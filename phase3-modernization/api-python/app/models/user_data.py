"""
User-related data models (MyJobs, MyResumes, MySearches).
"""
from datetime import datetime
from ..extensions import db


class MyJob(db.Model):
    """Saved/favorite jobs for job seekers."""
    
    __tablename__ = 'my_jobs'
    
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False, index=True)
    job_posting_id = db.Column(db.Integer, db.ForeignKey('job_postings.id'), nullable=False, index=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    
    # Relationships
    job_posting = db.relationship('JobPosting', backref='saved_by')
    
    # Unique constraint to prevent duplicate saves
    __table_args__ = (
        db.UniqueConstraint('user_id', 'job_posting_id', name='uq_user_job'),
    )
    
    def __repr__(self):
        return f'<MyJob user={self.user_id} job={self.job_posting_id}>'


class MyResume(db.Model):
    """Saved/favorite resumes for employers."""
    
    __tablename__ = 'my_resumes'
    
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False, index=True)
    resume_id = db.Column(db.Integer, db.ForeignKey('resumes.id'), nullable=False, index=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    
    # Relationships
    resume = db.relationship('Resume', backref='saved_by')
    
    # Unique constraint to prevent duplicate saves
    __table_args__ = (
        db.UniqueConstraint('user_id', 'resume_id', name='uq_user_resume'),
    )
    
    def __repr__(self):
        return f'<MyResume user={self.user_id} resume={self.resume_id}>'


class MySearch(db.Model):
    """Saved search criteria for users."""
    
    __tablename__ = 'my_searches'
    
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False, index=True)
    
    # Search criteria
    search_criteria = db.Column(db.String(255))
    city = db.Column(db.String(50))
    state_id = db.Column(db.Integer, db.ForeignKey('states.id'))
    country_id = db.Column(db.Integer, db.ForeignKey('countries.id'))
    
    # Timestamps
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    
    # Relationships
    state = db.relationship('State', backref='saved_searches')
    country = db.relationship('Country', backref='saved_searches')
    
    def __repr__(self):
        return f'<MySearch user={self.user_id} criteria={self.search_criteria}>'
