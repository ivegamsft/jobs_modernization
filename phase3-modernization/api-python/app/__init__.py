"""
Flask application factory.
"""
from flask import Flask
from .config import get_config
from .extensions import db, migrate, login_manager, bcrypt, csrf


def create_app(config_class=None):
    """
    Application factory for creating Flask application instances.
    
    Args:
        config_class: Configuration class to use. Defaults to environment-based config.
    
    Returns:
        Flask application instance.
    """
    app = Flask(__name__)
    
    # Load configuration
    if config_class is None:
        config_class = get_config()
    app.config.from_object(config_class)
    
    # Initialize extensions
    db.init_app(app)
    migrate.init_app(app, db)
    login_manager.init_app(app)
    bcrypt.init_app(app)
    csrf.init_app(app)
    
    # Import models for migrations
    from .models import User, Company, JobPosting, Resume, Country, State
    from .models import EducationLevel, ExperienceLevel, JobType
    from .models import MyJob, MyResume, MySearch
    
    # User loader for Flask-Login
    @login_manager.user_loader
    def load_user(user_id):
        return User.query.get(int(user_id))
    
    # Register blueprints
    from .routes.main import main_bp
    from .routes.auth import auth_bp
    from .routes.employer import employer_bp
    from .routes.jobseeker import jobseeker_bp
    from .routes.admin import admin_bp
    
    app.register_blueprint(main_bp)
    app.register_blueprint(auth_bp, url_prefix='/auth')
    app.register_blueprint(employer_bp, url_prefix='/employer')
    app.register_blueprint(jobseeker_bp, url_prefix='/jobseeker')
    app.register_blueprint(admin_bp, url_prefix='/admin')
    
    # Create database tables (with error handling for missing DB connection)
    with app.app_context():
        try:
            db.create_all()
        except Exception as e:
            app.logger.warning(f"Could not create database tables: {e}")
            app.logger.warning("Database may not be available. Some features may not work.")
    
    # Register error handlers
    register_error_handlers(app)
    
    # Register template context processors
    register_context_processors(app)
    
    return app


def register_error_handlers(app):
    """Register custom error handlers."""
    
    @app.errorhandler(404)
    def not_found_error(error):
        from flask import render_template
        return render_template('errors/404.html'), 404
    
    @app.errorhandler(500)
    def internal_error(error):
        from flask import render_template
        db.session.rollback()
        return render_template('errors/500.html'), 500
    
    @app.errorhandler(403)
    def forbidden_error(error):
        from flask import render_template
        return render_template('errors/403.html'), 403


def register_context_processors(app):
    """Register template context processors."""
    
    @app.context_processor
    def inject_app_name():
        return {'app_name': app.config.get('APP_NAME', 'JobSite')}
