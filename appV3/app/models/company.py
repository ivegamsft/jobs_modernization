"""
Company model for employer profiles.
"""
from datetime import datetime
from ..extensions import db


class Company(db.Model):
    """Company/Employer profile model."""
    
    __tablename__ = 'companies'
    
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False, index=True)
    
    # Company information
    company_name = db.Column(db.String(255), nullable=False)
    company_profile = db.Column(db.Text)
    
    # Address
    address1 = db.Column(db.String(255))
    address2 = db.Column(db.String(255))
    city = db.Column(db.String(50))
    state_id = db.Column(db.Integer, db.ForeignKey('states.id'))
    country_id = db.Column(db.Integer, db.ForeignKey('countries.id'))
    postal_code = db.Column(db.String(50))
    
    # Contact information
    phone = db.Column(db.String(50))
    fax = db.Column(db.String(50))
    email = db.Column(db.String(255))
    website_url = db.Column(db.String(255))
    
    # Timestamps
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationships
    state = db.relationship('State', backref='companies')
    country = db.relationship('Country', backref='companies')
    job_postings = db.relationship('JobPosting', backref='company', lazy='dynamic')
    
    def __repr__(self):
        return f'<Company {self.company_name}>'
    
    @property
    def full_address(self):
        """Return formatted full address."""
        parts = [self.address1]
        if self.address2:
            parts.append(self.address2)
        parts.append(f'{self.city}')
        if self.state:
            parts.append(self.state.state_name)
        if self.postal_code:
            parts.append(self.postal_code)
        if self.country:
            parts.append(self.country.country_name)
        return ', '.join(filter(None, parts))
