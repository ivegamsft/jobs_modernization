# AppV3 Environment Setup Guide

## ⚠️ Security Notice

This application requires environment variables for sensitive configuration. **Never commit `.env` files to version control**. The `.env` file is already listed in `.gitignore`.

## Quick Start

### Windows (PowerShell)

```powershell
# Run the interactive setup script
.\setup-environment.ps1
```

### Linux/macOS (Bash)

```bash
# Make script executable and run
chmod +x .env.setup.sh
./.env.setup.sh
```

### Manual Setup

1. Copy the example file:
   ```bash
   cp .env.example .env
   ```

2. Edit `.env` with your values:
   ```bash
   nano .env  # or use your preferred editor
   ```

## Required Environment Variables

### `SECRET_KEY`
- **Purpose**: Flask session encryption and CSRF protection
- **Requirements**: Strong random string (minimum 32 characters)
- **Generate**: 
  ```bash
  # Python
  python -c "import secrets; print(secrets.token_urlsafe(32))"
  
  # OpenSSL
  openssl rand -base64 32
  ```

### `DATABASE_URL`
- **Purpose**: SQLAlchemy database connection string
- **Format**: 
  - SQL Server: `mssql+pyodbc://user:pass@host:port/database?driver=ODBC+Driver+18+for+SQL+Server&TrustServerCertificate=yes`
  - PostgreSQL: `postgresql://user:pass@host:port/database`
  - SQLite: `sqlite:///relative/path/jobsite.db`
- **Example (Docker)**: 
  ```
  mssql+pyodbc://sa:YourPassword@sqlserver:1433/JobsDB?driver=ODBC+Driver+18+for+SQL+Server&TrustServerCertificate=yes
  ```

### `MSSQL_SA_PASSWORD` (if using SQL Server)
- **Purpose**: SQL Server system administrator password
- **Requirements**: 
  - Minimum 8 characters
  - Must contain uppercase, lowercase, number, and special character
- **Example**: `YourStr0ng@Passw0rd`

## Running with Docker Compose

```bash
# Start all services
docker-compose up -d

# Check SQL Server health (should show "healthy" after ~30 seconds)
docker-compose ps

# View logs
docker-compose logs -f sqlserver
docker-compose logs -f jobsite-web

# Test database connection
docker-compose exec sqlserver /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -C -Q "SELECT @@version"

# Stop all services
docker-compose down
```

## Running Locally (without Docker)

```bash
# Create virtual environment
python -m venv venv

# Activate it
# Windows:
venv\Scripts\activate
# Linux/macOS:
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Set environment (PowerShell example)
$env:SECRET_KEY = "your-generated-key"
$env:DATABASE_URL = "your-database-url"

# Run Flask app
flask run
```

## Troubleshooting

### Application won't start: "SECRET_KEY environment variable must be set"
- Ensure `.env` file exists in the `appV3` directory
- Verify `SECRET_KEY` is defined and not empty
- Run `docker-compose down` and `docker-compose up -d` to reload

### Database connection errors
- Check `DATABASE_URL` format matches your database type
- Verify SQL Server is healthy: `docker-compose ps`
- Check connection string credentials are correct
- For SQL Server in Docker, wait 30+ seconds for startup

### "MSSQL_SA_PASSWORD" validation error
- Password must be 8+ characters
- Must contain: uppercase, lowercase, number, and special character
- Example valid password: `JobSite@2024`

## Security Best Practices

✅ **DO:**
- Generate strong random `SECRET_KEY` using cryptographic tools
- Store real credentials in `.env` (which is `.gitignore`'d)
- Rotate `MSSQL_SA_PASSWORD` regularly in production
- Use different passwords for dev/staging/production
- Keep `.env` file permissions restrictive (mode 600)

❌ **DON'T:**
- Commit `.env` to version control
- Use same password across environments
- Share `.env` files in email or chat
- Hardcode secrets in code or config files
- Use simple/predictable passwords

## Environment File Structure

```dotenv
# Flask Application
FLASK_APP=run.py
FLASK_ENV=development
FLASK_DEBUG=1

# Security (REQUIRED)
SECRET_KEY=your-strong-random-key-here

# Database (REQUIRED)
DATABASE_URL=mssql+pyodbc://sa:password@host:port/database?driver=...

# SQL Server (REQUIRED if using SQL Server in Docker)
MSSQL_SA_PASSWORD=YourPassword@123

# Optional
APP_NAME=JobSite
ITEMS_PER_PAGE=10
```

## CI/CD Integration

For GitHub Actions and other CI/CD systems:

1. Add secrets via GitHub Settings → Secrets and variables → Actions
2. Use in workflows: `${{ secrets.SECRET_KEY }}`
3. Pass to environment:
   ```yaml
   env:
     SECRET_KEY: ${{ secrets.SECRET_KEY }}
     DATABASE_URL: ${{ secrets.DATABASE_URL }}
   ```

## Additional Resources

- [Flask Configuration](https://flask.palletsprojects.com/config/)
- [SQLAlchemy Connection Strings](https://docs.sqlalchemy.org/core/engines.html)
- [Python-dotenv Documentation](https://python-dotenv.readthedocs.io/)
