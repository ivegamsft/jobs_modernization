"""
Admin routes (manage reference data).
"""
from flask import Blueprint, render_template, redirect, url_for, flash, request
from flask_login import login_required, current_user
from functools import wraps
from ..extensions import db
from ..models import EducationLevel, ExperienceLevel, JobType, Country, State
from ..forms.admin_forms import (
    EducationLevelForm, ExperienceLevelForm, JobTypeForm,
    CountryForm, StateForm
)

admin_bp = Blueprint('admin', __name__)


def admin_required(f):
    """Decorator to require admin user."""
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if not current_user.is_authenticated:
            return redirect(url_for('auth.login'))
        if not current_user.is_admin:
            flash('Access denied. Admin privileges required.', 'danger')
            return redirect(url_for('main.index'))
        return f(*args, **kwargs)
    return decorated_function


@admin_bp.route('/')
@login_required
@admin_required
def dashboard():
    """Admin dashboard."""
    stats = {
        'countries': Country.query.count(),
        'states': State.query.count(),
        'education_levels': EducationLevel.query.count(),
        'experience_levels': ExperienceLevel.query.count(),
        'job_types': JobType.query.count(),
    }
    return render_template('admin/dashboard.html', stats=stats)


# Education Levels
@admin_bp.route('/education-levels')
@login_required
@admin_required
def education_levels():
    """List education levels."""
    levels = EducationLevel.query.all()
    return render_template('admin/education_levels.html', levels=levels)


@admin_bp.route('/education-levels/new', methods=['GET', 'POST'])
@login_required
@admin_required
def create_education_level():
    """Create new education level."""
    form = EducationLevelForm()
    if form.validate_on_submit():
        level = EducationLevel(education_level_name=form.education_level_name.data)
        db.session.add(level)
        db.session.commit()
        flash('Education level created successfully.', 'success')
        return redirect(url_for('admin.education_levels'))
    return render_template('admin/education_level_form.html', form=form, is_new=True)


@admin_bp.route('/education-levels/<int:id>/edit', methods=['GET', 'POST'])
@login_required
@admin_required
def edit_education_level(id):
    """Edit education level."""
    level = EducationLevel.query.get_or_404(id)
    form = EducationLevelForm(obj=level)
    if form.validate_on_submit():
        level.education_level_name = form.education_level_name.data
        db.session.commit()
        flash('Education level updated successfully.', 'success')
        return redirect(url_for('admin.education_levels'))
    return render_template('admin/education_level_form.html', form=form, level=level, is_new=False)


@admin_bp.route('/education-levels/<int:id>/delete', methods=['POST'])
@login_required
@admin_required
def delete_education_level(id):
    """Delete education level."""
    level = EducationLevel.query.get_or_404(id)
    db.session.delete(level)
    db.session.commit()
    flash('Education level deleted successfully.', 'success')
    return redirect(url_for('admin.education_levels'))


# Experience Levels
@admin_bp.route('/experience-levels')
@login_required
@admin_required
def experience_levels():
    """List experience levels."""
    levels = ExperienceLevel.query.all()
    return render_template('admin/experience_levels.html', levels=levels)


@admin_bp.route('/experience-levels/new', methods=['GET', 'POST'])
@login_required
@admin_required
def create_experience_level():
    """Create new experience level."""
    form = ExperienceLevelForm()
    if form.validate_on_submit():
        level = ExperienceLevel(experience_level_name=form.experience_level_name.data)
        db.session.add(level)
        db.session.commit()
        flash('Experience level created successfully.', 'success')
        return redirect(url_for('admin.experience_levels'))
    return render_template('admin/experience_level_form.html', form=form, is_new=True)


@admin_bp.route('/experience-levels/<int:id>/edit', methods=['GET', 'POST'])
@login_required
@admin_required
def edit_experience_level(id):
    """Edit experience level."""
    level = ExperienceLevel.query.get_or_404(id)
    form = ExperienceLevelForm(obj=level)
    if form.validate_on_submit():
        level.experience_level_name = form.experience_level_name.data
        db.session.commit()
        flash('Experience level updated successfully.', 'success')
        return redirect(url_for('admin.experience_levels'))
    return render_template('admin/experience_level_form.html', form=form, level=level, is_new=False)


@admin_bp.route('/experience-levels/<int:id>/delete', methods=['POST'])
@login_required
@admin_required
def delete_experience_level(id):
    """Delete experience level."""
    level = ExperienceLevel.query.get_or_404(id)
    db.session.delete(level)
    db.session.commit()
    flash('Experience level deleted successfully.', 'success')
    return redirect(url_for('admin.experience_levels'))


# Job Types
@admin_bp.route('/job-types')
@login_required
@admin_required
def job_types():
    """List job types."""
    types = JobType.query.all()
    return render_template('admin/job_types.html', types=types)


@admin_bp.route('/job-types/new', methods=['GET', 'POST'])
@login_required
@admin_required
def create_job_type():
    """Create new job type."""
    form = JobTypeForm()
    if form.validate_on_submit():
        job_type = JobType(job_type_name=form.job_type_name.data)
        db.session.add(job_type)
        db.session.commit()
        flash('Job type created successfully.', 'success')
        return redirect(url_for('admin.job_types'))
    return render_template('admin/job_type_form.html', form=form, is_new=True)


@admin_bp.route('/job-types/<int:id>/edit', methods=['GET', 'POST'])
@login_required
@admin_required
def edit_job_type(id):
    """Edit job type."""
    job_type = JobType.query.get_or_404(id)
    form = JobTypeForm(obj=job_type)
    if form.validate_on_submit():
        job_type.job_type_name = form.job_type_name.data
        db.session.commit()
        flash('Job type updated successfully.', 'success')
        return redirect(url_for('admin.job_types'))
    return render_template('admin/job_type_form.html', form=form, job_type=job_type, is_new=False)


@admin_bp.route('/job-types/<int:id>/delete', methods=['POST'])
@login_required
@admin_required
def delete_job_type(id):
    """Delete job type."""
    job_type = JobType.query.get_or_404(id)
    db.session.delete(job_type)
    db.session.commit()
    flash('Job type deleted successfully.', 'success')
    return redirect(url_for('admin.job_types'))


# Countries
@admin_bp.route('/countries')
@login_required
@admin_required
def countries():
    """List countries."""
    all_countries = Country.query.order_by(Country.country_name).all()
    return render_template('admin/countries.html', countries=all_countries)


@admin_bp.route('/countries/new', methods=['GET', 'POST'])
@login_required
@admin_required
def create_country():
    """Create new country."""
    form = CountryForm()
    if form.validate_on_submit():
        country = Country(country_name=form.country_name.data)
        db.session.add(country)
        db.session.commit()
        flash('Country created successfully.', 'success')
        return redirect(url_for('admin.countries'))
    return render_template('admin/country_form.html', form=form, is_new=True)


# States
@admin_bp.route('/states')
@login_required
@admin_required
def states():
    """List states."""
    all_states = State.query.join(Country).order_by(Country.country_name, State.state_name).all()
    return render_template('admin/states.html', states=all_states)


@admin_bp.route('/states/new', methods=['GET', 'POST'])
@login_required
@admin_required
def create_state():
    """Create new state."""
    form = StateForm()
    form.country_id.choices = [(c.id, c.country_name) for c in Country.query.order_by(Country.country_name).all()]
    
    if form.validate_on_submit():
        state = State(
            state_name=form.state_name.data,
            country_id=form.country_id.data
        )
        db.session.add(state)
        db.session.commit()
        flash('State created successfully.', 'success')
        return redirect(url_for('admin.states'))
    return render_template('admin/state_form.html', form=form, is_new=True)
