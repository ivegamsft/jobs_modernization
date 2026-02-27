"""
User model for authentication and authorization.
"""
from datetime import datetime
from flask_login import UserMixin
from ..extensions import db, bcrypt


class User(UserMixin, db.Model):
    """User model for authentication."""
    
    __tablename__ = 'users'
    
    id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(50), unique=True, nullable=False, index=True)
    email = db.Column(db.String(255), unique=True, nullable=False, index=True)
    password_hash = db.Column(db.String(255), nullable=False)
    
    # User type: 'employer' or 'jobseeker'
    user_type = db.Column(db.String(20), nullable=False, default='jobseeker')
    
    # Profile fields
    first_name = db.Column(db.String(100))
    last_name = db.Column(db.String(100))
    phone = db.Column(db.String(50))
    
    # Status
    is_active = db.Column(db.Boolean, default=True)
    is_admin = db.Column(db.Boolean, default=False)
    
    # Timestamps
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    last_login = db.Column(db.DateTime)
    
    # Relationships
    company = db.relationship('Company', backref='user', uselist=False, lazy='select')
    resumes = db.relationship('Resume', backref='user', lazy='dynamic')
    my_jobs = db.relationship('MyJob', backref='user', lazy='dynamic')
    my_resumes = db.relationship('MyResume', backref='user', lazy='dynamic')
    my_searches = db.relationship('MySearch', backref='user', lazy='dynamic')
    
    def __repr__(self):
        return f'<User {self.username}>'
    
    def set_password(self, password):
        """Hash and set the user's password."""
        self.password_hash = bcrypt.generate_password_hash(password).decode('utf-8')
    
    def check_password(self, password):
        """Check if the provided password matches the hash."""
        return bcrypt.check_password_hash(self.password_hash, password)
    
    @property
    def full_name(self):
        """Return the user's full name."""
        if self.first_name and self.last_name:
            return f'{self.first_name} {self.last_name}'
        return self.username
    
    @property
    def is_employer(self):
        """Check if user is an employer."""
        return self.user_type == 'employer'
    
    @property
    def is_jobseeker(self):
        """Check if user is a job seeker."""
        return self.user_type == 'jobseeker'
