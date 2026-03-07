"""
Vision module for analyzing screen recording frames.

This module provides functionality to:
- Extract key frames from video recordings
- Detect slide changes
- Analyze visual content using vision models
"""

import subprocess
import json
from pathlib import Path
from dataclasses import dataclass
from typing import List, Optional, Protocol
from abc import ABC, abstractmethod


@dataclass
class Frame:
    """Represents a single video frame."""
    index: int
    timestamp: float
    image_path: Path
    description: Optional[str] = None


@dataclass
class Slide:
    """Represents a detected slide or key frame."""
    index: int
    timestamp: float
    image_data: bytes
    description: str
    confidence: float


class VisionProvider(Protocol):
    """Protocol for vision analysis providers."""
    
    def analyze_frame(self, image_data: bytes) -> str:
        """Analyze a single frame and return description."""
        ...
    
    def analyze_frames(self, frames: List[bytes]) -> List[str]:
        """Analyze multiple frames."""
        ...


class FrameExtractor:
    """
    Extracts frames from video recordings.
    
    Responsibilities:
    - Sample frames at regular intervals
    - Detect significant frame changes (slides)
    - Save frames as images
    """
    
    def __init__(self, video_path: Path, output_dir: Optional[Path] = None):
        self.video_path = video_path
        self.output_dir = output_dir or video_path.parent / "frames"
        self.output_dir.mkdir(parents=True, exist_ok=True)
    
    def extract_frames(self, interval_seconds: float = 5.0) -> List[Frame]:
        """
        Extract frames at regular intervals.
        
        Args:
            interval_seconds: Time between frames in seconds.
            
        Returns:
            List of extracted Frame objects.
        """
        frames = []
        
        # Get video duration
        duration = self._get_duration()
        if duration <= 0:
            return frames
        
        # Extract frames at interval
        current_time = 0.0
        frame_index = 0
        
        while current_time < duration:
            frame_path = self.output_dir / f"frame_{frame_index:04d}.jpg"
            
            if self._extract_frame(current_time, frame_path):
                frames.append(Frame(
                    index=frame_index,
                    timestamp=current_time,
                    image_path=frame_path
                ))
            
            current_time += interval_seconds
            frame_index += 1
        
        return frames
    
    def detect_slides(self, threshold: float = 0.3) -> List[Slide]:
        """
        Detect significant frame changes (slide transitions).
        
        Args:
            threshold: Similarity threshold (0-1). Lower = more sensitive.
            
        Returns:
            List of detected Slide objects.
        """
        import cv2
        
        slides = []
        frames = self.extract_frames(interval_seconds=2.0)
        
        if not frames:
            return slides
        
        prev_gray = None
        
        for frame in frames:
            img = cv2.imread(str(frame.image_path))
            if img is None:
                continue
                
            gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
            
            if prev_gray is not None:
                # Calculate similarity
                score = self._compare_frames(prev_gray, gray)
                
                if score < threshold:
                    # Significant change detected - this is a new slide
                    with open(frame.image_path, 'rb') as f:
                        image_data = f.read()
                    
                    slides.append(Slide(
                        index=len(slides),
                        timestamp=frame.timestamp,
                        image_data=image_data,
                        description=f"Slide at {self._format_timestamp(frame.timestamp)}",
                        confidence=1.0 - score
                    ))
            
            prev_gray = gray
        
        return slides
    
    def _get_duration(self) -> float:
        """Get video duration in seconds using ffprobe."""
        try:
            result = subprocess.run(
                [
                    "ffprobe",
                    "-v", "error",
                    "-show_entries", "format=duration",
                    "-of", "json",
                    str(self.video_path)
                ],
                capture_output=True,
                text=True,
                timeout=30
            )
            
            data = json.loads(result.stdout)
            return float(data.get("format", {}).get("duration", 0))
        except (subprocess.TimeoutExpired, json.JSONDecodeError, KeyError):
            return 0.0
    
    def _extract_frame(self, timestamp: float, output_path: Path) -> bool:
        """Extract a single frame at the given timestamp."""
        try:
            subprocess.run(
                [
                    "ffmpeg",
                    "-ss", str(timestamp),
                    "-i", str(self.video_path),
                    "-vframes", "1",
                    "-q:v", "2",
                    "-y",
                    str(output_path)
                ],
                capture_output=True,
                timeout=30
            )
            return output_path.exists()
        except subprocess.TimeoutExpired:
            return False
    
    def _compare_frames(self, gray1, gray2) -> float:
        """Compare two grayscale frames and return similarity score."""
        import cv2
        diff = cv2.absdiff(gray1, gray2)
        non_zero = cv2.countNonZero(diff)
        total_pixels = diff.shape[0] * diff.shape[1]
        return 1.0 - (non_zero / total_pixels)
    
    def _format_timestamp(self, seconds: float) -> str:
        """Format seconds as MM:SS."""
        mins = int(seconds) // 60
        secs = int(seconds) % 60
        return f"{mins:02d}:{secs:02d}"
