"""
Tests for resume-related routes.
"""
import pytest


def test_resume_page_requires_login(client):
    """Test resume page requires authentication."""
    response = client.get('/jobseeker/resume')
    assert response.status_code == 302  # Redirect to login


def test_resume_search_requires_employer(client):
    """Test resume search requires employer authentication."""
    response = client.get('/employer/resume-search')
    assert response.status_code == 302  # Redirect to login
