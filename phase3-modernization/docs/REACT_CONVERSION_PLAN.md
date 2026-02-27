# AppV2 to React Conversion Plan

## Executive Summary

This document outlines a comprehensive plan to convert the current ASP.NET Core backend API (appV2) architecture into a modern full-stack solution with a React frontend and optimized Azure deployment using Bicep infrastructure-as-code. The conversion will maintain the existing API while adding a new React SPA (Single Page Application) frontend.

---

## 1. Project Structure & Architecture

### 1.1 Target Architecture Overview

```
jobs_modernization/
├── appV2-api/                          # Existing ASP.NET Core API (refactored)
│   ├── src/
│   │   ├── JobSite.Api/
│   │   ├── JobSite.Application/
│   │   ├── JobSite.Core/
│   │   └── JobSite.Infrastructure/
│   ├── tests/
│   └── Dockerfile
│
├── appV2-react/                        # NEW: React Frontend
│   ├── public/
│   ├── src/
│   │   ├── components/
│   │   ├── pages/
│   │   ├── services/
│   │   ├── context/
│   │   ├── hooks/
│   │   ├── utils/
│   │   ├── styles/
│   │   └── App.tsx
│   ├── package.json
│   ├── tsconfig.json
│   ├── vite.config.ts
│   ├── tailwind.config.js
│   ├── Dockerfile
│   └── .dockerignore
│
└── config/
    ├── bicep/
    │   ├── main.bicep                  # Main orchestration template
    │   ├── modules/
    │   │   ├── api-service.bicep       # ASP.NET Core API hosting
    │   │   ├── react-app.bicep         # React SPA hosting (Static Web Apps)
    │   │   ├── database.bicep          # SQL Database
    │   │   ├── keyvault.bicep          # Key Vault
    │   │   ├── monitoring.bicep        # Application Insights & Log Analytics
    │   │   ├── cdn.bicep               # CDN for React static assets
    │   │   ├── networking.bicep        # VNets, NSGs, Firewall rules
    │   │   └── storage.bicep           # Azure Storage (if needed)
    │   └── parameters/
    │       ├── dev.parameters.json
    │       ├── staging.parameters.json
    │       └── prod.parameters.json
    ├── scripts/
    │   ├── deploy.ps1                  # Main deployment script
    │   ├── build-images.ps1            # Docker build script
    │   └── validate.ps1                # Template validation
    └── docs/
        ├── DEPLOYMENT_GUIDE.md
        ├── ARCHITECTURE.md
        └── MIGRATION_CHECKLIST.md
```

### 1.2 Technology Stack

#### Backend (Existing - Enhanced)
- **Framework**: ASP.NET Core 8.0+
- **Database**: Azure SQL Database
- **Authentication**: Azure AD / ASP.NET Core Identity
- **Caching**: Redis (optional for high-scale)
- **Logging**: Application Insights + Serilog
- **Container**: Docker (Linux)

#### Frontend (NEW)
- **Framework**: React 18+
- **Language**: TypeScript
- **Build Tool**: Vite (faster than Create React App)
- **Package Manager**: npm or pnpm
- **UI Framework**: TailwindCSS or Material-UI
- **State Management**: Context API + custom hooks (or Redux if complex)
- **API Client**: Axios or Fetch API with custom wrapper
- **Testing**: Vitest + React Testing Library
- **Container**: Docker (Node.js)

#### Deployment (Azure)
- **Frontend Hosting**: Azure Static Web Apps (recommended for React SPAs)
- **Backend Hosting**: Azure App Service (Linux)
- **Database**: Azure SQL Database (existing)
- **CDN**: Azure CDN (for static assets)
- **Monitoring**: Application Insights
- **Infrastructure**: Bicep templates

---

## 2. Phase 1: Project Setup & Foundation (Weeks 1-2)

### 2.1 Create React Application Structure

**Tasks:**
1. Initialize new React project with Vite
   ```bash
   npm create vite@latest appV2-react -- --template react-ts
   cd appV2-react
   npm install
   ```

2. Install core dependencies
   ```bash
   npm install axios react-router-dom zustand
   npm install -D typescript tailwindcss postcss autoprefixer
   npm run build
   ```

3. Setup TailwindCSS
   ```bash
   npx tailwindcss init -p
   ```

4. Configure build optimization
   - Update `vite.config.ts` for production builds
   - Configure source maps for debugging
   - Setup environment variables (.env files)

5. Establish folder structure
   ```
   src/
   ├── components/
   │   ├── common/          (Header, Footer, Navigation, etc.)
   │   ├── employer/        (Employer-specific components)
   │   ├── jobseeker/       (JobSeeker-specific components)
   │   └── auth/            (Login, Register, ChangePassword)
   ├── pages/
   │   ├── EmployerDashboard.tsx
   │   ├── JobSeekerDashboard.tsx
   │   ├── Login.tsx
   │   ├── Register.tsx
   │   ├── NotFound.tsx
   │   └── ErrorBoundary.tsx
   ├── services/
   │   ├── api.ts           (Axios instance config)
   │   ├── jobService.ts
   │   ├── companyService.ts
   │   ├── authService.ts
   │   └── resumeService.ts
   ├── context/
   │   ├── AuthContext.tsx
   │   └── AppContext.tsx
   ├── hooks/
   │   ├── useAuth.ts
   │   ├── useFetch.ts
   │   └── useLocalStorage.ts
   ├── utils/
   │   ├── constants.ts
   │   ├── validators.ts
   │   └── formatters.ts
   ├── styles/
   │   ├── globals.css
   │   └── variables.css
   ├── App.tsx
   ├── main.tsx
   └── vite-env.d.ts
   ```

### 2.2 Setup Backend API Adaptations

**Tasks:**
1. Update ASP.NET Core API for CORS (if not already done)
   ```csharp
   // In Program.cs
   builder.Services.AddCors(options =>
   {
       options.AddPolicy("ReactApp", builder =>
           builder.AllowAnyOrigin()
                  .AllowAnyMethod()
                  .AllowAnyHeader());
   });
   ```

2. Ensure API returns proper error responses (standardized format)
3. Add API versioning (v1, v2)
4. Setup JWT token handling for authentication
5. Document all API endpoints (OpenAPI/Swagger)

### 2.3 Environment Configuration

**Create `.env` files:**
- `.env.development` - Local development API URL
- `.env.staging` - Staging environment
- `.env.production` - Production environment

---

## 3. Phase 2: React Component Development (Weeks 3-6)

### 3.1 Authentication & Core Features

**Components to Build:**
1. **Auth Components**
   - Login page with email/password
   - Registration page
   - Change password page
   - Protected route wrapper
   - Auth context provider

2. **Layout Components**
   - Header/Navigation
   - Sidebar/Navigation menu
   - Footer
   - Layout container

3. **Employer Components**
   - Dashboard
   - Job posting management (list, create, edit, delete)
   - Company profile
   - Candidate search & filtering
   - Resume viewer
   - Favorites/Saved resumes

4. **Job Seeker Components**
   - Dashboard
   - Job search & filtering
   - Job posting details view
   - Resume management (upload, edit, list)
   - Favorites/Saved jobs
   - Company profile view

### 3.2 State Management Setup

**Options:**
1. **Context API (Recommended for MVP)**
   - Create `AuthContext` for user auth state
   - Create `AppContext` for global app state
   - Use custom hooks for derived state

2. **Redux (If complexity warrants)**
   - Setup Redux store
   - Create slices: auth, jobs, companies, resumes
   - Implement middleware for API calls

**Implement:**
```typescript
// Example: AuthContext
interface User {
  id: string;
  email: string;
  role: 'JobSeeker' | 'Employer' | 'Admin';
  name: string;
}

interface AuthContextType {
  user: User | null;
  loading: boolean;
  login: (email: string, password: string) => Promise<void>;
  logout: () => void;
  register: (data: RegistrationData) => Promise<void>;
}

const AuthContext = createContext<AuthContextType | null>(null);
```

### 3.3 API Integration Layer

**Create Service Classes:**
```typescript
// services/api.ts
import axios from 'axios';

const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:5000/api';

const apiClient = axios.create({
  baseURL: API_BASE_URL,
  timeout: 10000,
});

// Add request interceptor for auth token
apiClient.interceptors.request.use((config) => {
  const token = localStorage.getItem('authToken');
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

// Add response interceptor for error handling
apiClient.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response?.status === 401) {
      // Handle token expiration
      localStorage.removeItem('authToken');
      window.location.href = '/login';
    }
    return Promise.reject(error);
  }
);

export default apiClient;
```

---

## 4. Phase 3: Testing & Quality Assurance (Weeks 7-8)

### 4.1 Unit Testing Setup

**Setup Vitest:**
```bash
npm install -D vitest @vitest/ui
npm install -D @testing-library/react @testing-library/jest-dom
```

**Test Structure:**
```
src/
├── __tests__/
│   ├── components/
│   ├── hooks/
│   ├── services/
│   └── utils/
```

**Example Tests:**
- Auth context tests
- Component rendering tests
- Hook behavior tests
- API service tests with mocks

### 4.2 Integration Testing

- Test API integration end-to-end
- Test authentication flow
- Test user workflows (job search, posting, etc.)

### 4.3 Performance & Accessibility

- Lighthouse audits
- Accessibility compliance (WCAG 2.1 AA)
- Bundle size analysis
- Load time optimization

---

## 5. Phase 4: Docker & Containerization (Week 9)

### 5.1 React Dockerfile

```dockerfile
# Stage 1: Build
FROM node:18-alpine AS builder

WORKDIR /app
COPY package*.json ./
RUN npm ci

COPY . .
RUN npm run build

# Stage 2: Serve
FROM node:18-alpine

WORKDIR /app
RUN npm install -g serve

COPY --from=builder /app/dist ./dist

EXPOSE 3000

CMD ["serve", "-s", "dist", "-l", "3000"]
```

### 5.2 Update Backend Dockerfile

- Ensure ASP.NET Core API has production-optimized Dockerfile
- Multi-stage build pattern
- Health check endpoints
- Proper logging configuration

### 5.3 Docker Compose for Local Development

```yaml
version: '3.8'

services:
  api:
    build:
      context: ./appV2-api
    ports:
      - "5000:5000"
    environment:
      - ASPNETCORE_ENVIRONMENT=Development
    depends_on:
      - sqlserver

  react:
    build:
      context: ./appV2-react
    ports:
      - "3000:3000"
    environment:
      - VITE_API_URL=http://api:5000/api
    depends_on:
      - api

  sqlserver:
    image: mcr.microsoft.com/mssql/server
    ports:
      - "1433:1433"
    environment:
      SA_PASSWORD: YourPassword123!
      ACCEPT_EULA: Y
```

---

## 6. Phase 5: Azure Deployment with Bicep

### 6.1 Bicep Module Architecture

#### Main Bicep File Structure (`main.bicep`)

```bicep
param location string = resourceGroup().location
param environment string = 'dev'
param appName string = 'jobsite'

// Import modules
module apiService 'modules/api-service.bicep' = {
  name: 'apiServiceModule'
  params: {
    location: location
    environment: environment
    appName: appName
    sqlServerName: sqlModule.outputs.sqlServerName
    sqlDatabaseName: sqlModule.outputs.sqlDatabaseName
    keyVaultUri: keyVaultModule.outputs.vaultUri
    appInsightsConnectionString: monitoringModule.outputs.appInsightsConnectionString
  }
}

module reactApp 'modules/react-app.bicep' = {
  name: 'reactAppModule'
  params: {
    location: location
    environment: environment
    appName: appName
    apiUrl: apiService.outputs.apiUrl
    cdnUrl: cdnModule.outputs.cdnUrl
  }
}

module sqlModule 'modules/database.bicep' = {
  name: 'databaseModule'
  params: {
    location: location
    environment: environment
    appName: appName
  }
}

module keyVaultModule 'modules/keyvault.bicep' = {
  name: 'keyVaultModule'
  params: {
    location: location
    environment: environment
    appName: appName
    apiServicePrincipalId: apiService.outputs.servicePrincipalId
  }
}

module monitoringModule 'modules/monitoring.bicep' = {
  name: 'monitoringModule'
  params: {
    location: location
    environment: environment
    appName: appName
  }
}

module cdnModule 'modules/cdn.bicep' = {
  name: 'cdnModule'
  params: {
    location: location
    environment: environment
    appName: appName
  }
}

module networkingModule 'modules/networking.bicep' = {
  name: 'networkingModule'
  params: {
    location: location
    environment: environment
    appName: appName
    sqlServerName: sqlModule.outputs.sqlServerName
  }
}

// Outputs
output apiUrl string = apiService.outputs.apiUrl
output reactAppUrl string = reactApp.outputs.appUrl
output keyVaultUri string = keyVaultModule.outputs.vaultUri
```

#### 6.1.1 `modules/api-service.bicep`

```bicep
param location string
param environment string
param appName string
param sqlServerName string
param sqlDatabaseName string
param keyVaultUri string
param appInsightsConnectionString string

var apiServiceName = '${appName}-api-${environment}'
var planName = '${appName}-api-plan-${environment}'
var skuName = environment == 'prod' ? 'P1V2' : (environment == 'staging' ? 'S1' : 'B1')
var capacity = environment == 'prod' ? 3 : (environment == 'staging' ? 2 : 1)

resource appServicePlan 'Microsoft.Web/serverfarms@2023-01-01' = {
  name: planName
  location: location
  kind: 'linux'
  properties: {
    reserved: true
  }
  sku: {
    name: skuName
    capacity: capacity
  }
}

resource appService 'Microsoft.Web/sites@2023-01-01' = {
  name: apiServiceName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    siteConfig: {
      linuxFxVersion: 'DOTNETCORE|8.0'
      alwaysOn: true
      http20Enabled: true
      minTlsVersion: '1.2'
      appSettings: [
        {
          name: 'ASPNETCORE_ENVIRONMENT'
          value: environment
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: appInsightsConnectionString
        }
        {
          name: 'KeyVault:VaultUri'
          value: keyVaultUri
        }
        {
          name: 'DOCKER_REGISTRY_SERVER_URL'
          value: 'https://index.docker.io'
        }
      ]
      connectionStrings: [
        {
          name: 'DefaultConnection'
          connectionString: 'Server=tcp:${sqlServerName}.database.windows.net,1433;Initial Catalog=${sqlDatabaseName};Authentication=Active Directory Default;'
          type: 'SQLServer'
        }
      ]
    }
  }
}

resource appServiceConfig 'Microsoft.Web/sites/config@2023-01-01' = {
  parent: appService
  name: 'web'
  properties: {
    numberOfWorkers: 1
    defaultDocuments: []
  }
}

output apiUrl string = 'https://${appService.properties.defaultHostName}'
output servicePrincipalId string = appService.identity.principalId
```

#### 6.1.2 `modules/react-app.bicep`

```bicep
param location string
param environment string
param appName string
param apiUrl string
param cdnUrl string

var staticAppName = '${appName}-spa-${environment}'
var repositoryUrl = 'https://github.com/your-org/jobs_modernization' // Update with actual repo
var branch = environment == 'prod' ? 'main' : (environment == 'staging' ? 'staging' : 'develop')

resource staticWebApp 'Microsoft.Web/staticSites@2023-01-01' = {
  name: staticAppName
  location: location
  sku: {
    name: 'Free' // For production, consider 'Standard'
    tier: environment == 'prod' ? 'Standard' : 'Free'
  }
  properties: {
    repositoryUrl: repositoryUrl
    branch: branch
    buildProperties: {
      appLocation: 'appV2-react'
      outputLocation: 'dist'
      appBuildCommand: 'npm install && npm run build'
      skipGithubActionWorkflowGeneration: true
    }
  }
}

// Add custom domain and SSL if needed
resource customDomain 'Microsoft.Web/staticSites/customDomains@2023-01-01' = if (environment == 'prod') {
  parent: staticWebApp
  name: 'yourdomain.com'
}

resource appSettingsConfig 'Microsoft.Web/staticSites/config@2023-01-01' = {
  parent: staticWebApp
  name: 'appsettings'
  properties: {
    'VITE_API_URL': apiUrl
    'VITE_CDN_URL': cdnUrl
    'VITE_ENV': environment
  }
}

output appUrl string = staticWebApp.properties.defaultHostname
output deploymentToken string = staticWebApp.listSecrets().properties.apiKey
```

#### 6.1.3 `modules/database.bicep`

```bicep
param location string
param environment string
param appName string

var sqlServerName = '${appName}-sqlserver-${environment}'
var sqlDatabaseName = '${appName}-db-${environment}'

resource sqlServer 'Microsoft.Sql/servers@2021-08-01-preview' = {
  name: sqlServerName
  location: location
  properties: {
    version: '12.0'
    administrators: {
      login: 'aadadmin'
      administratorType: 'ActiveDirectory'
      principalType: 'Group'
      tenantId: subscription().tenantId
      sid: 'YOUR_AZURE_AD_GROUP_SID' // Use Azure AD group for admin
    }
    restrictOutboundNetworkAccess: 'Disabled'
    publicNetworkAccess: 'Enabled'
  }
}

resource sqlDatabase 'Microsoft.Sql/servers/databases@2021-08-01-preview' = {
  parent: sqlServer
  name: sqlDatabaseName
  location: location
  sku: {
    name: environment == 'prod' ? 'S1' : (environment == 'staging' ? 'S0' : 'Basic')
    tier: environment == 'prod' ? 'Standard' : (environment == 'staging' ? 'Standard' : 'Basic')
  }
  properties: {
    collation: 'SQL_Latin1_General_CP1_CI_AS'
    maxSizeBytes: environment == 'prod' ? 107374182400 : 1073741824
  }
}

resource firewall 'Microsoft.Sql/servers/firewallRules@2021-08-01-preview' = {
  parent: sqlServer
  name: 'AllowAzureServices'
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}

resource vulnerabilityAssessment 'Microsoft.Sql/servers/securityAlertPolicies@2021-08-01-preview' = {
  parent: sqlServer
  name: 'default'
  properties: {
    state: 'Enabled'
    disabledAlerts: []
    emailAddresses: []
    emailNotificationAdmins: true
  }
}

output sqlServerName string = sqlServer.name
output sqlServerFqdn string = sqlServer.properties.fullyQualifiedDomainName
output sqlDatabaseName string = sqlDatabase.name
output connectionString string = 'Server=tcp:${sqlServer.properties.fullyQualifiedDomainName},1433;Initial Catalog=${sqlDatabase.name};'
```

#### 6.1.4 `modules/monitoring.bicep`

```bicep
param location string
param environment string
param appName string

var appInsightsName = '${appName}-insights-${environment}'
var workspaceName = '${appName}-law-${environment}'

resource workspace 'Microsoft.OperationalInsights/workspaces@2021-12-01-preview' = {
  name: workspaceName
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: environment == 'prod' ? 90 : (environment == 'staging' ? 30 : 7)
  }
}

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: workspace.id
    RetentionInDays: environment == 'prod' ? 90 : (environment == 'staging' ? 30 : 7)
  }
}

resource diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: workspace
  name: 'diagnostics'
  properties: {
    workspaceId: workspace.id
    logs: [
      {
        category: 'Audit'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: 30
        }
      }
    ]
  }
}

output appInsightsKey string = appInsights.properties.InstrumentationKey
output appInsightsConnectionString string = appInsights.properties.ConnectionString
output workspaceId string = workspace.id
```

#### 6.1.5 `modules/keyvault.bicep`

```bicep
param location string
param environment string
param appName string
param apiServicePrincipalId string

var keyVaultName = replace('${appName}-kv-${environment}', '-', '')

resource keyVault 'Microsoft.KeyVault/vaults@2023-02-01' = {
  name: keyVaultName
  location: location
  properties: {
    tenantId: subscription().tenantId
    sku: {
      family: 'A'
      name: 'standard'
    }
    accessPolicies: [
      {
        tenantId: subscription().tenantId
        objectId: apiServicePrincipalId
        permissions: {
          secrets: ['get', 'list']
          keys: ['get', 'list']
          certificates: ['get', 'list']
        }
      }
    ]
    enablePurgeProtection: environment == 'prod' ? true : false
    enableSoftDelete: true
    softDeleteRetentionInDays: 90
  }
}

output vaultUri string = keyVault.properties.vaultUri
output vaultId string = keyVault.id
output vaultName string = keyVault.name
```

#### 6.1.6 `modules/cdn.bicep`

```bicep
param location string
param environment string
param appName string

var cdnProfileName = '${appName}-cdn-${environment}'
var cdnEndpointName = '${appName}-cdn-ep-${environment}'

resource cdnProfile 'Microsoft.Cdn/profiles@2023-05-01' = if (environment == 'prod') {
  name: cdnProfileName
  location: location
  sku: {
    name: 'Standard_Microsoft'
  }
  properties: {}
}

resource cdnEndpoint 'Microsoft.Cdn/profiles/endpoints@2023-05-01' = if (environment == 'prod') {
  parent: cdnProfile
  name: cdnEndpointName
  location: location
  properties: {
    origins: [
      {
        name: 'myOrigin'
        properties: {
          hostName: 'yourstaticapp.azurestaticapps.net'
          httpsPort: 443
          priority: 1
          weight: 50
        }
      }
    ]
    isHttpAllowed: true
    isHttpsAllowed: true
    queryStringCachingBehavior: 'IgnoreQueryString'
    contentTypesToCompress: [
      'text/plain'
      'text/html'
      'text/xml'
      'text/css'
      'text/javascript'
      'application/x-javascript'
      'application/javascript'
      'application/json'
    ]
    isCompressionEnabled: true
  }
}

output cdnUrl string = environment == 'prod' ? 'https://${cdnEndpoint.properties.hostName}' : ''
output cdnProfileName string = cdnProfileName
```

#### 6.1.7 `modules/networking.bicep`

```bicep
param location string
param environment string
param appName string
param sqlServerName string

var nsgName = '${appName}-nsg-${environment}'
var vnetName = '${appName}-vnet-${environment}'
var subnetName = '${appName}-subnet-${environment}'

resource nsg 'Microsoft.Network/networkSecurityGroups@2023-04-01' = {
  name: nsgName
  location: location
  properties: {
    securityRules: [
      {
        name: 'AllowHTTP'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '80'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
      {
        name: 'AllowHTTPS'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 101
          direction: 'Inbound'
        }
      }
      {
        name: 'DenyAllInbound'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Deny'
          priority: 4096
          direction: 'Inbound'
        }
      }
    ]
  }
}

resource vnet 'Microsoft.Network/virtualNetworks@2023-04-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: '10.0.0.0/24'
          networkSecurityGroup: {
            id: nsg.id
          }
          serviceEndpoints: [
            {
              service: 'Microsoft.Sql'
            }
          ]
        }
      }
    ]
  }
}

output vnetId string = vnet.id
output subnetId string = vnet.properties.subnets[0].id
output nsgId string = nsg.id
```

### 6.2 Parameter Files

#### `parameters/dev.parameters.json`
```json
{
  "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "environment": {
      "value": "dev"
    },
    "location": {
      "value": "eastus"
    },
    "appName": {
      "value": "jobsite"
    }
  }
}
```

#### `parameters/staging.parameters.json`
```json
{
  "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "environment": {
      "value": "staging"
    },
    "location": {
      "value": "eastus"
    },
    "appName": {
      "value": "jobsite"
    }
  }
}
```

#### `parameters/prod.parameters.json`
```json
{
  "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "environment": {
      "value": "prod"
    },
    "location": {
      "value": "eastus"
    },
    "appName": {
      "value": "jobsite"
    }
  }
}
```

### 6.3 Deployment Scripts

#### `scripts/deploy.ps1`

```powershell
param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("dev", "staging", "prod")]
    [string]$Environment,
    
    [Parameter(Mandatory=$false)]
    [string]$Location = "eastus",
    
    [Parameter(Mandatory=$false)]
    [string]$ResourceGroupName = "rg-jobsite-$Environment"
)

$ErrorActionPreference = "Stop"

Write-Host "Deploying JobSite to $Environment environment..." -ForegroundColor Cyan

# Create resource group if it doesn't exist
$rg = az group show --name $ResourceGroupName --query "id" -o tsv 2>$null
if (-not $rg) {
    Write-Host "Creating resource group: $ResourceGroupName" -ForegroundColor Yellow
    az group create --name $ResourceGroupName --location $Location
}

# Get bicep file path
$bicepFile = (Join-Path (Get-Location) "config/bicep/main.bicep")
$parametersFile = (Join-Path (Get-Location) "config/bicep/parameters/$Environment.parameters.json")

if (-not (Test-Path $bicepFile)) {
    Write-Host "Error: Bicep file not found at $bicepFile" -ForegroundColor Red
    exit 1
}

if (-not (Test-Path $parametersFile)) {
    Write-Host "Error: Parameters file not found at $parametersFile" -ForegroundColor Red
    exit 1
}

# Validate template
Write-Host "Validating Bicep template..." -ForegroundColor Yellow
az deployment group validate `
    --resource-group $ResourceGroupName `
    --template-file $bicepFile `
    --parameters $parametersFile

if ($LASTEXITCODE -ne 0) {
    Write-Host "Template validation failed!" -ForegroundColor Red
    exit 1
}

# Deploy resources
Write-Host "Starting deployment..." -ForegroundColor Cyan
$deploymentName = "jobsite-deployment-$(Get-Date -Format yyyyMMdd-HHmmss)"

az deployment group create `
    --name $deploymentName `
    --resource-group $ResourceGroupName `
    --template-file $bicepFile `
    --parameters $parametersFile

if ($LASTEXITCODE -eq 0) {
    Write-Host "Deployment completed successfully!" -ForegroundColor Green
    
    # Get deployment outputs
    Write-Host "`nDeployment Outputs:" -ForegroundColor Cyan
    az deployment group show `
        --name $deploymentName `
        --resource-group $ResourceGroupName `
        --query "properties.outputs" -o table
} else {
    Write-Host "Deployment failed!" -ForegroundColor Red
    exit 1
}
```

#### `scripts/build-images.ps1`

```powershell
param(
    [Parameter(Mandatory=$true)]
    [string]$Registry,
    
    [Parameter(Mandatory=$false)]
    [string]$Tag = "latest"
)

$ErrorActionPreference = "Stop"

Write-Host "Building and pushing Docker images..." -ForegroundColor Cyan

# Build API image
Write-Host "Building API image..." -ForegroundColor Yellow
docker build -f "appV2-api/Dockerfile" -t "$Registry/jobsite-api:$Tag" .
docker push "$Registry/jobsite-api:$Tag"

if ($LASTEXITCODE -ne 0) {
    Write-Host "Failed to push API image!" -ForegroundColor Red
    exit 1
}

# Build React image
Write-Host "Building React app image..." -ForegroundColor Yellow
docker build -f "appV2-react/Dockerfile" -t "$Registry/jobsite-react:$Tag" .
docker push "$Registry/jobsite-react:$Tag"

if ($LASTEXITCODE -ne 0) {
    Write-Host "Failed to push React image!" -ForegroundColor Red
    exit 1
}

Write-Host "All images built and pushed successfully!" -ForegroundColor Green
```

---

## 7. Phase 6: CI/CD Pipeline Setup (Week 10)

### 7.1 GitHub Actions Workflows

#### `.github/workflows/deploy-dev.yml`
```yaml
name: Deploy to Dev

on:
  push:
    branches: [develop]

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Build Docker images
      run: |
        docker build -f appV2-api/Dockerfile -t jobsite-api:latest .
        docker build -f appV2-react/Dockerfile -t jobsite-react:latest .
    
    - name: Login to Azure
      uses: azure/login@v1
      with:
        creds: ${{ secrets.AZURE_CREDENTIALS }}
    
    - name: Deploy Bicep
      run: |
        az deployment group create \
          --resource-group rg-jobsite-dev \
          --template-file config/bicep/main.bicep \
          --parameters config/bicep/parameters/dev.parameters.json
```

---

## 8. Phase 7: Migration & Data Strategy

### 8.1 Database Considerations
- Maintain existing SQL Server schema
- Create migration scripts for any schema changes
- Implement database backup strategy
- Setup geo-replication for prod

### 8.2 Authentication & User Migration
- Support Azure AD authentication
- Maintain backward compatibility with existing tokens
- Implement token refresh strategy
- Setup API rate limiting

### 8.3 API Backward Compatibility
- Version API endpoints (/api/v1, /api/v2)
- Maintain existing endpoints during transition
- Gradually deprecate old endpoints
- Implement API change log

---

## 9. Security Considerations

### 9.1 Frontend Security
- ✅ HTTPS only
- ✅ Content Security Policy (CSP) headers
- ✅ CORS properly configured
- ✅ XSS protection
- ✅ CSRF token handling
- ✅ Secure storage of auth tokens (HttpOnly cookies preferred)
- ✅ Input validation & sanitization
- ✅ Environment variable management (no secrets in code)

### 9.2 Backend Security
- ✅ API authentication with JWT/OAuth2
- ✅ Role-based access control (RBAC)
- ✅ SQL injection prevention (parameterized queries)
- ✅ Rate limiting & DDoS protection
- ✅ HTTPS/TLS encryption
- ✅ Secrets in Key Vault
- ✅ API versioning
- ✅ Proper error handling (no sensitive info in errors)

### 9.3 Azure Infrastructure Security
- ✅ Network Security Groups (NSGs)
- ✅ SQL Database firewall rules
- ✅ Key Vault access policies
- ✅ Managed Identity authentication
- ✅ Application Insights monitoring
- ✅ Azure Defender enabled
- ✅ Regular security updates

---

## 10. Performance Optimization

### 10.1 Frontend Optimization
- Code splitting with React.lazy()
- Bundle analysis
- Image optimization (WebP, lazy loading)
- Minification & compression
- HTTP/2 server push
- Service Worker caching strategy
- Database connection pooling

### 10.2 Backend Optimization
- Database indexing strategy
- Query optimization
- Redis caching (optional)
- Response compression
- API pagination
- Batch endpoints for multiple requests

### 10.3 CDN & Caching
- Static asset caching with Azure CDN
- Browser cache headers
- Cache invalidation strategy
- Geographic distribution

---

## 11. Monitoring & Observability

### 11.1 Application Insights Setup
- ✅ Custom events tracking
- ✅ Performance monitoring
- ✅ Error rate tracking
- ✅ User session tracking
- ✅ Availability tests
- ✅ Custom metrics

### 11.2 Logging Strategy
- Structured logging (Serilog for backend, Winston/Pino for React)
- Centralized log aggregation
- Log retention policies (dev: 7 days, staging: 30 days, prod: 90 days)
- Alerting on critical errors

### 11.3 Health Checks
- API health endpoint (`/health`, `/health/ready`, `/health/live`)
- React app health checks
- Database connectivity checks
- External service checks

---

## 12. Implementation Timeline

| Phase | Duration | Milestones |
|-------|----------|-----------|
| **Phase 1: Setup** | 2 weeks | React app scaffolding, API adaptation, environment config |
| **Phase 2: Development** | 4 weeks | Component development, state management, API integration |
| **Phase 3: Testing** | 2 weeks | Unit tests, integration tests, QA, performance audits |
| **Phase 4: Containerization** | 1 week | Docker setup, docker-compose, image optimization |
| **Phase 5: Azure Deployment** | 1 week | Bicep modules, parameter files, deployment scripts |
| **Phase 6: CI/CD** | 1 week | GitHub Actions, automated builds, deployment pipelines |
| **Phase 7: Go-Live** | 1 week | Migration testing, cutover, monitoring, support |
| **Total** | **12 weeks** | Full React app with production Azure deployment |

---

## 13. Success Criteria

- ✅ React app fully functional and deployed
- ✅ All API endpoints accessible and working
- ✅ Authentication/Authorization working correctly
- ✅ Performance metrics meet SLAs (< 2s load time, 99.5% uptime)
- ✅ All tests passing (>80% code coverage)
- ✅ Zero security vulnerabilities (no critical/high severity)
- ✅ Monitoring & alerting configured
- ✅ Disaster recovery & backup strategies in place
- ✅ Documentation complete and up-to-date

---

## 14. Risk Mitigation

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|-----------|
| API compatibility issues | Medium | High | Maintain API versioning, comprehensive testing |
| Performance degradation | Medium | High | Load testing, CDN, caching strategy |
| Security vulnerabilities | Low | Critical | Security audit, OWASP compliance, pen testing |
| Data loss during migration | Low | Critical | Backup strategy, dry-run migration, rollback plan |
| Infrastructure costs spike | Medium | Medium | Cost monitoring, resource scaling policies |
| Team skill gaps (React/TS) | Medium | Medium | Training, pair programming, code reviews |

---

## 15. Appendix: Quick Reference

### Azure CLI Commands
```bash
# Create resource group
az group create --name rg-jobsite-dev --location eastus

# Validate Bicep
az deployment group validate --resource-group rg-jobsite-dev --template-file config/bicep/main.bicep --parameters config/bicep/parameters/dev.parameters.json

# Deploy
az deployment group create --name jobsite-deployment --resource-group rg-jobsite-dev --template-file config/bicep/main.bicep --parameters config/bicep/parameters/dev.parameters.json

# Get outputs
az deployment group show --name jobsite-deployment --resource-group rg-jobsite-dev --query properties.outputs
```

### Docker Commands
```bash
# Build images
docker build -f appV2-api/Dockerfile -t jobsite-api:latest .
docker build -f appV2-react/Dockerfile -t jobsite-react:latest .

# Local testing
docker-compose -f docker-compose.yml up

# Push to registry
docker tag jobsite-api:latest myregistry.azurecr.io/jobsite-api:latest
docker push myregistry.azurecr.io/jobsite-api:latest
```

### React Development Commands
```bash
# Create project
npm create vite@latest appV2-react -- --template react-ts

# Install dependencies
npm install

# Development
npm run dev

# Build
npm run build

# Preview production build
npm run preview

# Test
npm run test

# Lint
npm run lint
```

---

## 16. Next Steps

1. **Review & Approval**: Get stakeholder approval on this plan
2. **Resource Allocation**: Assign team members to each phase
3. **Setup Development Environment**: Begin Phase 1
4. **Create GitHub Issues**: Break down tasks into actionable items
5. **Establish Communication**: Weekly sync meetings for progress tracking

---

**Document Version**: 1.0  
**Last Updated**: January 21, 2026  
**Author**: AI Assistant  
**Status**: Ready for Review
