use std::fmt;

/// Errors returned by the fingerprint API.
#[derive(Debug, Clone)]
pub enum FingerprintError {
    /// The file could not be opened or read.
    OpenFile { message: String },
    /// The audio could not be decoded (unsupported or corrupt).
    Decode { message: String },
    /// The container or codec has no decoder in this build.
    Unsupported { message: String },
    /// Fingerprint calculation or comparison failed.
    Fingerprint { message: String },
    /// The operation was cancelled via [`cancellation_token_cancel`](super::fingerprint::cancellation_token_cancel).
    Cancelled,
}

impl fmt::Display for FingerprintError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Self::OpenFile { message } => write!(f, "Could not open file: {message}"),
            Self::Decode { message } => write!(f, "Could not decode audio: {message}"),
            Self::Unsupported { message } => write!(f, "Unsupported audio format: {message}"),
            Self::Fingerprint { message } => write!(f, "Fingerprint error: {message}"),
            Self::Cancelled => write!(f, "Fingerprint cancelled"),
        }
    }
}

impl std::error::Error for FingerprintError {}
