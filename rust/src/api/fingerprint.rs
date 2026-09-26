use std::io::Cursor;

use flutter_rust_bridge::frb;
use rusty_chromaprint::{Configuration, Fingerprinter, match_fingerprints};
use symphonia::core::codecs::audio::AudioDecoderOptions;
use symphonia::core::errors::Error as SymphoniaError;
use symphonia::core::formats::FormatOptions;
use symphonia::core::formats::TrackType;
use symphonia::core::formats::probe::Hint;
use symphonia::core::io::MediaSourceStream;
use symphonia::core::meta::MetadataOptions;

use super::error::FingerprintError;

/// A perceptual audio fingerprint.
///
/// Two recordings of the same audio produce equal (or near-equal)
/// fingerprints even if filenames, tags, containers, or encoders differ.
/// Compare with [`similarity`].
#[derive(Debug, Clone)]
pub struct AudioFingerprint {
    /// Raw Chromaprint items (one `u32` per ~0.12s of audio).
    pub values: Vec<u32>,
    /// Decoded audio duration in whole seconds.
    pub duration_secs: u32,
}

/// Compute the fingerprint of the audio file at `path`.
///
/// Decodes the full audio stream (MP3, FLAC, Ogg Vorbis, WAV, AIFF,
/// M4A/AAC/ALAC) and fingerprints the PCM content. Tags, filenames, and
/// container differences do not affect the result.
///
/// `sync` (not pooled): FRB would otherwise run this on its web worker pool,
/// whose bootstrap hardcodes the `wasm_bindgen` JS global — unusable when
/// two FRB plugins share a page. Sync execution needs no pool, no workers.
// ponytail: sync keeps web worker-free; revisit if compute ever needs threads.
#[frb(sync)]
pub fn fingerprint(path: String) -> Result<AudioFingerprint, FingerprintError> {
    let bytes = std::fs::read(&path).map_err(|e| FingerprintError::OpenFile {
        message: format!("Could not read file: {e}"),
    })?;
    fingerprint_from_bytes(bytes)
}

/// Compute the fingerprint of in-memory audio `bytes` (for web/WASM).
// ponytail: sync, same worker-pool reason as `fingerprint`.
#[frb(sync)]
pub fn fingerprint_from_bytes(bytes: Vec<u8>) -> Result<AudioFingerprint, FingerprintError> {
    let (samples, sample_rate, channels) = decode_to_pcm(&bytes)?;
    let (values, duration_secs) = fingerprint_pcm(&samples, sample_rate, channels)?;
    Ok(AudioFingerprint {
        values,
        duration_secs,
    })
}

/// Compare two fingerprints, returning a similarity score from `0.0` to `1.0`.
///
/// `1.0` means (near-)identical audio. Copies and renames score `1.0`;
/// different encodings of the same recording typically score above `0.8`;
/// unrelated audio scores near `0.0`.
// ponytail: sync, same worker-pool reason as `fingerprint`.
#[frb(sync)]
pub fn similarity(a: AudioFingerprint, b: AudioFingerprint) -> Result<f64, FingerprintError> {
    if a.values.is_empty() || b.values.is_empty() {
        return Err(FingerprintError::Fingerprint {
            message: "Cannot compare empty fingerprints".to_string(),
        });
    }
    let config = Configuration::default();
    let segments = match_fingerprints(&a.values, &b.values, &config).map_err(|e| {
        FingerprintError::Fingerprint {
            message: format!("Comparison failed: {e:?}"),
        }
    })?;
    let denom = a.values.len().max(b.values.len()).max(1) as f64;
    let best = segments
        .iter()
        .map(|s| s.items_count as f64 * (1.0 - (s.score / 32.0).clamp(0.0, 1.0)))
        .fold(0.0, f64::max);
    Ok((best / denom).clamp(0.0, 1.0))
}

/// Decode any supported container to interleaved `i16` PCM.
/// Returns `(samples, sample_rate, channels)`.
fn decode_to_pcm(bytes: &[u8]) -> Result<(Vec<i16>, u32, u32), FingerprintError> {
    let cursor = Cursor::new(bytes);
    let mss = MediaSourceStream::new(Box::new(cursor), Default::default());
    // ponytail: no extension hint — symphonia sniffs the container from content,
    // so renames/copies fingerprint identically without relying on filenames.
    let mut format = symphonia::default::get_probe()
        .probe(
            &Hint::new(),
            mss,
            FormatOptions::default(),
            MetadataOptions::default(),
        )
        .map_err(|_| FingerprintError::Decode {
            message: "Unrecognized audio container".to_string(),
        })?;

    let track = format
        .default_track(TrackType::Audio)
        .ok_or_else(|| FingerprintError::Decode {
            message: "No decodable audio track found".to_string(),
        })?;
    let track_id = track.id;
    let audio_params = track
        .codec_params
        .as_ref()
        .ok_or_else(|| FingerprintError::Decode {
            message: "Missing codec parameters".to_string(),
        })?
        .audio()
        .ok_or_else(|| FingerprintError::Decode {
            message: "Track is not an audio codec".to_string(),
        })?;
    let mut decoder = symphonia::default::get_codecs()
        .make_audio_decoder(audio_params, &AudioDecoderOptions::default())
        .map_err(|_| FingerprintError::Unsupported {
            message: "No decoder for this codec".to_string(),
        })?;

    let mut samples: Vec<i16> = Vec::new();
    let mut interleaved: Vec<i16> = Vec::new();
    let (mut sample_rate, mut channels) = (0u32, 0u32);
    loop {
        let packet = match format.next_packet() {
            Ok(Some(packet)) => packet,
            // End of stream.
            Ok(None) => break,
            // Track list changed (chained OGG); keep going with current decoder.
            Err(SymphoniaError::ResetRequired) => continue,
            Err(e) => {
                return Err(FingerprintError::Decode {
                    message: format!("Packet read failed: {e}"),
                });
            }
        };
        if packet.track_id != track_id {
            continue;
        }
        match decoder.decode(&packet) {
            Ok(decoded) => {
                sample_rate = decoded.spec().rate();
                channels = decoded.spec().channels().count() as u32;
                interleaved.resize(decoded.samples_interleaved(), 0);
                decoded.copy_to_slice_interleaved::<i16, _>(&mut interleaved);
                samples.extend_from_slice(&interleaved);
            }
            // Skip corrupt frames; the packet cursor already advanced.
            Err(SymphoniaError::DecodeError(_)) | Err(SymphoniaError::IoError(_)) => continue,
            Err(e) => {
                return Err(FingerprintError::Decode {
                    message: format!("Frame decode failed: {e}"),
                });
            }
        }
    }

    if samples.is_empty() || sample_rate == 0 || channels == 0 {
        return Err(FingerprintError::Decode {
            message: "No audio samples decoded".to_string(),
        });
    }
    Ok((samples, sample_rate, channels))
}

/// Fingerprint interleaved `i16` PCM. Returns `(items, duration_secs)`.
fn fingerprint_pcm(
    samples: &[i16],
    sample_rate: u32,
    channels: u32,
) -> Result<(Vec<u32>, u32), FingerprintError> {
    // ponytail: Configuration::default() is preset_test2 — the same algorithm
    // fpcalc/AcoustID use, so fingerprints stay comparable with that ecosystem.
    let config = Configuration::default();
    let mut printer = Fingerprinter::new(&config);
    printer
        .start(sample_rate, channels)
        .map_err(|e| FingerprintError::Fingerprint {
            message: format!("Fingerprinter init failed: {e:?}"),
        })?;
    printer.consume(samples);
    printer.finish();
    let values = printer.fingerprint().to_vec();
    if values.is_empty() {
        return Err(FingerprintError::Fingerprint {
            message: "Audio too short to fingerprint".to_string(),
        });
    }
    let duration_secs = (samples.len() as u32)
        .checked_div(sample_rate.saturating_mul(channels).max(1))
        .unwrap_or(0);
    Ok((values, duration_secs))
}

#[cfg(test)]
mod tests {
    use super::*;

    /// Synthesize a 16-bit PCM WAV (linear frequency sweep) with std only.
    /// Sweeps give time-varying spectra, unlike pure tones (which are
    /// stationary — and octave-invariant under chroma features, so 440Hz
    /// and 880Hz sines fingerprint identically, as they should).
    fn wav_bytes(f0_hz: f32, f1_hz: f32, secs: u32, sample_rate: u32) -> Vec<u8> {
        let n = (secs * sample_rate) as usize;
        let mut data = Vec::with_capacity(44 + n * 2);
        let byte_rate = sample_rate * 2;
        data.extend_from_slice(b"RIFF");
        data.extend_from_slice(&((36 + n * 2) as u32).to_le_bytes());
        data.extend_from_slice(b"WAVEfmt ");
        data.extend_from_slice(&16u32.to_le_bytes());
        data.extend_from_slice(&1u16.to_le_bytes());
        data.extend_from_slice(&1u16.to_le_bytes());
        data.extend_from_slice(&sample_rate.to_le_bytes());
        data.extend_from_slice(&byte_rate.to_le_bytes());
        data.extend_from_slice(&2u16.to_le_bytes());
        data.extend_from_slice(&16u16.to_le_bytes());
        data.extend_from_slice(b"data");
        data.extend_from_slice(&((n * 2) as u32).to_le_bytes());
        for i in 0..n {
            let t = i as f32 / sample_rate as f32;
            let phase = 2.0
                * std::f32::consts::PI
                * (f0_hz * t + (f1_hz - f0_hz) * t * t / (2.0 * secs as f32));
            let s = (f32::sin(phase) * 20000.0) as i16;
            data.extend_from_slice(&s.to_le_bytes());
        }
        data
    }

    #[test]
    fn fingerprint_is_deterministic() {
        let a = fingerprint_from_bytes(wav_bytes(440.0, 880.0, 5, 44100)).unwrap();
        let b = fingerprint_from_bytes(wav_bytes(440.0, 880.0, 5, 44100)).unwrap();
        assert_eq!(a.values, b.values);
        assert_eq!(a.duration_secs, 5);
    }

    #[test]
    fn different_audio_gives_different_fingerprint() {
        let a = fingerprint_from_bytes(wav_bytes(440.0, 880.0, 5, 44100)).unwrap();
        let b = fingerprint_from_bytes(wav_bytes(440.0, 660.0, 5, 44100)).unwrap();
        assert_ne!(a.values, b.values);
    }

    #[test]
    fn identical_audio_scores_one() {
        let a = fingerprint_from_bytes(wav_bytes(440.0, 880.0, 5, 44100)).unwrap();
        let b = fingerprint_from_bytes(wav_bytes(440.0, 880.0, 5, 44100)).unwrap();
        assert_eq!(similarity(a, b).unwrap(), 1.0);
    }

    #[test]
    fn unrelated_audio_scores_low() {
        let a = fingerprint_from_bytes(wav_bytes(440.0, 880.0, 5, 44100)).unwrap();
        let b = fingerprint_from_bytes(wav_bytes(200.0, 300.0, 5, 44100)).unwrap();
        assert!(similarity(a, b).unwrap() < 0.5);
    }

    #[test]
    fn garbage_bytes_are_rejected() {
        assert!(fingerprint_from_bytes(b"not audio at all".to_vec()).is_err());
    }
}
