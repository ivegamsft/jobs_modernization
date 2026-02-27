"""
Company profile forms.
"""
from flask_wtf import FlaskForm
from wtforms import StringField, TextAreaField, SelectField
from wtforms.validators import DataRequired, Email, Length, URL, Optional


class CompanyProfileForm(FlaskForm):
    """Company profile form."""
    
    company_name = StringField('Company Name', validators=[
        DataRequired(message='Company name is required'),
        Length(max=255)
    ])
    company_profile = TextAreaField('Company Profile', validators=[
        Optional(),
        Length(max=5000)
    ])
    address1 = StringField('Address Line 1', validators=[
        Optional(),
        Length(max=255)
    ])
    address2 = StringField('Address Line 2', validators=[
        Optional(),
        Length(max=255)
    ])
    city = StringField('City', validators=[
        Optional(),
        Length(max=50)
    ])
    state_id = SelectField('State', coerce=int, validators=[Optional()])
    country_id = SelectField('Country', coerce=int, validators=[Optional()])
    postal_code = StringField('Postal Code', validators=[
        Optional(),
        Length(max=50)
    ])
    phone = StringField('Phone', validators=[
        Optional(),
        Length(max=50)
    ])
    fax = StringField('Fax', validators=[
        Optional(),
        Length(max=50)
    ])
    email = StringField('Email', validators=[
        Optional(),
        Email(message='Please enter a valid email address'),
        Length(max=255)
    ])
    website_url = StringField('Website URL', validators=[
        Optional(),
        Length(max=255)
    ])
