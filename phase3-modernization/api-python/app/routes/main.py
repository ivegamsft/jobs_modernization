"""
Main routes (home, about, public pages).
"""
from flask import Blueprint, render_template
from ..models import JobPosting

main_bp = Blueprint('main', __name__)


@main_bp.route('/')
def index():
    """Home page with latest job postings."""
    latest_jobs = JobPosting.query.filter_by(is_active=True)\
        .order_by(JobPosting.posted_date.desc())\
        .limit(10)\
        .all()
    return render_template('main/index.html', jobs=latest_jobs)


@main_bp.route('/about')
def about():
    """About page."""
    return render_template('main/about.html')


@main_bp.route('/contact')
def contact():
    """Contact page."""
    return render_template('main/contact.html')


@main_bp.route('/privacy')
def privacy():
    """Privacy policy page."""
    return render_template('main/privacy.html')


@main_bp.route('/terms')
def terms():
    """Terms of service page."""
    return render_template('main/terms.html')
