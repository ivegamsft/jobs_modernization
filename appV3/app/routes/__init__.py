"""
Flask routes module.
"""
from .main import main_bp
from .auth import auth_bp
from .employer import employer_bp
from .jobseeker import jobseeker_bp
from .admin import admin_bp

__all__ = [
    'main_bp',
    'auth_bp',
    'employer_bp',
    'jobseeker_bp',
    'admin_bp',
]
