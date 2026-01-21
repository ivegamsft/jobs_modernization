#!/bin/bash

# ============================================================================
# Bicep Deployment Script for Legacy Job Site Application (Bash/Linux)
# ============================================================================
# Usage: 
#   ./deploy-bicep.sh dev jobsite-dev-rg
#   ./deploy-bicep.sh prod jobsite-prod-rg eastus
#
# Prerequisites:
#   - Azure CLI installed
#   - Logged in to Azure (az login)
#   - Appropriate permissions in target subscription
# ============================================================================

set -e

ENVIRONMENT=${1:-dev}
RESOURCE_GROUP=${2:-jobsite-${ENVIRONMENT}-rg}
LOCATION=${3:-eastus}
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BICEP_FILE="${SCRIPT_DIR}/main.bicep"
PARAM_FILE="${SCRIPT_DIR}/main.${ENVIRONMENT}.bicepparam"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
DEPLOYMENT_NAME="jobsite-deploy-${ENVIRONMENT}-${TIMESTAMP}"

echo "═══════════════════════════════════════════════════════════════════"
echo "Job Site Application - Bicep Deployment ($ENVIRONMENT)"
echo "═══════════════════════════════════════════════════════════════════"
echo ""

# ============================================================================
# Validation
# ============================================================================

echo "📋 Validating deployment prerequisites..."

if [ ! -f "$BICEP_FILE" ]; then
    echo "❌ Bicep file not found: $BICEP_FILE"
    exit 1
fi

if [ ! -f "$PARAM_FILE" ]; then
    echo "❌ Parameter file not found: $PARAM_FILE"
    exit 1
fi

if ! command -v az &> /dev/null; then
    echo "❌ Azure CLI is required. Please install it first."
    exit 1
fi

echo "✅ Prerequisites validated"
echo ""

# ============================================================================
# Azure Connection
# ============================================================================

echo "🔐 Checking Azure connection..."

if ! az account show &> /dev/null; then
    echo "Please login to Azure..."
    az login
fi

echo "✅ Connected to Azure"
echo ""

# ============================================================================
# Resource Group
# ============================================================================

echo "📦 Checking resource group: $RESOURCE_GROUP"

if ! az group show --name "$RESOURCE_GROUP" &> /dev/null; then
    echo "Creating resource group: $RESOURCE_GROUP in $LOCATION"
    az group create \
        --name "$RESOURCE_GROUP" \
        --location "$LOCATION" \
        --tags environment="$ENVIRONMENT" application="jobsite"
fi

echo "✅ Resource group ready: $RESOURCE_GROUP"
echo ""

# ============================================================================
# Bicep Validation
# ============================================================================

echo "🔍 Validating Bicep template..."

if ! az deployment group validate \
    --resource-group "$RESOURCE_GROUP" \
    --template-file "$BICEP_FILE" \
    --parameters "$PARAM_FILE" &> /dev/null; then
    echo "❌ Bicep validation failed"
    az deployment group validate \
        --resource-group "$RESOURCE_GROUP" \
        --template-file "$BICEP_FILE" \
        --parameters "$PARAM_FILE"
    exit 1
fi

echo "✅ Bicep template validated"
echo ""

# ============================================================================
# Deployment
# ============================================================================

echo "🚀 Starting deployment..."
echo "Deployment Name: $DEPLOYMENT_NAME"
echo "Environment: $ENVIRONMENT"
echo "Location: $LOCATION"
echo ""

az deployment group create \
    --name "$DEPLOYMENT_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --template-file "$BICEP_FILE" \
    --parameters "$PARAM_FILE"

if [ $? -ne 0 ]; then
    echo "❌ Deployment failed"
    exit 1
fi

echo "✅ Deployment completed successfully"
echo ""

# ============================================================================
# Output
# ============================================================================

echo "📊 Deployment Outputs:"
echo ""

az deployment group show \
    --resource-group "$RESOURCE_GROUP" \
    --name "$DEPLOYMENT_NAME" \
    --query "properties.outputs" \
    -o table

echo ""
echo "═══════════════════════════════════════════════════════════════════"
echo "Deployment completed!"
echo "═══════════════════════════════════════════════════════════════════"

# ============================================================================
# Next Steps
# ============================================================================

echo ""
echo "📝 Next Steps:"
echo "1. Review the deployed resources in Azure Portal"
echo "2. Deploy your application package to App Service:"
echo "   az webapp deployment source config-zip --resource-group $RESOURCE_GROUP --name <app-service-name> --src app.zip"
echo "3. Monitor application health in Application Insights"
echo "4. Test the application at the deployed URL"
echo ""
