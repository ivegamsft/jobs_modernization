"""
Database seed script for initial data.
Run with: python scripts/seed_data.py
"""
import sys
import os

# Add the parent directory to the path
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app import create_app
from app.extensions import db
from app.models import (
    User, Country, State, EducationLevel, ExperienceLevel, JobType
)


def seed_countries():
    """Seed countries."""
    countries = [
        'United States',
        'Canada',
        'United Kingdom',
        'Australia',
        'Germany',
        'France',
        'India',
        'Japan',
        'Brazil',
        'Mexico',
    ]
    
    for name in countries:
        if not Country.query.filter_by(country_name=name).first():
            country = Country(country_name=name)
            db.session.add(country)
    
    db.session.commit()
    print(f"Seeded {len(countries)} countries")


def seed_states():
    """Seed US states."""
    us = Country.query.filter_by(country_name='United States').first()
    if not us:
        print("United States not found, skipping states")
        return
    
    states = [
        'Alabama', 'Alaska', 'Arizona', 'Arkansas', 'California',
        'Colorado', 'Connecticut', 'Delaware', 'Florida', 'Georgia',
        'Hawaii', 'Idaho', 'Illinois', 'Indiana', 'Iowa',
        'Kansas', 'Kentucky', 'Louisiana', 'Maine', 'Maryland',
        'Massachusetts', 'Michigan', 'Minnesota', 'Mississippi', 'Missouri',
        'Montana', 'Nebraska', 'Nevada', 'New Hampshire', 'New Jersey',
        'New Mexico', 'New York', 'North Carolina', 'North Dakota', 'Ohio',
        'Oklahoma', 'Oregon', 'Pennsylvania', 'Rhode Island', 'South Carolina',
        'South Dakota', 'Tennessee', 'Texas', 'Utah', 'Vermont',
        'Virginia', 'Washington', 'West Virginia', 'Wisconsin', 'Wyoming',
    ]
    
    for name in states:
        if not State.query.filter_by(state_name=name, country_id=us.id).first():
            state = State(state_name=name, country_id=us.id)
            db.session.add(state)
    
    db.session.commit()
    print(f"Seeded {len(states)} states")


def seed_education_levels():
    """Seed education levels."""
    levels = [
        'High School',
        'Some College',
        'Associate Degree',
        'Bachelor\'s Degree',
        'Master\'s Degree',
        'Doctorate',
        'Professional Degree',
        'Vocational Training',
    ]
    
    for name in levels:
        if not EducationLevel.query.filter_by(education_level_name=name).first():
            level = EducationLevel(education_level_name=name)
            db.session.add(level)
    
    db.session.commit()
    print(f"Seeded {len(levels)} education levels")


def seed_experience_levels():
    """Seed experience levels."""
    levels = [
        'Entry Level (0-1 years)',
        'Junior (1-3 years)',
        'Mid-Level (3-5 years)',
        'Senior (5-8 years)',
        'Lead (8-10 years)',
        'Principal (10+ years)',
        'Executive',
    ]
    
    for name in levels:
        if not ExperienceLevel.query.filter_by(experience_level_name=name).first():
            level = ExperienceLevel(experience_level_name=name)
            db.session.add(level)
    
    db.session.commit()
    print(f"Seeded {len(levels)} experience levels")


def seed_job_types():
    """Seed job types."""
    types = [
        'Full-Time',
        'Part-Time',
        'Contract',
        'Temporary',
        'Internship',
        'Freelance',
        'Remote',
    ]
    
    for name in types:
        if not JobType.query.filter_by(job_type_name=name).first():
            job_type = JobType(job_type_name=name)
            db.session.add(job_type)
    
    db.session.commit()
    print(f"Seeded {len(types)} job types")


def seed_admin_user():
    """Seed admin user."""
    if not User.query.filter_by(username='admin').first():
        admin = User(
            username='admin',
            email='admin@jobsite.com',
            user_type='jobseeker',
            first_name='Admin',
            last_name='User',
            is_admin=True,
            is_active=True
        )
        admin.set_password('admin123')
        db.session.add(admin)
        db.session.commit()
        print("Created admin user (username: admin, password: admin123)")
    else:
        print("Admin user already exists")


def main():
    """Run all seed functions."""
    app = create_app()
    
    with app.app_context():
        print("Starting database seed...")
        print("-" * 40)
        
        seed_countries()
        seed_states()
        seed_education_levels()
        seed_experience_levels()
        seed_job_types()
        seed_admin_user()
        
        print("-" * 40)
        print("Database seed completed!")


if __name__ == '__main__':
    main()
