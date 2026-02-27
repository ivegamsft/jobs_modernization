"""
Job posting forms.
"""
from flask_wtf import FlaskForm
from wtforms import StringField, TextAreaField, SelectField, DecimalField, BooleanField
from wtforms.validators import DataRequired, Length, Optional, NumberRange


class JobPostingForm(FlaskForm):
    """Job posting form."""
    
    title = StringField('Job Title', validators=[
        DataRequired(message='Job title is required'),
        Length(max=255)
    ])
    description = TextAreaField('Job Description', validators=[
        DataRequired(message='Job description is required')
    ])
    department = StringField('Department', validators=[
        Optional(),
        Length(max=50)
    ])
    job_code = StringField('Job Code', validators=[
        Optional(),
        Length(max=50)
    ])
    contact_person = StringField('Contact Person', validators=[
        Optional(),
        Length(max=255)
    ])
    city = StringField('City', validators=[
        Optional(),
        Length(max=50)
    ])
    state_id = SelectField('State', coerce=int, validators=[Optional()])
    country_id = SelectField('Country', coerce=int, validators=[Optional()])
    education_level_id = SelectField('Education Level', coerce=int, validators=[Optional()])
    job_type_id = SelectField('Job Type', coerce=int, validators=[Optional()])
    min_salary = DecimalField('Minimum Salary', validators=[
        Optional(),
        NumberRange(min=0, message='Salary must be positive')
    ], places=2)
    max_salary = DecimalField('Maximum Salary', validators=[
        Optional(),
        NumberRange(min=0, message='Salary must be positive')
    ], places=2)
    is_active = BooleanField('Active', default=True)
