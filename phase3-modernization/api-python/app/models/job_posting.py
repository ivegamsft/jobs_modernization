"""
JobPosting model for job listings.
"""
from datetime import datetime
from ..extensions import db


class JobPosting(db.Model):
    """Job posting model."""
    
    __tablename__ = 'job_postings'
    
    id = db.Column(db.Integer, primary_key=True)
    company_id = db.Column(db.Integer, db.ForeignKey('companies.id'), nullable=False, index=True)
    
    # Job details
    title = db.Column(db.String(255), nullable=False)
    description = db.Column(db.Text, nullable=False)
    department = db.Column(db.String(50))
    job_code = db.Column(db.String(50))
    contact_person = db.Column(db.String(255))
    
    # Location
    city = db.Column(db.String(50))
    state_id = db.Column(db.Integer, db.ForeignKey('states.id'))
    country_id = db.Column(db.Integer, db.ForeignKey('countries.id'))
    
    # Requirements
    education_level_id = db.Column(db.Integer, db.ForeignKey('education_levels.id'))
    job_type_id = db.Column(db.Integer, db.ForeignKey('job_types.id'))
    category_id = db.Column(db.Integer)
    
    # Salary
    min_salary = db.Column(db.Numeric(12, 2))
    max_salary = db.Column(db.Numeric(12, 2))
    
    # Metadata
    posted_date = db.Column(db.DateTime, default=datetime.utcnow)
    posted_by = db.Column(db.String(50))
    is_active = db.Column(db.Boolean, default=True)
    
    # Timestamps
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationships
    state = db.relationship('State', backref='job_postings')
    country = db.relationship('Country', backref='job_postings')
    education_level = db.relationship('EducationLevel', backref='job_postings')
    job_type = db.relationship('JobType', backref='job_postings')
    
    def __repr__(self):
        return f'<JobPosting {self.title}>'
    
    @property
    def salary_range(self):
        """Return formatted salary range."""
        if self.min_salary and self.max_salary:
            return f'${self.min_salary:,.0f} - ${self.max_salary:,.0f}'
        elif self.min_salary:
            return f'From ${self.min_salary:,.0f}'
        elif self.max_salary:
            return f'Up to ${self.max_salary:,.0f}'
        return 'Not specified'
    
    @property
    def location(self):
        """Return formatted location."""
        parts = []
        if self.city:
            parts.append(self.city)
        if self.state:
            parts.append(self.state.state_name)
        if self.country:
            parts.append(self.country.country_name)
        return ', '.join(parts) if parts else 'Not specified'
