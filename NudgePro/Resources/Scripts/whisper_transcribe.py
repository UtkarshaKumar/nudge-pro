#!/usr/bin/env python3
"""Whisper transcription script for Nudge Pro."""

import sys
import json
import argparse
from pathlib import Path

try:
    from faster_whisper import WhisperModel
except ImportError:
    print("ERROR: faster-whisper not installed. Run: pip install faster-whisper")
    sys.exit(1)


def transcribe_audio(audio_path: str, model_size: str = "small.en") -> str:
    """
    Transcribe audio file using Whisper.

    Args:
        audio_path: Path to audio file
        model_size: Whisper model size (tiny, base, small, medium, large)

    Returns:
        Transcribed text
    """
    try:
        print(f"Loading Whisper model: {model_size}")
        model = WhisperModel(
            model_size, device="cpu", compute_type="int8", download_root=None
        )

        print(f"Transcribing: {audio_path}")

        # Check if file exists
        if not Path(audio_path).exists():
            raise FileNotFoundError(f"Audio file not found: {audio_path}")

        segments, info = model.transcribe(audio_path, beam_size=5)

        print(
            f"Detected language: {info.language} (probability: {info.language_probability:.2f})"
        )

        transcript = []
        for segment in segments:
            transcript.append(segment.text.strip())

        result = " ".join(transcript)
        print(f"Transcription complete: {len(result)} characters")
        return result

    except Exception as e:
        print(f"ERROR: Transcription failed: {e}")
        sys.exit(1)


def main():
    parser = argparse.ArgumentParser(description="Transcribe audio using Whisper")
    parser.add_argument("audio_path", help="Path to audio file")
    parser.add_argument("--model", default="small.en", help="Whisper model size")
    parser.add_argument("--output", "-o", help="Output JSON file path")

    args = parser.parse_args()

    audio_path = Path(args.audio_path)
    if not audio_path.exists():
        print(f"ERROR: Audio file not found: {audio_path}")
        sys.exit(1)

    transcript = transcribe_audio(str(audio_path), args.model)

    if args.output:
        output_data = {
            "audio_path": str(audio_path),
            "transcript": transcript,
            "model": args.model,
        }
        with open(args.output, "w") as f:
            json.dump(output_data, f, indent=2)
        print(f"Output saved to: {args.output}")
    else:
        print(transcript)


if __name__ == "__main__":
    main()
