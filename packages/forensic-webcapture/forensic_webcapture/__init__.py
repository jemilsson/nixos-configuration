"""
Forensic Web Capture Tool with TLS Certificate Preservation and Browser Spoofing
Creates court-admissible captures with cryptographic proof of origin
"""

__version__ = "4.0.0"

# Lazy imports to avoid dependency issues
def __getattr__(name):
    if name == 'ForensicCapture':
        from .capture import ForensicCapture
        return ForensicCapture
    elif name == 'browse_capture':
        from .server import browse_capture
        return browse_capture
    elif name == 'verify_capture':
        from .utils import verify_capture
        return verify_capture
    elif name == 'main':
        from .main import main
        return main
    raise AttributeError(f"module '{__name__}' has no attribute '{name}'")

__all__ = ['ForensicCapture', 'browse_capture', 'verify_capture', 'main']