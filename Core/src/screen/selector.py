"""
Monitor selection and detection for screen capture.

This module provides functionality to detect and enumerate available
monitors/displays on macOS, allowing users to select which screen
to record.
"""

import subprocess
import json
import re
from dataclasses import dataclass
from typing import Optional, List
from pathlib import Path


@dataclass
class Monitor:
    """Represents a display monitor."""
    id: str
    name: str
    width: int
    height: int
    is_primary: bool
    display_id: int = 0
    
    def to_dict(self) -> dict:
        return {
            "id": self.id,
            "name": self.name,
            "width": self.width,
            "height": self.height,
            "isPrimary": self.is_primary,
            "displayID": self.display_id,
            "resolution": f"{self.width} × {self.height}"
        }


class MonitorSelector:
    """
    Detects and selects available monitors.
    
    This class provides functionality to:
    - Enumerate all available displays
    - Get the primary display
    - Look up displays by ID
    - Provide human-readable descriptions
    
    Example:
        >>> selector = MonitorSelector()
        >>> monitors = selector.list_monitors()
        >>> for m in monitors:
        ...     print(f"{m.name}: {m.resolution}")
    """
    
    def __init__(self):
        self._cached_monitors: Optional[List[Monitor]] = None
    
    def list_monitors(self, force_refresh: bool = False) -> List[Monitor]:
        """
        List all available monitors.
        
        Args:
            force_refresh: If True, bypass cache and re-detect monitors.
            
        Returns:
            List of Monitor objects representing available displays.
        """
        if self._cached_monitors is not None and not force_refresh:
            return self._cached_monitors
        
        monitors = []
        
        # Try multiple methods to detect monitors
        monitors = self._detect_via_system_profiler()
        
        if not monitors:
            monitors = self._detect_via_display_manager()
        
        if not monitors:
            # Fallback: create a default primary monitor
            monitors = [
                Monitor(
                    id="0",
                    name="Primary Display",
                    width=1920,
                    height=1080,
                    is_primary=True,
                    display_id=0
                )
            ]
        
        self._cached_monitors = monitors
        return monitors
    
    def _detect_via_system_profiler(self) -> List[Monitor]:
        """Detect monitors using system_profiler."""
        monitors = []
        
        try:
            result = subprocess.run(
                ["system_profiler", "SPDisplaysDataType", "-json"],
                capture_output=True,
                text=True,
                timeout=30
            )
            
            if result.returncode != 0:
                return []
            
            data = json.loads(result.stdout)
            displays = data.get("SPDisplaysDataType", [])
            
            if not isinstance(displays, list):
                displays = [displays]
            
            display_id = 0
            for display_info in displays:
                # Get display name
                name = display_info.get("sppci_model", "Display")
                if "Built-in" in str(display_info):
                    name = "Built-in Retina Display"
                
                # Get resolution
                resolution = display_info.get("_spdisplays_resolution", "")
                width, height = self._parse_resolution(resolution)
                
                # Check if this is the primary display
                is_primary = display_info.get("spdisplays_main", False)
                
                # Get display ID for ffmpeg
                # ffmpeg uses 0 for main, 1+ for additional
                ff_display_id = display_id
                display_id += 1
                
                monitor = Monitor(
                    id=str(ff_display_id),
                    name=name,
                    width=width,
                    height=height,
                    is_primary=is_primary,
                    display_id=ff_display_id
                )
                monitors.append(monitor)
                
        except (subprocess.TimeoutExpired, json.JSONDecodeError, KeyError):
            pass
        
        return monitors
    
    def _detect_via_display_manager(self) -> List[Monitor]:
        """Alternative detection using Core Graphics."""
        try:
            # Use Python with Quartz (Core Graphics) to get displays
            result = subprocess.run(
                ["python3", "-c", """
import Quartz
import json

displays = []
display_id = 0

for screen in Quartz.CGGetActiveDisplayList()[1]:
    info = Quartz.CGDisplayCopyDisplayMode(screen)
    width = info.get('Width', 0)
    height = info.get('Height', 0)
    is_main = Quartz.CGDisplayIsMain(display_id) != 0
    
    name = "Display"
    if is_main:
        name = "Primary Display"
    
    displays.append({
        'id': str(display_id),
        'name': name,
        'width': width,
        'height': height,
        'isPrimary': is_main,
        'displayID': display_id
    })
    display_id += 1

print(json.dumps(displays))
"""],
                capture_output=True,
                text=True,
                timeout=10
            )
            
            if result.returncode == 0 and result.stdout.strip():
                data = json.loads(result.stdout)
                return [
                    Monitor(
                        id=m["id"],
                        name=m["name"],
                        width=m["width"],
                        height=m["height"],
                        is_primary=m["isPrimary"],
                        display_id=m["displayID"]
                    )
                    for m in data
                ]
        except (subprocess.TimeoutExpired, json.JSONDecodeError, FileNotFoundError):
            pass
        
        return []
    
    def _parse_resolution(self, resolution: str) -> tuple[int, int]:
        """Parse resolution string like '2560 x 1440' to (width, height)."""
        if not resolution:
            return (1920, 1080)
        
        # Try to extract numbers
        match = re.search(r'(\d+)\s*[x×]\s*(\d+)', resolution)
        if match:
            return (int(match.group(1)), int(match.group(2)))
        
        return (1920, 1080)  # Default fallback
    
    def get_primary_monitor(self) -> Monitor:
        """
        Get the primary monitor.
        
        Returns:
            Monitor object for the primary display.
            
        Raises:
            RuntimeError: If no monitors are available.
        """
        monitors = self.list_monitors()
        
        for monitor in monitors:
            if monitor.is_primary:
                return monitor
        
        # If no primary found, return first monitor
        if monitors:
            monitors[0].is_primary = True
            return monitors[0]
        
        raise RuntimeError("No monitors available")
    
    def get_monitor_by_id(self, monitor_id: str) -> Optional[Monitor]:
        """
        Get a monitor by its ID.
        
        Args:
            monitor_id: The ID of the monitor to find.
            
        Returns:
            Monitor object if found, None otherwise.
        """
        monitors = self.list_monitors()
        
        for monitor in monitors:
            if monitor.id == monitor_id:
                return monitor
        
        return None
    
    def get_monitor_by_display_id(self, display_id: int) -> Optional[Monitor]:
        """
        Get a monitor by its ffmpeg display ID.
        
        Args:
            display_id: The ffmpeg display ID.
            
        Returns:
            Monitor object if found, None otherwise.
        """
        monitors = self.list_monitors()
        
        for monitor in monitors:
            if monitor.display_id == display_id:
                return monitor
        
        return None
    
    def get_or_prompt_primary(self) -> Monitor:
        """
        Get the primary monitor, creating one if none exist.
        
        This is a convenience method that ensures a monitor is always
        available, even if detection fails.
        
        Returns:
            Monitor object for the primary display.
        """
        monitors = self.list_monitors()
        
        if not monitors:
            # Create a default primary monitor
            return Monitor(
                id="0",
                name="Primary Display",
                width=1920,
                height=1080,
                is_primary=True,
                display_id=0
            )
        
        return self.get_primary_monitor()


class MonitorPicker:
    """
    Interactive monitor selection for CLI usage.
    
    This class provides a simple CLI interface for users to select
    a monitor when multiple are available.
    """
    
    def __init__(self):
        self.selector = MonitorSelector()
    
    def prompt_selection(self, allow_default: bool = True) -> Monitor:
        """
        Prompt user to select a monitor.
        
        Args:
            allow_default: If True, allow selecting the default monitor.
            
        Returns:
            The selected Monitor object.
        """
        monitors = self.selector.list_monitors()
        
        if not monitors:
            print("No monitors detected!")
            return self.selector.get_or_prompt_primary()
        
        if len(monitors) == 1:
            print(f"Only one monitor available: {monitors[0].name}")
            return monitors[0]
        
        print("\nAvailable monitors:")
        for i, monitor in enumerate(monitors):
            primary_marker = " (primary)" if monitor.is_primary else ""
            print(f"  {i + 1}. {monitor.name}{primary_marker}")
            print(f"     {monitor.width} × {monitor.height}")
        
        if allow_default:
            print(f"  0. Use primary monitor")
        
        print()
        
        while True:
            try:
                choice = input("Select monitor [0]: ").strip()
                if not choice:
                    return self.selector.get_primary_monitor()
                
                idx = int(choice) - 1
                if 0 <= idx < len(monitors):
                    return monitors[idx]
                
                if allow_default and idx == -1:
                    return self.selector.get_primary_monitor()
                
                print("Invalid selection. Try again.")
            except ValueError:
                print("Please enter a number.")
    
    def get_default_or_prompt(self) -> Monitor:
        """
        Get default monitor or prompt if multiple available.
        
        Returns:
            The selected Monitor.
        """
        monitors = self.selector.list_monitors()
        
        if len(monitors) <= 1:
            return monitors[0] if monitors else self.selector.get_or_prompt_primary()
        
        return self.prompt_selection()
