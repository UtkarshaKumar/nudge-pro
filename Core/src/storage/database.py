"""Database storage for sessions."""

from pathlib import Path
from dataclasses import dataclass, asdict, field
from datetime import datetime
from typing import Optional, List, Dict, Any
import json


@dataclass
class SessionData:
    """In-memory session representation."""
    id: str
    title: str
    mode: str
    status: str
    started_at: str
    stopped_at: Optional[str] = None
    audio_dir: Optional[str] = None
    transcript: Optional[str] = None
    actions: List[Dict[str, Any]] = field(default_factory=list)
    video_path: Optional[str] = None
    notes_path: Optional[str] = None
    
    def to_dict(self) -> dict:
        data = asdict(self)
        return data


class Database:
    """
    Simple file-based session storage.
    
    Responsibilities:
    - Create new sessions
    - Update session status
    - Query sessions
    """
    
    def __init__(self, db_path: Path):
        self.db_path = db_path
        self._active_session: Optional[SessionData] = None
        self._sessions_dir = db_path.parent / "sessions"
    
    def create_session(self, title: str, mode: str) -> SessionData:
        """Create a new session."""
        timestamp = datetime.now().timestamp()
        session = SessionData(
            id=str(timestamp),
            title=title,
            mode=mode,
            status="recording",
            started_at=datetime.now().isoformat()
        )
        self._active_session = session
        
        # Create session directory
        session_dir = self._sessions_dir / session.id
        session_dir.mkdir(parents=True, exist_ok=True)
        
        return session
    
    def get_active_session(self) -> Optional[SessionData]:
        """Get the currently active session."""
        return self._active_session
    
    def update_session(self, session: SessionData) -> None:
        """Update a session."""
        self._active_session = session
        
        # Also save to file
        session_dir = self._sessions_dir / session.id
        if session_dir.exists():
            (session_dir / "session.json").write_text(
                json.dumps(session.to_dict(), indent=2)
            )
    
    def get_session(self, session_id: str) -> Optional[SessionData]:
        """Get a specific session by ID."""
        session_file = self._sessions_dir / session_id / "session.json"
        if session_file.exists():
            data = json.loads(session_file.read_text())
            return SessionData(**data)
        return None
    
    def list_sessions(self, limit: int = 10) -> List[SessionData]:
        """List recent sessions."""
        sessions = []
        
        if not self._sessions_dir.exists():
            return sessions
        
        # Get all session directories
        session_dirs = sorted(
            self._sessions_dir.iterdir(),
            key=lambda x: x.stat().st_mtime,
            reverse=True
        )
        
        for session_dir in session_dirs[:limit]:
            if session_dir.is_dir():
                session_file = session_dir / "session.json"
                if session_file.exists():
                    try:
                        data = json.loads(session_file.read_text())
                        sessions.append(SessionData(**data))
                    except json.JSONDecodeError:
                        pass
        
        return sessions
    
    def delete_session(self, session_id: str) -> bool:
        """Delete a session and its files."""
        session_dir = self._sessions_dir / session_id
        if session_dir.exists():
            import shutil
            shutil.rmtree(session_dir)
            return True
        return False
