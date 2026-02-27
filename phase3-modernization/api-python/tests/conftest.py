"""
Test configuration and fixtures.
"""
import pytest
from app import create_app
from app.extensions import db
from app.config import TestingConfig


@pytest.fixture(scope='session')
def app():
    """Create application for testing."""
    app = create_app(TestingConfig)
    
    with app.app_context():
        db.create_all()
        yield app
        db.drop_all()


@pytest.fixture
def client(app):
    """Create a test client."""
    return app.test_client()


@pytest.fixture
def runner(app):
    """Create a test CLI runner."""
    return app.test_cli_runner()


@pytest.fixture
def auth_client(client, app):
    """Create an authenticated test client."""
    from app.models import User
    
    with app.app_context():
        user = User(
            username='testuser',
            email='test@example.com',
            user_type='jobseeker',
            first_name='Test',
            last_name='User'
        )
        user.set_password('testpassword')
        db.session.add(user)
        db.session.commit()
        
        # Login
        client.post('/auth/login', data={
            'username': 'testuser',
            'password': 'testpassword'
        }, follow_redirects=True)
    
    return client
