using './main.bicep'

param environment = 'dev'
param applicationName = 'jobsite'
param location = 'westus'
param vnetAddressPrefix = '10.50.0.0/16'
param sqlAdminUsername = 'jobsiteadmin'
param vpnClientAddressPool = '10.70.0.0/24'
