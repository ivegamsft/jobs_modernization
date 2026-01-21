"""
Job seeker routes (job search, resume management, favorites).
"""
from flask import Blueprint, render_template, redirect, url_for, flash, request
from flask_login import login_required, current_user
from functools import wraps
from ..extensions import db
from ..models import JobPosting, Resume, MyJob, Company, Country, State
from ..models import EducationLevel, ExperienceLevel, JobType
from ..forms.resume_forms import ResumeForm

jobseeker_bp = Blueprint('jobseeker', __name__)


def jobseeker_required(f):
    """Decorator to require job seeker user type."""
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if not current_user.is_authenticated:
            return redirect(url_for('auth.login'))
        if not current_user.is_jobseeker:
            flash('Access denied. This area is for job seekers only.', 'danger')
            return redirect(url_for('main.index'))
        return f(*args, **kwargs)
    return decorated_function


@jobseeker_bp.route('/dashboard')
@login_required
@jobseeker_required
def dashboard():
    """Job seeker dashboard."""
    resume = Resume.query.filter_by(user_id=current_user.id).first()
    saved_jobs_count = MyJob.query.filter_by(user_id=current_user.id).count()
    
    # Get recommended jobs based on resume
    recommended_jobs = []
    if resume:
        query = JobPosting.query.filter_by(is_active=True)
        if resume.target_city:
            query = query.filter(JobPosting.city.ilike(f'%{resume.target_city}%'))
        recommended_jobs = query.order_by(JobPosting.posted_date.desc()).limit(5).all()
    else:
        recommended_jobs = JobPosting.query.filter_by(is_active=True)\
            .order_by(JobPosting.posted_date.desc())\
            .limit(5)\
            .all()
    
    return render_template('jobseeker/dashboard.html',
                          resume=resume,
                          saved_jobs_count=saved_jobs_count,
                          recommended_jobs=recommended_jobs)


@jobseeker_bp.route('/job-search')
@login_required
@jobseeker_required
def job_search():
    """Search for jobs."""
    page = request.args.get('page', 1, type=int)
    keyword = request.args.get('keyword', '')
    city = request.args.get('city', '')
    job_type_id = request.args.get('job_type_id', 0, type=int)
    
    query = JobPosting.query.filter_by(is_active=True)
    
    if keyword:
        query = query.filter(
            JobPosting.title.ilike(f'%{keyword}%') |
            JobPosting.description.ilike(f'%{keyword}%')
        )
    
    if city:
        query = query.filter(JobPosting.city.ilike(f'%{city}%'))
    
    if job_type_id > 0:
        query = query.filter(JobPosting.job_type_id == job_type_id)
    
    jobs = query.order_by(JobPosting.posted_date.desc())\
        .paginate(page=page, per_page=10)
    
    job_types = JobType.query.all()
    
    return render_template('jobseeker/job_search.html',
                          jobs=jobs,
                          keyword=keyword,
                          city=city,
                          job_type_id=job_type_id,
                          job_types=job_types)


@jobseeker_bp.route('/job/<int:id>')
@login_required
@jobseeker_required
def view_job(id):
    """View a job posting."""
    job = JobPosting.query.filter_by(id=id, is_active=True).first_or_404()
    
    # Check if job is already saved
    is_saved = MyJob.query.filter_by(
        user_id=current_user.id,
        job_posting_id=id
    ).first() is not None
    
    return render_template('jobseeker/view_job.html', job=job, is_saved=is_saved)


@jobseeker_bp.route('/company/<int:id>')
@login_required
@jobseeker_required
def view_company(id):
    """View company profile."""
    company = Company.query.get_or_404(id)
    
    # Get active job postings for this company
    jobs = JobPosting.query.filter_by(company_id=id, is_active=True)\
        .order_by(JobPosting.posted_date.desc())\
        .all()
    
    return render_template('jobseeker/view_company.html', company=company, jobs=jobs)


@jobseeker_bp.route('/resume', methods=['GET', 'POST'])
@login_required
@jobseeker_required
def resume():
    """Manage resume."""
    resume = Resume.query.filter_by(user_id=current_user.id).first()
    form = ResumeForm(obj=resume)
    
    # Populate dropdown choices
    _populate_resume_form_choices(form)
    
    if form.validate_on_submit():
        if resume is None:
            resume = Resume(user_id=current_user.id)
            db.session.add(resume)
        
        form.populate_obj(resume)
        db.session.commit()
        
        flash('Resume updated successfully.', 'success')
        return redirect(url_for('jobseeker.dashboard'))
    
    return render_template('jobseeker/resume.html', form=form, resume=resume)


@jobseeker_bp.route('/favorites')
@login_required
@jobseeker_required
def favorites():
    """View favorite/saved jobs."""
    page = request.args.get('page', 1, type=int)
    my_jobs = MyJob.query.filter_by(user_id=current_user.id)\
        .order_by(MyJob.created_at.desc())\
        .paginate(page=page, per_page=10)
    
    return render_template('jobseeker/favorites.html', my_jobs=my_jobs)


@jobseeker_bp.route('/favorites/add/<int:job_id>', methods=['POST'])
@login_required
@jobseeker_required
def add_favorite_job(job_id):
    """Add a job to favorites."""
    existing = MyJob.query.filter_by(
        user_id=current_user.id,
        job_posting_id=job_id
    ).first()
    
    if not existing:
        my_job = MyJob(user_id=current_user.id, job_posting_id=job_id)
        db.session.add(my_job)
        db.session.commit()
        flash('Job added to favorites.', 'success')
    else:
        flash('Job is already in your favorites.', 'info')
    
    return redirect(url_for('jobseeker.view_job', id=job_id))


@jobseeker_bp.route('/favorites/remove/<int:id>', methods=['POST'])
@login_required
@jobseeker_required
def remove_favorite_job(id):
    """Remove a job from favorites."""
    my_job = MyJob.query.filter_by(
        id=id,
        user_id=current_user.id
    ).first_or_404()
    
    db.session.delete(my_job)
    db.session.commit()
    
    flash('Job removed from favorites.', 'success')
    return redirect(url_for('jobseeker.favorites'))


def _populate_resume_form_choices(form):
    """Populate dropdown choices for resume form."""
    form.target_country_id.choices = [(0, 'Select Country')] + [
        (c.id, c.country_name) for c in Country.query.order_by(Country.country_name).all()
    ]
    form.target_state_id.choices = [(0, 'Select State')] + [
        (s.id, s.state_name) for s in State.query.order_by(State.state_name).all()
    ]
    form.relocation_country_id.choices = [(0, 'No Preference')] + [
        (c.id, c.country_name) for c in Country.query.order_by(Country.country_name).all()
    ]
    form.education_level_id.choices = [(0, 'Select Education Level')] + [
        (e.id, e.education_level_name) for e in EducationLevel.query.all()
    ]
    form.experience_level_id.choices = [(0, 'Select Experience Level')] + [
        (e.id, e.experience_level_name) for e in ExperienceLevel.query.all()
    ]
    form.target_job_type_id.choices = [(0, 'Any Job Type')] + [
        (j.id, j.job_type_name) for j in JobType.query.all()
    ]
