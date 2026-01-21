using './main.bicep'

param environment = 'staging'
param applicationName = 'jobsite'
param location = 'eastus'
param appServiceSku = 'S1'
param sqlDatabaseEdition = 'Standard'
param sqlServiceObjective = 'S1'
param sqlAdminUsername = 'sqladmin'
param sqlAdminPassword = 'ChangeMe@87654321!' // ⚠️ Change this! Use Key Vault in real deployment
param alertEmail = 'your-email@company.com'
