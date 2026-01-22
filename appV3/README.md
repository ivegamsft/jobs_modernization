# JobSite V3 - Python Flask with PostgreSQL

This folder contains the Python Flask version of the Job Site application, migrated from the ASP.NET Core appV2 to Python Flask with PostgreSQL database.

## Technology Stack

- **Backend Framework**: Python Flask 3.x
- **Database**: PostgreSQL 15+
- **ORM**: SQLAlchemy with Flask-SQLAlchemy
- **Authentication**: Flask-Login with Flask-Bcrypt
- **Forms**: Flask-WTF with WTForms
- **Migrations**: Flask-Migrate (Alembic)
- **Template Engine**: Jinja2
- **CSS Framework**: Bootstrap 5

## Project Structure

```
appV3/
├── app/
│   ├── __init__.py           # Flask application factory
│   ├── config.py             # Configuration settings
│   ├── extensions.py         # Flask extensions initialization
│   ├── models/               # SQLAlchemy models
│   │   ├── __init__.py
│   │   ├── user.py
│   │   ├── company.py
│   │   ├── job_posting.py
│   │   ├── resume.py
│   │   └── ...
│   ├── routes/               # Flask blueprints/routes
│   │   ├── __init__.py
│   │   ├── auth.py
│   │   ├── main.py
│   │   ├── employer.py
│   │   ├── jobseeker.py
│   │   └── admin.py
│   ├── services/             # Business logic layer
│   │   ├── __init__.py
│   │   ├── auth_service.py
│   │   ├── company_service.py
│   │   ├── job_service.py
│   │   └── resume_service.py
│   ├── forms/                # WTForms form definitions
│   │   ├── __init__.py
│   │   ├── auth_forms.py
│   │   ├── company_forms.py
│   │   ├── job_forms.py
│   │   └── resume_forms.py
│   ├── templates/            # Jinja2 templates
│   │   ├── base.html
│   │   ├── auth/
│   │   ├── employer/
│   │   ├── jobseeker/
│   │   └── admin/
│   └── static/               # Static assets (CSS, JS, images)
│       ├── css/
│       ├── js/
│       └── images/
├── migrations/               # Database migrations (Flask-Migrate)
├── tests/                    # Unit and integration tests
│   ├── __init__.py
│   ├── conftest.py
│   ├── test_auth.py
│   ├── test_jobs.py
│   └── test_resumes.py
├── scripts/                  # Utility scripts
│   └── seed_data.py
├── .env.example              # Environment variables template
├── .gitignore
├── docker-compose.yml        # Docker configuration
├── Dockerfile
├── requirements.txt          # Python dependencies
├── requirements-dev.txt      # Development dependencies
└── run.py                    # Application entry point
```

## Quick Start

### Prerequisites

- Python 3.11+
- PostgreSQL 15+
- Docker & Docker Compose (optional)

### Option 1: Using Docker (Recommended)

```bash
# Clone and navigate to appV3
cd appV3

# Start all services
docker-compose up -d

# The application will be available at http://localhost:5000
```

### Option 2: Local Development

```bash
# Create virtual environment
python -m venv venv

# Activate virtual environment
# On Windows:
.\venv\Scripts\activate
# On Linux/Mac:
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Set up environment variables
cp .env.example .env
# Edit .env with your PostgreSQL connection details

# Initialize database
flask db upgrade

# Seed initial data
python scripts/seed_data.py

# Run the application
flask run
```

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `FLASK_APP` | Flask application module | `run.py` |
| `FLASK_ENV` | Environment (development/production) | `development` |
| `SECRET_KEY` | Secret key for session encryption | - |
| `DATABASE_URL` | PostgreSQL connection string | `postgresql://user:pass@localhost:5432/jobsite` |

## API Endpoints

### Authentication
- `GET/POST /auth/login` - User login
- `GET/POST /auth/register` - User registration
- `GET /auth/logout` - User logout
- `GET/POST /auth/change-password` - Change password

### Employer Routes
- `GET /employer/dashboard` - Employer dashboard
- `GET/POST /employer/company-profile` - Company profile management
- `GET /employer/job-postings` - List job postings
- `GET/POST /employer/job-postings/new` - Create job posting
- `GET/POST /employer/job-postings/<id>/edit` - Edit job posting
- `DELETE /employer/job-postings/<id>` - Delete job posting
- `GET /employer/resume-search` - Search resumes
- `GET /employer/favorites` - Favorite resumes

### Job Seeker Routes
- `GET /jobseeker/dashboard` - Job seeker dashboard
- `GET /jobseeker/job-search` - Search jobs
- `GET /jobseeker/job/<id>` - View job posting
- `GET/POST /jobseeker/resume` - Manage resume
- `GET /jobseeker/favorites` - Favorite jobs

### Admin Routes
- `GET /admin/education-levels` - Manage education levels
- `GET /admin/experience-levels` - Manage experience levels
- `GET /admin/job-types` - Manage job types

## Database Schema

The PostgreSQL database includes the following tables:
- `users` - User accounts with authentication
- `companies` - Employer company profiles
- `job_postings` - Job listings
- `resumes` - Job seeker resumes
- `countries` - Country reference data
- `states` - State/province reference data
- `education_levels` - Education level options
- `experience_levels` - Experience level options
- `job_types` - Job type options (Full-time, Part-time, etc.)
- `my_jobs` - Saved/favorite jobs for job seekers
- `my_resumes` - Saved/favorite resumes for employers
- `my_searches` - Saved search criteria

## Migration from appV2

This application is a Python Flask port of the ASP.NET Core appV2 application with the following changes:
- ASP.NET Core → Python Flask
- Entity Framework Core → SQLAlchemy
- SQL Server → PostgreSQL
- Razor Views → Jinja2 Templates
- ASP.NET Identity → Flask-Login

## License

MIT License
