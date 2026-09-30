use std::collections::HashMap;
use std::io::Cursor;
use std::sync::{
    Arc, Mutex,
    atomic::{AtomicBool, AtomicU64, Ordering},
};

use flutter_rust_bridge::frb;
use rusty_chromaprint::{Configuration, Fingerprinter, match_fingerprints};
use symphonia::core::codecs::audio::AudioDecoderOptions;
use symphonia::core::errors::Error as SymphoniaError;
use symphonia::core::formats::probe::Hint;
use symphonia::core::formats::{FormatOptions, FormatReader, TrackType};
use symphonia::core::io::MediaSourceStream;
use symphonia::core::meta::MetadataOptions;

use super::error::FingerprintError;

/// Wire-protocol version. Bump ONLY when an FRB function signature changes
/// (new/removed/renamed params, changed types). The Dart side verifies this
/// on init: without the check, a stale native library decodes garbage
/// lengths (e.g. negative `i32` -> huge `usize`) and dies in `capacity
/// overflow` instead of reporting anything useful.
const FINGERPRINT_API_VERSION: u32 = 1;

/// Returns [`FINGERPRINT_API_VERSION`]. Called by Dart on init to detect a
/// stale native library before any real payload crosses FFI.
#[frb(sync)]
pub fn fingerprint_api_version() -> u32 {
    FINGERPRINT_API_VERSION
}

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
/// Async without touching FRB's worker pool (whose web bootstrap hardcodes
/// the `wasm_bindgen` JS global): native runs on tokio background threads,
/// web cooperatively yields between decode chunks on the main thread.
/// Pass `cancel_id` from [`cancellation_token_new`] to abort long scans.
pub async fn fingerprint(
    path: String,
    cancel_id: Option<u64>,
) -> Result<AudioFingerprint, FingerprintError> {
    let bytes = std::fs::read(&path).map_err(|e| FingerprintError::OpenFile {
        message: format!("Could not read file: {e}"),
    })?;
    fingerprint_inner(bytes, cancel_id).await
}

/// Compute the fingerprint of in-memory audio `bytes` (for web/WASM).
///
/// Async, same execution model as [`fingerprint`]. Pass `cancel_id` from
/// [`cancellation_token_new`] to abort long scans.
pub async fn fingerprint_from_bytes(
    bytes: Vec<u8>,
    cancel_id: Option<u64>,
) -> Result<AudioFingerprint, FingerprintError> {
    fingerprint_inner(bytes, cancel_id).await
}

async fn fingerprint_inner(
    bytes: Vec<u8>,
    cancel_id: Option<u64>,
) -> Result<AudioFingerprint, FingerprintError> {
    let flag = cancel_flag(cancel_id);
    if is_cancelled(&flag) {
        return Err(FingerprintError::Cancelled);
    }
    // Native: blocking pool thread, streaming decode with O(chunk) memory.
    // A dependency panic becomes a clean error via the join, never a crash.
    #[cfg(not(target_arch = "wasm32"))]
    {
        let out = tokio::task::spawn_blocking(move || fingerprint_sync_streaming(&bytes, &flag))
            .await
            .map_err(|_| FingerprintError::Fingerprint {
                message: "Fingerprint task failed".to_string(),
            })?;
        return out.map(|(values, duration_secs)| AudioFingerprint {
            values,
            duration_secs,
        });
    }
    // WASM: cooperative main-thread path (no worker pool exists here).
    #[cfg(target_arch = "wasm32")]
    {
        let (samples, sample_rate, channels) = decode_to_pcm(&bytes, &flag).await?;
        if is_cancelled(&flag) {
            return Err(FingerprintError::Cancelled);
        }
        // ponytail: sync stretch — the printer is !Send, so it must never be
        // alive across an await. Decode yields happen above, none in here.
        let (values, duration_secs) = fingerprint_pcm(&samples, sample_rate, channels)?;
        Ok(AudioFingerprint {
            values,
            duration_secs,
        })
    }
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

// ── Cancellation ──────────────────────────────────────────────────────────
//
// Cooperative, handle-based: ids are cheap `u64`s (no opaque-type plumbing
// through FRB), flags live in one process-global map. `cancel`/`free` on
// unknown ids are harmless no-ops, so double-cancel and use-after-free
// cannot fail. Ids are reusable resources owned by the caller: create one
// token per scan, `free` it when done; a tripped flag stays tripped.

static NEXT_CANCEL_ID: AtomicU64 = AtomicU64::new(1);
static CANCEL_FLAGS: std::sync::LazyLock<Mutex<HashMap<u64, Arc<AtomicBool>>>> =
    std::sync::LazyLock::new(|| Mutex::new(HashMap::new()));

fn cancel_flag(id: Option<u64>) -> Option<Arc<AtomicBool>> {
    id.and_then(|id| CANCEL_FLAGS.lock().unwrap().get(&id).cloned())
}

fn is_cancelled(flag: &Option<Arc<AtomicBool>>) -> bool {
    flag.as_ref().is_some_and(|f| f.load(Ordering::Relaxed))
}

/// Create a cancellation token, returned as an id for Dart's
/// `CancellationToken`. Pass it as `cancel_id` to abort long scans.
#[frb(sync)]
pub fn cancellation_token_new() -> u64 {
    let id = NEXT_CANCEL_ID.fetch_add(1, Ordering::Relaxed);
    CANCEL_FLAGS
        .lock()
        .unwrap()
        .insert(id, Arc::new(AtomicBool::new(false)));
    id
}

/// Trip a token created by [`cancellation_token_new`]. In-flight fingerprint
/// calls observing it abort with [`FingerprintError::Cancelled`]. Idempotent.
#[frb(sync)]
pub fn cancellation_token_cancel(id: u64) {
    if let Some(flag) = CANCEL_FLAGS.lock().unwrap().get(&id) {
        flag.store(true, Ordering::Relaxed);
    }
}

/// Release a token id. Ids are reusable resources owned by the caller:
// ponytail: no auto-drop on purpose — dropping would silently break token
// reuse across scans. Documented dispose pattern instead. Idempotent.
#[frb(sync)]
pub fn cancellation_token_free(id: u64) {
    CANCEL_FLAGS.lock().unwrap().remove(&id);
}

/// Shared probe/track setup for both decode paths. Returns the format
/// reader, the selected audio track id, and OWNED codec params (cloned so
/// no lifetimes escape — callers build their own decoder).
fn open_decoder(
    bytes: &[u8],
) -> Result<
    (
        Box<dyn FormatReader + '_>,
        u32,
        symphonia::core::codecs::audio::AudioCodecParameters,
    ),
    FingerprintError,
> {
    let cursor = Cursor::new(bytes);
    let mss = MediaSourceStream::new(Box::new(cursor), Default::default());
    // ponytail: no extension hint — symphonia sniffs the container from content,
    // so renames/copies fingerprint identically without relying on filenames.
    let format = symphonia::default::get_probe()
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
        })?
        .clone();
    Ok((format, track_id, audio_params))
}

/// Whole seconds of audio; saturates instead of wrapping on absurd inputs.
fn duration_secs(total_frames: u64, sample_rate: u32, channels: u32) -> u32 {
    let per_sec = sample_rate as u64 * channels.max(1) as u64;
    if per_sec == 0 {
        return 0;
    }
    u32::try_from(total_frames / per_sec).unwrap_or(u32::MAX)
}

/// Native blocking path: stream decode→feed with O(chunk) memory no matter
/// the file size, so hour-long files can't OOM the scanner. Fully synchronous
/// (runs on tokio's blocking pool) — no awaits, so the !Send printer can
/// live across the whole loop.
#[cfg(not(target_arch = "wasm32"))]
fn fingerprint_sync_streaming(
    bytes: &[u8],
    flag: &Option<Arc<AtomicBool>>,
) -> Result<(Vec<u32>, u32), FingerprintError> {
    const FEED_EVERY_SAMPLES: usize = 88200; // ~1s of stereo 44.1kHz
    let (mut format, track_id, audio_params) = open_decoder(bytes)?;
    let mut decoder = symphonia::default::get_codecs()
        .make_audio_decoder(&audio_params, &AudioDecoderOptions::default())
        .map_err(|_| FingerprintError::Unsupported {
            message: "No decoder for this codec".to_string(),
        })?;
    let config = Configuration::default();
    let mut printer: Option<Fingerprinter> = None;
    let mut chunk: Vec<i16> = Vec::new();
    let mut interleaved: Vec<i16> = Vec::new();
    let (mut sample_rate, mut channels) = (0u32, 0u32);
    let mut total_frames: u64 = 0;
    loop {
        if is_cancelled(flag) {
            return Err(FingerprintError::Cancelled);
        }
        let packet = match format.next_packet() {
            Ok(Some(packet)) => packet,
            Ok(None) => break,
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
                if printer.is_none() {
                    sample_rate = decoded.spec().rate();
                    channels = decoded.spec().channels().count() as u32;
                    if sample_rate == 0 || channels == 0 {
                        return Err(FingerprintError::Decode {
                            message: "Invalid audio spec".to_string(),
                        });
                    }
                    let mut p = Fingerprinter::new(&config);
                    p.start(sample_rate, channels)
                        .map_err(|e| FingerprintError::Fingerprint {
                            message: format!("Fingerprinter init failed: {e:?}"),
                        })?;
                    printer = Some(p);
                }
                interleaved.resize(decoded.samples_interleaved(), 0);
                decoded.copy_to_slice_interleaved::<i16, _>(&mut interleaved);
                total_frames += (interleaved.len() / channels.max(1) as usize) as u64;
                chunk.extend_from_slice(&interleaved);
                if chunk.len() >= FEED_EVERY_SAMPLES {
                    printer.as_mut().unwrap().consume(&chunk);
                    chunk.clear();
                }
            }
            Err(SymphoniaError::DecodeError(_)) | Err(SymphoniaError::IoError(_)) => continue,
            Err(e) => {
                return Err(FingerprintError::Decode {
                    message: format!("Frame decode failed: {e}"),
                });
            }
        }
    }
    let mut printer = printer.ok_or(FingerprintError::Decode {
        message: "No audio samples decoded".to_string(),
    })?;
    if !chunk.is_empty() {
        printer.consume(&chunk);
    }
    printer.finish();
    let values = printer.fingerprint().to_vec();
    if values.is_empty() {
        return Err(FingerprintError::Fingerprint {
            message: "Audio too short to fingerprint".to_string(),
        });
    }
    Ok((values, duration_secs(total_frames, sample_rate, channels)))
}

/// Decode any supported container to interleaved `i16` PCM.
/// Returns `(samples, sample_rate, channels)`.
///
/// WASM/test-only cooperative path: collects everything (like the old
/// design) with yields between chunks. Native production uses
/// [`fingerprint_sync_streaming`] instead for bounded memory.
#[cfg(any(test, target_arch = "wasm32"))]
///
/// Yields roughly every second of audio so event loops (notably the web main
/// thread, where this runs cooperatively) stay responsive during long files.
async fn decode_to_pcm(
    bytes: &[u8],
    flag: &Option<Arc<AtomicBool>>,
) -> Result<(Vec<i16>, u32, u32), FingerprintError> {
    let (mut format, track_id, audio_params) = open_decoder(bytes)?;
    let mut decoder = symphonia::default::get_codecs()
        .make_audio_decoder(&audio_params, &AudioDecoderOptions::default())
        .map_err(|_| FingerprintError::Unsupported {
            message: "No decoder for this codec".to_string(),
        })?;

    let mut samples: Vec<i16> = Vec::new();
    let mut interleaved: Vec<i16> = Vec::new();
    let (mut sample_rate, mut channels) = (0u32, 0u32);
    // ponytail: one Relaxed load per packet is ~free; the yield keeps long
    // decodes from monopolizing cooperative executors (web main thread).
    const YIELD_EVERY_SAMPLES: usize = 88200; // ~1s of stereo 44.1kHz
    let mut since_yield = 0usize;
    loop {
        if is_cancelled(flag) {
            return Err(FingerprintError::Cancelled);
        }
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
                since_yield += interleaved.len();
                if since_yield >= YIELD_EVERY_SAMPLES {
                    since_yield = 0;
                    tokio::task::yield_now().await;
                    if is_cancelled(flag) {
                        return Err(FingerprintError::Cancelled);
                    }
                }
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

/// Fingerprint interleaved `i16` PCM in one shot. Returns `(items, duration)`.
///
/// Test/wasm-only oracle: native production streams through
/// [`fingerprint_sync_streaming`] instead. The chunked-vs-oneshot test below
/// proves both produce identical output.
#[cfg(any(test, target_arch = "wasm32"))]
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
    let duration_secs = duration_secs(samples.len() as u64, sample_rate, channels);
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

    #[tokio::test(flavor = "multi_thread")]
    async fn fingerprint_is_deterministic() {
        let a = fingerprint_from_bytes(wav_bytes(440.0, 880.0, 5, 44100), None)
            .await
            .unwrap();
        let b = fingerprint_from_bytes(wav_bytes(440.0, 880.0, 5, 44100), None)
            .await
            .unwrap();
        assert_eq!(a.values, b.values);
        assert_eq!(a.duration_secs, 5);
    }

    #[tokio::test(flavor = "multi_thread")]
    async fn different_audio_gives_different_fingerprint() {
        let a = fingerprint_from_bytes(wav_bytes(440.0, 880.0, 5, 44100), None)
            .await
            .unwrap();
        let b = fingerprint_from_bytes(wav_bytes(440.0, 660.0, 5, 44100), None)
            .await
            .unwrap();
        assert_ne!(a.values, b.values);
    }

    #[tokio::test(flavor = "multi_thread")]
    async fn identical_audio_scores_one() {
        let a = fingerprint_from_bytes(wav_bytes(440.0, 880.0, 5, 44100), None)
            .await
            .unwrap();
        let b = fingerprint_from_bytes(wav_bytes(440.0, 880.0, 5, 44100), None)
            .await
            .unwrap();
        assert_eq!(similarity(a, b).unwrap(), 1.0);
    }

    // Chunked streaming (native production path) must produce bit-identical
    // output to one-shot consume, or cross-platform fingerprints diverge.
    #[tokio::test(flavor = "multi_thread")]
    async fn chunked_matches_oneshot() {
        let mut inputs = vec![
            wav_bytes(440.0, 880.0, 5, 44100),
            wav_bytes(200.0, 300.0, 7, 48000),
            wav_bytes(880.0, 440.0, 3, 22050),
        ];
        for name in [
            "chirp.mp3",
            "chirp.flac",
            "chirp.ogg",
            "chirp.m4a",
            "chirp.wav",
        ] {
            if let Ok(b) = std::fs::read(format!("../test/fixtures/{name}")) {
                inputs.push(b);
            }
        }
        assert!(inputs.len() >= 3);
        for bytes in &inputs {
            let (samples, rate, ch) = decode_to_pcm(bytes, &None).await.unwrap();
            let (one_vals, one_dur) = fingerprint_pcm(&samples, rate, ch).unwrap();
            let (stream_vals, stream_dur) = fingerprint_sync_streaming(bytes, &None).unwrap();
            assert_eq!(one_vals, stream_vals);
            assert_eq!(one_dur, stream_dur);
        }
    }

    #[tokio::test(flavor = "multi_thread")]
    async fn unrelated_audio_scores_low() {
        let a = fingerprint_from_bytes(wav_bytes(440.0, 880.0, 5, 44100), None)
            .await
            .unwrap();
        let b = fingerprint_from_bytes(wav_bytes(200.0, 300.0, 5, 44100), None)
            .await
            .unwrap();
        assert!(similarity(a, b).unwrap() < 0.5);
    }

    #[tokio::test(flavor = "multi_thread")]
    async fn garbage_bytes_are_rejected() {
        assert!(
            fingerprint_from_bytes(b"not audio at all".to_vec(), None)
                .await
                .is_err()
        );
    }

    // Every input below must return Err, never panic. If any of these
    // panics, that is the crash bug — fix the code, not the test.
    #[tokio::test(flavor = "multi_thread")]
    async fn malformed_inputs_never_panic() {
        let mut bad: Vec<Vec<u8>> = vec![
            vec![],
            vec![0],
            b"ID3".to_vec(),
            b"ID3\x04\x00\x00\x00\x00\x00\x00".to_vec(),
            b"fLaC".to_vec(),
            b"fLaC\x10\x00\x00".to_vec(),
            b"OggS".to_vec(),
            b"OggS\x00\x00\x00\x00".to_vec(),
            b"ftyp".to_vec(),
            b"RIFF".to_vec(),
            b"RIFF\x00\x00\x00\x00WAVE".to_vec(),
            // WAV header lying about a giant data chunk, tiny body.
            {
                let mut v = b"RIFF".to_vec();
                v.extend_from_slice(&u32::MAX.to_le_bytes());
                v.extend_from_slice(b"WAVEfmt ");
                v.extend_from_slice(&16u32.to_le_bytes());
                v.extend_from_slice(&1u16.to_le_bytes());
                v.extend_from_slice(&1u16.to_le_bytes());
                v.extend_from_slice(&44100u32.to_le_bytes());
                v.extend_from_slice(&88200u32.to_le_bytes());
                v.extend_from_slice(&2u16.to_le_bytes());
                v.extend_from_slice(&16u16.to_le_bytes());
                v.extend_from_slice(b"data");
                v.extend_from_slice(&u32::MAX.to_le_bytes());
                v.extend_from_slice(&[0u8; 16]);
                v
            },
        ];
        // Deterministic pseudo-random garbage (LCG, no new deps).
        let mut state = 0x12345678u32;
        let mut rand = vec![0u8; 4096];
        for b in rand.iter_mut() {
            state = state.wrapping_mul(1664525).wrapping_add(1013904223);
            *b = (state >> 16) as u8;
        }
        bad.push(rand);
        for (i, input) in bad.into_iter().enumerate() {
            assert!(
                fingerprint_from_bytes(input, None).await.is_err(),
                "input {i} should err, not panic or succeed"
            );
        }
    }

    // Real-world corpus fuzz: set HAUDIO_FUZZ_DIR to a music folder and
    // every audio file in it must Ok or Err — never panic. Skipped otherwise
    // so CI stays hermetic.
    #[tokio::test(flavor = "multi_thread", worker_threads = 8)]
    async fn corpus_files_never_panic() {
        let dir = match std::env::var("HAUDIO_FUZZ_DIR") {
            Ok(d) => d,
            Err(_) => return,
        };
        fn collect(dir: &std::path::Path, out: &mut Vec<std::path::PathBuf>) {
            let entries = match std::fs::read_dir(dir) {
                Ok(e) => e,
                Err(_) => return,
            };
            for entry in entries.flatten() {
                let path = entry.path();
                if path.is_dir() {
                    collect(&path, out);
                } else if path.extension().and_then(|e| e.to_str()).is_some_and(|e| {
                    matches!(
                        e.to_lowercase().as_str(),
                        "mp3" | "flac" | "m4a" | "ogg" | "opus" | "wav" | "aac" | "aiff"
                    )
                }) {
                    out.push(path);
                }
            }
        }
        let mut files = Vec::new();
        collect(std::path::Path::new(&dir), &mut files);
        assert!(!files.is_empty(), "no audio files under {dir}");
        let mut ok = 0usize;
        let mut err = 0usize;
        for path in &files {
            let bytes = match std::fs::read(path) {
                Ok(b) => b,
                Err(_) => continue,
            };
            // Catch unwinds per file so one bad file can't hide behind
            // another, and report which file it was.
            let result = tokio::task::spawn_blocking(move || {
                let rt = tokio::runtime::Builder::new_current_thread()
                    .build()
                    .unwrap();
                rt.block_on(fingerprint_from_bytes(bytes, None))
            })
            .await
            .expect("scan task itself panicked");
            match result {
                Ok(_) => ok += 1,
                Err(_) => err += 1,
            }
        }
        println!("corpus: {} files, {ok} ok, {err} err", files.len());
    }

    // Mutation fuzz: flip bytes and smash u32/u64 fields in real files.
    // Any panic is the crash bug — the harness catches unwinds per input
    // and reports the exact mutation for minimization.
    // Slow (decodes real files); run explicitly, not in default CI.
    #[tokio::test(flavor = "multi_thread")]
    #[ignore]
    async fn fuzz_mutations_never_panic() {
        let mut seeds: Vec<Vec<u8>> = Vec::new();
        for name in [
            "chirp.mp3",
            "chirp.flac",
            "chirp.ogg",
            "chirp.m4a",
            "chirp.wav",
        ] {
            if let Ok(b) = std::fs::read(format!("../test/fixtures/{name}")) {
                seeds.push(b);
            }
        }
        for name in ["tone.mp3", "tiny.mp3", "tone.opus"] {
            if let Ok(b) = std::fs::read(format!("/tmp/opencode/fuzz/{name}")) {
                seeds.push(b);
            }
        }
        assert!(!seeds.is_empty());
        let mut state: u64 = 0x243F6A8885A308D3;
        let mut next = move |bound: usize| {
            state = state
                .wrapping_mul(6364136223846793005)
                .wrapping_add(1442695040888963407);
            (state >> 33) as usize % bound.max(1)
        };
        let mut failures = Vec::new();
        for iter in 0..3000 {
            let src = &seeds[iter % seeds.len()];
            if src.is_empty() {
                continue;
            }
            let mut input = src.clone();
            match iter % 4 {
                0 => {
                    // Random byte flips.
                    for _ in 0..1 + next(8) {
                        let at = next(input.len());
                        input[at] = next(256) as u8;
                    }
                }
                1 => {
                    // Smash a u32 field with max.
                    if input.len() >= 4 {
                        let at = next(input.len() - 3);
                        input[at..at + 4].copy_from_slice(&u32::MAX.to_le_bytes());
                    }
                }
                2 => {
                    // Smash a u64 field with max.
                    if input.len() >= 8 {
                        let at = next(input.len() - 7);
                        input[at..at + 8].copy_from_slice(&u64::MAX.to_le_bytes());
                    }
                }
                _ => {
                    // Truncate at a random point.
                    input.truncate(next(input.len()));
                }
            }
            // One OS thread per input: a panic is caught by join() and
            // recorded instead of killing the harness.
            let h = std::thread::spawn(move || {
                let rt = tokio::runtime::Builder::new_current_thread()
                    .build()
                    .unwrap();
                rt.block_on(fingerprint_from_bytes(input, None))
            });
            if h.join().is_err() {
                failures.push(iter);
                eprintln!("PANIC on iter {iter}");
                if failures.len() >= 3 {
                    break;
                }
            }
        }
        assert!(failures.is_empty(), "panics at iters {failures:?}");
    }

    // Similarity must handle huge and adversarial inputs without panic
    // (or absurd hangs): identical walls, pure noise, tiny-vs-huge.
    #[tokio::test(flavor = "multi_thread")]
    async fn similarity_stress_never_panics() {
        let wall = vec![0x9e3779b9u32; 50_000];
        let noise: Vec<u32> = (0..50_000u32)
            .map(|i| {
                let mut x = i.wrapping_mul(1664525).wrapping_add(1013904223);
                x ^= x >> 15;
                x = x.wrapping_mul(0x85ebca6b);
                x
            })
            .collect();
        let tiny = vec![1u32];
        let a = AudioFingerprint {
            values: wall.clone(),
            duration_secs: 3600,
        };
        let b = AudioFingerprint {
            values: wall,
            duration_secs: 3600,
        };
        assert_eq!(similarity(a, b).unwrap(), 1.0);
        let c = AudioFingerprint {
            values: noise,
            duration_secs: 3600,
        };
        let d = AudioFingerprint {
            values: c.values.clone(),
            duration_secs: 3600,
        };
        let s = similarity(c, d).unwrap();
        assert!((0.0..=1.0).contains(&s));
        let e = AudioFingerprint {
            values: tiny,
            duration_secs: 1,
        };
        let f = AudioFingerprint {
            values: vec![2u32; 50_000],
            duration_secs: 3600,
        };
        let s2 = similarity(e, f).unwrap();
        assert!((0.0..=1.0).contains(&s2));
    }

    // Real-world exotics (generated by ffmpeg): Opus must fail cleanly
    // (no decoder), everything else must Ok or Err — never panic.
    // Fixtures live outside the repo; missing files are skipped so this
    // stays green on machines without them.
    #[tokio::test(flavor = "multi_thread")]
    async fn exotic_files_never_panic() {
        for name in [
            "tone.mp3",
            "tone.opus",
            "tone51.wav",
            "tone192.wav",
            "tiny.mp3",
            "tonef32.wav",
        ] {
            let path = format!("/tmp/opencode/fuzz/{name}");
            let bytes = match std::fs::read(&path) {
                Ok(b) => b,
                Err(_) => continue,
            };
            let r = fingerprint_from_bytes(bytes, None).await;
            if name == "tone.opus" {
                assert!(r.is_err(), "opus has no decoder, must err");
            }
        }
    }

    // Parallel scans share the token registry and nothing else. Hammer it:
    // concurrent fingerprints, concurrent cancel/free churn. Must never panic.
    #[tokio::test(flavor = "multi_thread", worker_threads = 8)]
    async fn parallel_scans_never_panic() {
        let wavs = vec![
            wav_bytes(440.0, 880.0, 5, 44100),
            wav_bytes(220.0, 330.0, 5, 48000),
        ];
        let mut handles = Vec::new();
        for i in 0..16usize {
            let bytes = wavs[i % wavs.len()].clone();
            handles.push(tokio::spawn(async move {
                let id = cancellation_token_new();
                if i % 3 == 0 {
                    cancellation_token_cancel(id);
                }
                let r = fingerprint_from_bytes(bytes, Some(id)).await;
                cancellation_token_free(id);
                // Either outcome is fine; panicking is not.
                let _ = r;
                // Churn unknown ids concurrently too.
                cancellation_token_cancel(u64::MAX - i as u64);
            }));
        }
        for h in handles {
            h.await.unwrap();
        }
    }

    // Truncated real files: valid headers, cut streams. Must Err or Ok,
    // never panic, at every cut point.
    #[tokio::test(flavor = "multi_thread")]
    async fn truncated_real_files_never_panic() {
        for name in [
            "chirp.wav",
            "chirp.mp3",
            "chirp.flac",
            "chirp.ogg",
            "chirp.m4a",
        ] {
            let path = format!("../test/fixtures/{name}");
            let bytes = match std::fs::read(&path) {
                Ok(b) => b,
                Err(_) => continue,
            };
            assert!(!bytes.is_empty(), "missing fixture {name}");
            let mut cuts = vec![0, 1, 7, 44, 100, 1024];
            cuts.push(bytes.len() / 2);
            cuts.push(bytes.len().saturating_sub(1));
            for cut in cuts {
                let cut = cut.min(bytes.len());
                let _ = fingerprint_from_bytes(bytes[..cut].to_vec(), None).await;
            }
        }
    }

    // The handshake both sides of init compare. Bump together with the
    // Dart `_apiVersion`, and only when an FRB wire signature changes.
    #[test]
    fn api_version_is_current() {
        assert_eq!(fingerprint_api_version(), FINGERPRINT_API_VERSION);
        assert_eq!(FINGERPRINT_API_VERSION, 1);
    }

    #[test]
    fn token_ids_are_unique_and_hygienic() {
        let a = cancellation_token_new();
        let b = cancellation_token_new();
        assert_ne!(a, b);
        // Unknown ids are harmless no-ops, never panics.
        cancellation_token_cancel(u64::MAX);
        cancellation_token_free(u64::MAX);
        cancellation_token_free(a);
        cancellation_token_free(b);
    }

    #[tokio::test(flavor = "multi_thread")]
    async fn pre_cancelled_token_aborts() {
        let id = cancellation_token_new();
        cancellation_token_cancel(id);
        let err = fingerprint_from_bytes(wav_bytes(440.0, 880.0, 5, 44100), Some(id))
            .await
            .unwrap_err();
        assert!(matches!(err, FingerprintError::Cancelled));
        cancellation_token_free(id);
    }

    #[tokio::test(flavor = "multi_thread")]
    async fn cancel_during_long_decode_aborts() {
        // 240s of audio: decode takes well over a second, so a canceller
        // firing after 50ms virtually always lands mid-flight. Retry a few
        // times; if decode ever wins the race outright, that attempt just
        // doesn't prove anything.
        let bytes = wav_bytes(440.0, 880.0, 240, 44100);
        for _ in 0..5 {
            let id = cancellation_token_new();
            let bytes = bytes.clone();
            let canceller = tokio::spawn(async move {
                tokio::time::sleep(std::time::Duration::from_millis(50)).await;
                cancellation_token_cancel(id);
            });
            let result = fingerprint_from_bytes(bytes, Some(id)).await;
            let _ = canceller.await;
            cancellation_token_free(id);
            if matches!(result, Err(FingerprintError::Cancelled)) {
                return;
            }
        }
        panic!("cancellation never landed mid-decode");
    }
}
