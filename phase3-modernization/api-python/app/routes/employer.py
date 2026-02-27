"""
Employer routes (company profile, job postings, resume search).
"""
from flask import Blueprint, render_template, redirect, url_for, flash, request
from flask_login import login_required, current_user
from functools import wraps
from ..extensions import db
from ..models import Company, JobPosting, Resume, MyResume, Country, State
from ..models import EducationLevel, JobType
from ..forms.company_forms import CompanyProfileForm
from ..forms.job_forms import JobPostingForm

employer_bp = Blueprint('employer', __name__)


def employer_required(f):
    """Decorator to require employer user type."""
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if not current_user.is_authenticated:
            return redirect(url_for('auth.login'))
        if not current_user.is_employer:
            flash('Access denied. This area is for employers only.', 'danger')
            return redirect(url_for('main.index'))
        return f(*args, **kwargs)
    return decorated_function


@employer_bp.route('/dashboard')
@login_required
@employer_required
def dashboard():
    """Employer dashboard."""
    company = Company.query.filter_by(user_id=current_user.id).first()
    job_count = 0
    recent_jobs = []
    
    if company:
        job_count = JobPosting.query.filter_by(company_id=company.id).count()
        recent_jobs = JobPosting.query.filter_by(company_id=company.id)\
            .order_by(JobPosting.posted_date.desc())\
            .limit(5)\
            .all()
    
    return render_template('employer/dashboard.html',
                          company=company,
                          job_count=job_count,
                          recent_jobs=recent_jobs)


@employer_bp.route('/company-profile', methods=['GET', 'POST'])
@login_required
@employer_required
def company_profile():
    """Company profile management."""
    company = Company.query.filter_by(user_id=current_user.id).first()
    form = CompanyProfileForm(obj=company)
    
    # Populate dropdown choices
    form.country_id.choices = [(0, 'Select Country')] + [
        (c.id, c.country_name) for c in Country.query.order_by(Country.country_name).all()
    ]
    form.state_id.choices = [(0, 'Select State')] + [
        (s.id, s.state_name) for s in State.query.order_by(State.state_name).all()
    ]
    
    if form.validate_on_submit():
        if company is None:
            company = Company(user_id=current_user.id)
            db.session.add(company)
        
        form.populate_obj(company)
        db.session.commit()
        
        flash('Company profile updated successfully.', 'success')
        return redirect(url_for('employer.dashboard'))
    
    return render_template('employer/company_profile.html', form=form, company=company)


@employer_bp.route('/job-postings')
@login_required
@employer_required
def job_postings():
    """List all job postings for the employer."""
    company = Company.query.filter_by(user_id=current_user.id).first()
    if not company:
        flash('Please complete your company profile first.', 'warning')
        return redirect(url_for('employer.company_profile'))
    
    page = request.args.get('page', 1, type=int)
    jobs = JobPosting.query.filter_by(company_id=company.id)\
        .order_by(JobPosting.posted_date.desc())\
        .paginate(page=page, per_page=10)
    
    return render_template('employer/job_postings.html', jobs=jobs)


@employer_bp.route('/job-postings/new', methods=['GET', 'POST'])
@login_required
@employer_required
def create_job_posting():
    """Create a new job posting."""
    company = Company.query.filter_by(user_id=current_user.id).first()
    if not company:
        flash('Please complete your company profile first.', 'warning')
        return redirect(url_for('employer.company_profile'))
    
    form = JobPostingForm()
    _populate_job_form_choices(form)
    
    if form.validate_on_submit():
        job = JobPosting(
            company_id=company.id,
            posted_by=current_user.username
        )
        form.populate_obj(job)
        
        db.session.add(job)
        db.session.commit()
        
        flash('Job posting created successfully.', 'success')
        return redirect(url_for('employer.job_postings'))
    
    return render_template('employer/job_form.html', form=form, is_new=True)


@employer_bp.route('/job-postings/<int:id>/edit', methods=['GET', 'POST'])
@login_required
@employer_required
def edit_job_posting(id):
    """Edit an existing job posting."""
    company = Company.query.filter_by(user_id=current_user.id).first()
    job = JobPosting.query.filter_by(id=id, company_id=company.id).first_or_404()
    
    form = JobPostingForm(obj=job)
    _populate_job_form_choices(form)
    
    if form.validate_on_submit():
        form.populate_obj(job)
        db.session.commit()
        
        flash('Job posting updated successfully.', 'success')
        return redirect(url_for('employer.job_postings'))
    
    return render_template('employer/job_form.html', form=form, job=job, is_new=False)


@employer_bp.route('/job-postings/<int:id>/delete', methods=['POST'])
@login_required
@employer_required
def delete_job_posting(id):
    """Delete a job posting."""
    company = Company.query.filter_by(user_id=current_user.id).first()
    job = JobPosting.query.filter_by(id=id, company_id=company.id).first_or_404()
    
    db.session.delete(job)
    db.session.commit()
    
    flash('Job posting deleted successfully.', 'success')
    return redirect(url_for('employer.job_postings'))


@employer_bp.route('/resume-search')
@login_required
@employer_required
def resume_search():
    """Search resumes."""
    page = request.args.get('page', 1, type=int)
    keyword = request.args.get('keyword', '')
    city = request.args.get('city', '')
    
    query = Resume.query.filter_by(is_searchable=True)
    
    if keyword:
        query = query.filter(
            Resume.job_title.ilike(f'%{keyword}%') |
            Resume.resume_text.ilike(f'%{keyword}%')
        )
    
    if city:
        query = query.filter(Resume.target_city.ilike(f'%{city}%'))
    
    resumes = query.order_by(Resume.post_date.desc())\
        .paginate(page=page, per_page=10)
    
    return render_template('employer/resume_search.html',
                          resumes=resumes,
                          keyword=keyword,
                          city=city)


@employer_bp.route('/resume/<int:id>')
@login_required
@employer_required
def view_resume(id):
    """View a resume."""
    resume = Resume.query.filter_by(id=id, is_searchable=True).first_or_404()
    return render_template('employer/view_resume.html', resume=resume)


@employer_bp.route('/favorites')
@login_required
@employer_required
def favorites():
    """View favorite resumes."""
    page = request.args.get('page', 1, type=int)
    my_resumes = MyResume.query.filter_by(user_id=current_user.id)\
        .order_by(MyResume.created_at.desc())\
        .paginate(page=page, per_page=10)
    
    return render_template('employer/favorites.html', my_resumes=my_resumes)


@employer_bp.route('/favorites/add/<int:resume_id>', methods=['POST'])
@login_required
@employer_required
def add_favorite_resume(resume_id):
    """Add a resume to favorites."""
    existing = MyResume.query.filter_by(
        user_id=current_user.id,
        resume_id=resume_id
    ).first()
    
    if not existing:
        my_resume = MyResume(user_id=current_user.id, resume_id=resume_id)
        db.session.add(my_resume)
        db.session.commit()
        flash('Resume added to favorites.', 'success')
    else:
        flash('Resume is already in your favorites.', 'info')
    
    return redirect(url_for('employer.view_resume', id=resume_id))


@employer_bp.route('/favorites/remove/<int:id>', methods=['POST'])
@login_required
@employer_required
def remove_favorite_resume(id):
    """Remove a resume from favorites."""
    my_resume = MyResume.query.filter_by(
        id=id,
        user_id=current_user.id
    ).first_or_404()
    
    db.session.delete(my_resume)
    db.session.commit()
    
    flash('Resume removed from favorites.', 'success')
    return redirect(url_for('employer.favorites'))


def _populate_job_form_choices(form):
    """Populate dropdown choices for job form."""
    form.country_id.choices = [(0, 'Select Country')] + [
        (c.id, c.country_name) for c in Country.query.order_by(Country.country_name).all()
    ]
    form.state_id.choices = [(0, 'Select State')] + [
        (s.id, s.state_name) for s in State.query.order_by(State.state_name).all()
    ]
    form.education_level_id.choices = [(0, 'Any Education Level')] + [
        (e.id, e.education_level_name) for e in EducationLevel.query.all()
    ]
    form.job_type_id.choices = [(0, 'Select Job Type')] + [
        (j.id, j.job_type_name) for j in JobType.query.all()
    ]
