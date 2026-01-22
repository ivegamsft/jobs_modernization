"""
Tests for authentication routes.
"""
import pytest


def test_login_page(client):
    """Test login page loads."""
    response = client.get('/auth/login')
    assert response.status_code == 200
    assert b'Sign in' in response.data or b'Login' in response.data


def test_register_page(client):
    """Test register page loads."""
    response = client.get('/auth/register')
    assert response.status_code == 200
    assert b'Create Account' in response.data or b'Register' in response.data


def test_login_with_invalid_credentials(client):
    """Test login with invalid credentials."""
    response = client.post('/auth/login', data={
        'username': 'nonexistent',
        'password': 'wrongpassword'
    }, follow_redirects=True)
    assert response.status_code == 200
    assert b'Invalid username or password' in response.data


def test_register_new_user(client, app):
    """Test registering a new user."""
    response = client.post('/auth/register', data={
        'username': 'newuser',
        'email': 'newuser@example.com',
        'first_name': 'New',
        'last_name': 'User',
        'user_type': 'jobseeker',
        'password': 'password123',
        'confirm_password': 'password123'
    }, follow_redirects=True)
    assert response.status_code == 200
    
    from app.models import User
    with app.app_context():
        user = User.query.filter_by(username='newuser').first()
        assert user is not None
        assert user.email == 'newuser@example.com'


def test_logout(auth_client):
    """Test logout."""
    response = auth_client.get('/auth/logout', follow_redirects=True)
    assert response.status_code == 200
