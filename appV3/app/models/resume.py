"""
Resume model for job seeker profiles.
"""
from datetime import datetime
from ..extensions import db


class Resume(db.Model):
    """Resume/CV model for job seekers."""
    
    __tablename__ = 'resumes'
    
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False, index=True)
    
    # Resume details
    job_title = db.Column(db.String(255), nullable=False)
    resume_text = db.Column(db.Text)
    cover_letter_text = db.Column(db.Text)
    
    # Target location
    target_city = db.Column(db.String(50))
    target_state_id = db.Column(db.Integer, db.ForeignKey('states.id'))
    target_country_id = db.Column(db.Integer, db.ForeignKey('countries.id'))
    relocation_country_id = db.Column(db.Integer, db.ForeignKey('countries.id'))
    
    # Requirements
    target_job_type_id = db.Column(db.Integer, db.ForeignKey('job_types.id'))
    education_level_id = db.Column(db.Integer, db.ForeignKey('education_levels.id'))
    experience_level_id = db.Column(db.Integer, db.ForeignKey('experience_levels.id'))
    
    # Category
    category_id = db.Column(db.Integer)
    subcategory_id = db.Column(db.Integer)
    
    # Visibility
    is_searchable = db.Column(db.Boolean, default=True)
    
    # Timestamps
    post_date = db.Column(db.DateTime, default=datetime.utcnow)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationships
    target_state = db.relationship('State', foreign_keys=[target_state_id], backref='resumes_target')
    target_country = db.relationship('Country', foreign_keys=[target_country_id], backref='resumes_target')
    relocation_country = db.relationship('Country', foreign_keys=[relocation_country_id], backref='resumes_relocation')
    target_job_type = db.relationship('JobType', backref='resumes')
    education_level = db.relationship('EducationLevel', backref='resumes')
    experience_level = db.relationship('ExperienceLevel', backref='resumes')
    
    def __repr__(self):
        return f'<Resume {self.job_title}>'
    
    @property
    def target_location(self):
        """Return formatted target location."""
        parts = []
        if self.target_city:
            parts.append(self.target_city)
        if self.target_state:
            parts.append(self.target_state.state_name)
        if self.target_country:
            parts.append(self.target_country.country_name)
        return ', '.join(parts) if parts else 'Any location'
