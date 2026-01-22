"""
Reference data models (Countries, States, Education Levels, etc.)
"""
from ..extensions import db


class Country(db.Model):
    """Country reference data."""
    
    __tablename__ = 'countries'
    
    id = db.Column(db.Integer, primary_key=True)
    country_name = db.Column(db.String(255), nullable=False, unique=True)
    
    # Relationships
    states = db.relationship('State', backref='country', lazy='dynamic')
    
    def __repr__(self):
        return f'<Country {self.country_name}>'


class State(db.Model):
    """State/Province reference data."""
    
    __tablename__ = 'states'
    
    id = db.Column(db.Integer, primary_key=True)
    country_id = db.Column(db.Integer, db.ForeignKey('countries.id'), nullable=False, index=True)
    state_name = db.Column(db.String(255), nullable=False)
    
    def __repr__(self):
        return f'<State {self.state_name}>'


class EducationLevel(db.Model):
    """Education level reference data."""
    
    __tablename__ = 'education_levels'
    
    id = db.Column(db.Integer, primary_key=True)
    education_level_name = db.Column(db.String(50), nullable=False, unique=True)
    
    def __repr__(self):
        return f'<EducationLevel {self.education_level_name}>'


class ExperienceLevel(db.Model):
    """Experience level reference data."""
    
    __tablename__ = 'experience_levels'
    
    id = db.Column(db.Integer, primary_key=True)
    experience_level_name = db.Column(db.String(255), nullable=False, unique=True)
    
    def __repr__(self):
        return f'<ExperienceLevel {self.experience_level_name}>'


class JobType(db.Model):
    """Job type reference data (Full-time, Part-time, etc.)."""
    
    __tablename__ = 'job_types'
    
    id = db.Column(db.Integer, primary_key=True)
    job_type_name = db.Column(db.String(50), nullable=False, unique=True)
    
    def __repr__(self):
        return f'<JobType {self.job_type_name}>'
