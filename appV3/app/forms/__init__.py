"""
WTForms form definitions.
"""
from .auth_forms import LoginForm, RegistrationForm, ChangePasswordForm
from .company_forms import CompanyProfileForm
from .job_forms import JobPostingForm
from .resume_forms import ResumeForm
from .admin_forms import (
    EducationLevelForm, ExperienceLevelForm, JobTypeForm,
    CountryForm, StateForm
)

__all__ = [
    'LoginForm',
    'RegistrationForm',
    'ChangePasswordForm',
    'CompanyProfileForm',
    'JobPostingForm',
    'ResumeForm',
    'EducationLevelForm',
    'ExperienceLevelForm',
    'JobTypeForm',
    'CountryForm',
    'StateForm',
]
