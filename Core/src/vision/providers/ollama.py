"""
Vision analysis using Ollama with vision-capable models.

This provider uses Ollama's local models (like llava) to analyze
frames from screen recordings without requiring an external API.
"""

import base64
import json
import subprocess
from typing import List, Optional


class OllamaVisionProvider:
    """
    Vision analysis using Ollama's vision models.
    
    Responsibilities:
    - Communicate with local Ollama server
    - Analyze frames using vision models
    - Parse and return descriptions
    
    Supported models:
    - llava (recommended - uses latest version)
    - llava:7b
    - minicpm-v
    
    Example:
        >>> provider = OllamaVisionProvider(model="llava")
        >>> description = provider.analyze_frame(image_data)
    """
    
    def __init__(
        self,
        model: str = "llava",
        base_url: str = "http://localhost:11434",
        temperature: float = 0.7
    ):
        """
        Initialize the Ollama vision provider.
        
        Args:
            model: Ollama vision model to use.
            base_url: Base URL for Ollama server.
            temperature: Sampling temperature.
        """
        self.model = model
        self.base_url = base_url
        self.temperature = temperature
        self._check_model_available()
    
    def _check_model_available(self) -> None:
        """Check if the model is available in Ollama."""
        try:
            result = subprocess.run(
                ["ollama", "list"],
                capture_output=True,
                text=True,
                timeout=10
            )
            
            model_name = self.model.split(":")[0]
            if model_name not in result.stdout:
                # Try to pull the model
                print(f"Pulling {self.model} (this may take a few minutes)...")
                pull_result = subprocess.run(
                    ["ollama", "pull", self.model],
                    capture_output=True,
                    text=True,
                    timeout=600  # 10 minutes to download
                )
                if pull_result.returncode != 0:
                    print(f"Warning: Could not pull {self.model}: {pull_result.stderr}")
        except subprocess.TimeoutExpired:
            print(f"Warning: Could not verify {self.model} availability")
        except FileNotFoundError:
            print("Warning: Ollama not installed. Install from https://ollama.ai")
    
    def analyze_frame(self, image_data: bytes) -> str:
        """
        Analyze a single frame.
        
        Args:
            image_data: Raw image bytes.
            
        Returns:
            Description of the frame content.
        """
        import requests
        
        base64_image = base64.b64encode(image_data).decode("utf-8")
        
        print(f"[DEBUG] Using model: {self.model}")
        
        prompt = """Describe what's shown in this screen recording frame. 
Focus on: slides, diagrams, text content, UI elements, and any important visual information.
Be concise but detailed."""
        
        payload = {
            "model": self.model,
            "prompt": prompt,
            "images": [base64_image],
            "stream": False,
            "options": {
                "temperature": self.temperature
            }
        }
        
        try:
            response = requests.post(
                f"{self.base_url}/api/generate",
                json=payload,
                timeout=60
            )
            
            if response.status_code == 200:
                result = response.json()
                return result.get("response", "No description available")
            else:
                return f"Error: {response.status_code} - {response.text}"
        
        except requests.exceptions.RequestException as e:
            return f"Connection error: {str(e)}"
    
    def analyze_frames(self, frames: List[bytes]) -> List[str]:
        """
        Analyze multiple frames.
        
        Args:
            frames: List of image bytes.
            
        Returns:
            List of descriptions for each frame.
        """
        descriptions = []
        
        for i, frame_data in enumerate(frames):
            print(f"Analyzing frame {i+1}/{len(frames)}...")
            try:
                description = self.analyze_frame(frame_data)
                descriptions.append(description)
            except Exception as e:
                descriptions.append(f"Error: {str(e)}")
        
        return descriptions
    
    def summarize_slides(self, descriptions: List[str]) -> str:
        """
        Create a summary of all slide descriptions.
        
        Args:
            descriptions: List of frame descriptions.
            
        Returns:
            Combined summary.
        """
        if not descriptions:
            return "No slides to summarize."
        
        # Use Ollama to generate summary
        import requests
        
        slides_text = "\n\n".join(
            f"Slide {i+1}: {desc}"
            for i, desc in enumerate(descriptions)
        )
        
        prompt = f"""Based on these slide descriptions from a presentation, 
provide a concise summary of the key points covered:

{slides_text}

Format your response as:
- Main topic:
- Key points (3-5):
- Conclusions:"""
        
        payload = {
            "model": self.model,
            "prompt": prompt,
            "stream": False,
            "options": {
                "temperature": self.temperature
            }
        }
        
        try:
            response = requests.post(
                f"{self.base_url}/api/generate",
                json=payload,
                timeout=60
            )
            
            if response.status_code == 200:
                result = response.json()
                return result.get("response", "No summary available")
            else:
                # Fallback to simple concatenation
                return self._simple_summary(descriptions)
        
        except requests.exceptions.RequestException:
            return self._simple_summary(descriptions)
    
    def _simple_summary(self, descriptions: List[str]) -> str:
        """Generate a simple summary without LLM."""
        if not descriptions:
            return "No content to summarize."
        
        return f"Presentation with {len(descriptions)} slides. " \
               f"First slide: {descriptions[0][:200]}..."


def create_vision_provider(
    provider_type: str,
    **kwargs
) -> Optional[OllamaVisionProvider]:
    """
    Factory function to create vision providers.
    
    Args:
        provider_type: "ollama" or "openai"
        **kwargs: Additional arguments for the provider
        
    Returns:
        Vision provider instance or None if invalid type
    """
    if provider_type == "ollama":
        return OllamaVisionProvider(
            model=kwargs.get("model", "llava:7b"),
            base_url=kwargs.get("base_url", "http://localhost:11434")
        )
    # OpenAI would be imported and created here if available
    return None
