#!/bin/bash
# Environment Setup Helper for JobSite AppV3
# This script helps configure required environment variables securely

set -e

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║     JobSite AppV3 Environment Configuration Helper              ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# Check if .env already exists
if [ -f .env ]; then
    echo "⚠️  .env file already exists. Backing up to .env.backup"
    cp .env .env.backup
    rm .env
fi

# Generate SECRET_KEY
echo "🔐 Generating SECRET_KEY..."
SECRET_KEY=$(python3 -c "import secrets; print(secrets.token_urlsafe(32))" 2>/dev/null || openssl rand -base64 32)
echo "   ✓ SECRET_KEY generated"

# Get SQL Server password
echo ""
echo "🔒 SQL Server Password Configuration"
echo "   Password requirements: 8+ chars, uppercase, lowercase, number, special char"
read -sp "   Enter MSSQL_SA_PASSWORD: " MSSQL_SA_PASSWORD
echo ""

if [ ${#MSSQL_SA_PASSWORD} -lt 8 ]; then
    echo "❌ Password too short (minimum 8 characters)"
    exit 1
fi

# Get database URL
echo ""
echo "📊 Database Configuration"
echo "   Examples:"
echo "   - SQL Server: mssql+pyodbc://sa:PASSWORD@sqlserver:1433/JobsDB?driver=ODBC+Driver+18+for+SQL+Server&TrustServerCertificate=yes"
echo "   - PostgreSQL: postgresql://user:pass@localhost:5432/jobsite_db"
read -p "   Enter DATABASE_URL: " DATABASE_URL

if [ -z "$DATABASE_URL" ]; then
    echo "❌ DATABASE_URL cannot be empty"
    exit 1
fi

# Create .env file
cat > .env << EOF
# Flask Application
FLASK_APP=run.py
FLASK_ENV=development
FLASK_DEBUG=1

# Security
SECRET_KEY=$SECRET_KEY

# Database Configuration
DATABASE_URL=$DATABASE_URL

# SQL Server Settings
MSSQL_SA_PASSWORD=$MSSQL_SA_PASSWORD

# Application Settings
APP_NAME=JobSite
ITEMS_PER_PAGE=10
EOF

chmod 600 .env
echo ""
echo "✅ .env file created successfully!"
echo "   Location: $(pwd)/.env"
echo "   Permissions: 600 (user read/write only)"
echo ""
echo "⚡ Next steps:"
echo "   1. Run: docker-compose up -d"
echo "   2. Wait for SQL Server to be healthy (check logs: docker-compose logs -f sqlserver)"
echo "   3. Access app at: http://localhost:5000"
echo ""
