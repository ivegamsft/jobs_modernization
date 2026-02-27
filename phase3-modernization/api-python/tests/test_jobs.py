"""
Tests for job-related routes.
"""
import pytest


def test_home_page(client):
    """Test home page loads."""
    response = client.get('/')
    assert response.status_code == 200
    assert b'JobSite' in response.data or b'Find' in response.data


def test_about_page(client):
    """Test about page loads."""
    response = client.get('/about')
    assert response.status_code == 200


def test_contact_page(client):
    """Test contact page loads."""
    response = client.get('/contact')
    assert response.status_code == 200


def test_job_search_requires_login(client):
    """Test job search requires authentication."""
    response = client.get('/jobseeker/job-search')
    assert response.status_code == 302  # Redirect to login
