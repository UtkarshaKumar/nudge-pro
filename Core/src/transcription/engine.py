"""Transcription engine using Whisper."""

from pathlib import Path


class TranscriptionEngine:
    """
    Handles speech-to-text transcription.
    
    Responsibilities:
    - Load Whisper model
    - Transcribe audio files
    - Return formatted transcripts
    """
    
    def __init__(self, model: str = "small.en"):
        self.model = model
        self._model = None
    
    def transcribe(self, audio_path: Path) -> str:
        """
        Transcribe audio file.
        
        Args:
            audio_path: Path to audio file.
            
        Returns:
            Transcribed text.
        """
        # In production: Use faster-whisper
        # model = WhisperModel(self.model)
        # result = model.transcribe(str(audio_path))
        # return result["text"]
        
        return "Transcription placeholder"
