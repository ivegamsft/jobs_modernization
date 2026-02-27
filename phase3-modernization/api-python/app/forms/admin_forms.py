"""
Admin forms for reference data management.
"""
from flask_wtf import FlaskForm
from wtforms import StringField, SelectField
from wtforms.validators import DataRequired, Length


class EducationLevelForm(FlaskForm):
    """Education level form."""
    
    education_level_name = StringField('Education Level Name', validators=[
        DataRequired(message='Name is required'),
        Length(max=50)
    ])


class ExperienceLevelForm(FlaskForm):
    """Experience level form."""
    
    experience_level_name = StringField('Experience Level Name', validators=[
        DataRequired(message='Name is required'),
        Length(max=255)
    ])


class JobTypeForm(FlaskForm):
    """Job type form."""
    
    job_type_name = StringField('Job Type Name', validators=[
        DataRequired(message='Name is required'),
        Length(max=50)
    ])


class CountryForm(FlaskForm):
    """Country form."""
    
    country_name = StringField('Country Name', validators=[
        DataRequired(message='Name is required'),
        Length(max=255)
    ])


class StateForm(FlaskForm):
    """State form."""
    
    state_name = StringField('State Name', validators=[
        DataRequired(message='Name is required'),
        Length(max=255)
    ])
    country_id = SelectField('Country', coerce=int, validators=[
        DataRequired(message='Country is required')
    ])
