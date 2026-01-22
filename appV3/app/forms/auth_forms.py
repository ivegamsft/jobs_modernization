"""
Authentication forms.
"""
from flask_wtf import FlaskForm
from wtforms import StringField, PasswordField, BooleanField, SelectField
from wtforms.validators import DataRequired, Email, Length, EqualTo, ValidationError


class LoginForm(FlaskForm):
    """User login form."""
    
    username = StringField('Username', validators=[
        DataRequired(message='Username is required'),
        Length(min=3, max=50)
    ])
    password = PasswordField('Password', validators=[
        DataRequired(message='Password is required')
    ])
    remember_me = BooleanField('Remember Me')


class RegistrationForm(FlaskForm):
    """User registration form."""
    
    username = StringField('Username', validators=[
        DataRequired(message='Username is required'),
        Length(min=3, max=50, message='Username must be between 3 and 50 characters')
    ])
    email = StringField('Email', validators=[
        DataRequired(message='Email is required'),
        Email(message='Please enter a valid email address'),
        Length(max=255)
    ])
    first_name = StringField('First Name', validators=[
        DataRequired(message='First name is required'),
        Length(max=100)
    ])
    last_name = StringField('Last Name', validators=[
        DataRequired(message='Last name is required'),
        Length(max=100)
    ])
    user_type = SelectField('I am a', choices=[
        ('jobseeker', 'Job Seeker'),
        ('employer', 'Employer')
    ], validators=[DataRequired()])
    password = PasswordField('Password', validators=[
        DataRequired(message='Password is required'),
        Length(min=8, message='Password must be at least 8 characters')
    ])
    confirm_password = PasswordField('Confirm Password', validators=[
        DataRequired(message='Please confirm your password'),
        EqualTo('password', message='Passwords must match')
    ])


class ChangePasswordForm(FlaskForm):
    """Change password form."""
    
    current_password = PasswordField('Current Password', validators=[
        DataRequired(message='Current password is required')
    ])
    new_password = PasswordField('New Password', validators=[
        DataRequired(message='New password is required'),
        Length(min=8, message='Password must be at least 8 characters')
    ])
    confirm_password = PasswordField('Confirm New Password', validators=[
        DataRequired(message='Please confirm your new password'),
        EqualTo('new_password', message='Passwords must match')
    ])
