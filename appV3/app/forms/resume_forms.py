"""
Resume forms.
"""
from flask_wtf import FlaskForm
from wtforms import StringField, TextAreaField, SelectField, BooleanField
from wtforms.validators import DataRequired, Length, Optional


class ResumeForm(FlaskForm):
    """Resume form."""
    
    job_title = StringField('Desired Job Title', validators=[
        DataRequired(message='Job title is required'),
        Length(max=255)
    ])
    resume_text = TextAreaField('Resume/CV', validators=[
        Optional()
    ])
    cover_letter_text = TextAreaField('Cover Letter', validators=[
        Optional()
    ])
    target_city = StringField('Target City', validators=[
        Optional(),
        Length(max=50)
    ])
    target_state_id = SelectField('Target State', coerce=int, validators=[Optional()])
    target_country_id = SelectField('Target Country', coerce=int, validators=[Optional()])
    relocation_country_id = SelectField('Willing to Relocate To', coerce=int, validators=[Optional()])
    target_job_type_id = SelectField('Preferred Job Type', coerce=int, validators=[Optional()])
    education_level_id = SelectField('Education Level', coerce=int, validators=[Optional()])
    experience_level_id = SelectField('Experience Level', coerce=int, validators=[Optional()])
    is_searchable = BooleanField('Make my resume searchable by employers', default=True)
