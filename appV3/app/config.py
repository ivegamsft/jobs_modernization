"""
Flask application configuration settings.
"""
import os
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()


class Config:
    """Base configuration class."""
    
    # Flask
    SECRET_KEY = os.environ.get('SECRET_KEY', 'dev-secret-key-change-in-production')
    
    # Database - SQL Server connection
    # Set DATABASE_URL environment variable:
    # SQL Server: mssql+pyodbc://user:pass@server/database?driver=ODBC+Driver+17+for+SQL+Server
    # PostgreSQL: postgresql+psycopg://user:pass@localhost:5432/database
    # SQLite: sqlite:///jobsite.db
    SQLALCHEMY_DATABASE_URI = os.environ.get(
        'DATABASE_URL',
        'mssql+pyodbc://sa:YourPassword123!@localhost/JobsDB?driver=ODBC+Driver+17+for+SQL+Server&TrustServerCertificate=yes'
    )
    SQLALCHEMY_TRACK_MODIFICATIONS = False
    SQLALCHEMY_ENGINE_OPTIONS = {
        'pool_pre_ping': True,
        'pool_recycle': 300,
    }
    
    # Application
    APP_NAME = os.environ.get('APP_NAME', 'JobSite')
    ITEMS_PER_PAGE = int(os.environ.get('ITEMS_PER_PAGE', 10))
    
    # Security
    SESSION_COOKIE_SECURE = True
    SESSION_COOKIE_HTTPONLY = True
    SESSION_COOKIE_SAMESITE = 'Lax'
    
    # WTForms
    WTF_CSRF_ENABLED = True


class DevelopmentConfig(Config):
    """Development configuration."""
    
    DEBUG = True
    SESSION_COOKIE_SECURE = False


class ProductionConfig(Config):
    """Production configuration."""
    
    DEBUG = False
    
    # Enforce HTTPS in production
    SESSION_COOKIE_SECURE = True
    

class TestingConfig(Config):
    """Testing configuration."""
    
    TESTING = True
    SQLALCHEMY_DATABASE_URI = 'postgresql://jobsite:jobsite123@localhost:5432/jobsite_test_db'
    WTF_CSRF_ENABLED = False


# Configuration dictionary
config = {
    'development': DevelopmentConfig,
    'production': ProductionConfig,
    'testing': TestingConfig,
    'default': DevelopmentConfig
}


def get_config():
    """Get configuration based on environment."""
    env = os.environ.get('FLASK_ENV', 'development')
    return config.get(env, config['default'])
