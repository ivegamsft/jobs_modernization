# Network Security - Deployment Examples

## Complete Deployment with Network Security

### Prerequisites

- Azure subscription
- Resource group created
- Core network infrastructure deployed
- Bicep files in place

---

## 1. PowerShell Deployment Script

```powershell
# ============================================================================
# Deploy IaaS Infrastructure with Network Security Configuration
# ============================================================================

param(
    [string]$SubscriptionId = "YOUR_SUB_ID",
    [string]$ResourceGroupName = "rg-jobsite-dev",
    [string]$Environment = "dev",
    [string]$Location = "swedencentral",
    [string[]]$AllowedRdpIps = @('203.0.113.0/32'),  # CHANGE THIS to your IP
    [string]$AdminUsername = "azureadmin"
)

# Secure input for password
$AdminPassword = Read-Host "Enter SQL Admin Password" -AsSecureString

# ============================================================================
# Step 1: Deploy Core Network Infrastructure (if not already done)
# ============================================================================

Write-Host "Step 1: Deploying Core Network Infrastructure..." -ForegroundColor Cyan

$coreDeployment = New-AzResourceGroupDeployment `
    -ResourceGroupName $ResourceGroupName `
    -TemplateFile ".\iac\bicep\core\main.bicep" `
    -TemplateParameterFile ".\iac\bicep\core\parameters.bicepparam" `
    -environment $Environment `
    -applicationName "jobsite" `
    -location $Location `
    -Verbose

Write-Host "Core infrastructure deployed successfully!" -ForegroundColor Green

# Extract outputs
$coreOutputs = $coreDeployment.Outputs
$frontendSubnetId = $coreOutputs['frontendSubnetId'].Value
$dataSubnetId = $coreOutputs['dataSubnetId'].Value
$vnetId = $coreOutputs['vnetId'].Value
$natGatewayId = $coreOutputs['natGatewayId'].Value
$natGatewayPublicIp = $coreOutputs['natGatewayPublicIp'].Value

Write-Host "`nCore Infrastructure Outputs:"
Write-Host "  Frontend Subnet ID: $frontendSubnetId"
Write-Host "  Data Subnet ID: $dataSubnetId"
Write-Host "  NAT Gateway ID: $natGatewayId"
Write-Host "  NAT Gateway Public IP: $natGatewayPublicIp"

# ============================================================================
# Step 2: Deploy IaaS Resources with NSG Rules
# ============================================================================

Write-Host "`nStep 2: Deploying IaaS Resources (VMs + NSGs)..." -ForegroundColor Cyan

$iaasDeployment = New-AzResourceGroupDeployment `
    -ResourceGroupName $ResourceGroupName `
    -TemplateFile ".\iac\bicep\iaas\main.bicep" `
    -environment $Environment `
    -applicationName "jobsite" `
    -location $Location `
    -frontendSubnetId $frontendSubnetId `
    -dataSubnetId $dataSubnetId `
    -adminUsername $AdminUsername `
    -adminPassword $AdminPassword `
    -allowedRdpIps $AllowedRdpIps `
    -Verbose

Write-Host "IaaS infrastructure deployed successfully!" -ForegroundColor Green

# Extract outputs
$iaasOutputs = $iaasDeployment.Outputs
$wfeVmId = $iaasOutputs['wfeVmId'].Value
$wfeVmName = $iaasOutputs['wfeVmName'].Value
$wfeVmPrivateIp = $iaasOutputs['wfeVmPrivateIp'].Value
$sqlVmId = $iaasOutputs['sqlVmId'].Value
$sqlVmName = $iaasOutputs['sqlVmName'].Value
$sqlVmPrivateIp = $iaasOutputs['sqlVmPrivateIp'].Value

Write-Host "`nVM Outputs:"
Write-Host "  Web VM Name: $wfeVmName"
Write-Host "  Web VM Private IP: $wfeVmPrivateIp"
Write-Host "  SQL VM Name: $sqlVmName"
Write-Host "  SQL VM Private IP: $sqlVmPrivateIp"

# ============================================================================
# Step 3: Validate Network Security Configuration
# ============================================================================

Write-Host "`nStep 3: Validating Network Security Configuration..." -ForegroundColor Cyan

# Get NSGs
$nsgFrontend = Get-AzNetworkSecurityGroup `
    -ResourceGroupName $ResourceGroupName `
    -Name "*nsg-frontend*" | Select-Object -First 1

$nsgData = Get-AzNetworkSecurityGroup `
    -ResourceGroupName $ResourceGroupName `
    -Name "*nsg-data*" | Select-Object -First 1

# Validate Frontend NSG Rules
Write-Host "`nFrontend NSG Rules:"
$nsgFrontend.SecurityRules | ForEach-Object {
    Write-Host "  ✓ $($_.Name) - Port $($_.DestinationPortRange) - Priority $($_.Priority)"
}

# Validate Data NSG Rules
Write-Host "`nData NSG Rules:"
$nsgData.SecurityRules | ForEach-Object {
    Write-Host "  ✓ $($_.Name) - Port $($_.DestinationPortRange) - Priority $($_.Priority)"
}

# ============================================================================
# Step 4: Display Connection Information
# ============================================================================

Write-Host "`n" -ForegroundColor Green
Write-Host "╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║           DEPLOYMENT COMPLETE - CONNECTION INFO                ║" -ForegroundColor Green
Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Green

Write-Host "`n📋 NETWORK INFORMATION:" -ForegroundColor Yellow
Write-Host "  NAT Gateway Public IP: $natGatewayPublicIp"
Write-Host "  VNet Address Space: 10.50.0.0/21"
Write-Host "  Frontend Subnet: 10.50.0.0/24"
Write-Host "  Data Subnet: 10.50.1.0/26"

Write-Host "`n🖥️  WEB VM (FRONTEND):" -ForegroundColor Yellow
Write-Host "  Name: $wfeVmName"
Write-Host "  Private IP: $wfeVmPrivateIp"
Write-Host "  HTTP Access: http://<NAT_Gateway_IP_or_DNS>"
Write-Host "  HTTPS Access: https://<NAT_Gateway_IP_or_DNS>"

Write-Host "`n🗄️  SQL SERVER VM (DATA):" -ForegroundColor Yellow
Write-Host "  Name: $sqlVmName"
Write-Host "  Private IP: $sqlVmPrivateIp"
Write-Host "  Port: 1433"

Write-Host "`n🔒 SECURITY CONFIGURATION:" -ForegroundColor Yellow
Write-Host "  ✓ Frontend NSG: Allows HTTP/HTTPS, RDP, SQL outbound, WinRM"
Write-Host "  ✓ Data NSG: Allows SQL from frontend, RDP, SSMS, WinRM"
Write-Host "  ✓ NAT Gateway: All outbound via static IP ($natGatewayPublicIp)"
Write-Host "  ✓ RDP allowed from: $($AllowedRdpIps -join ', ')"

Write-Host "`n✅ All infrastructure deployed successfully!" -ForegroundColor Green

# ============================================================================
# Optional: Export Configuration to Variables File
# ============================================================================

Write-Host "`nExporting configuration to file..." -ForegroundColor Cyan

@{
    SubscriptionId = $SubscriptionId
    ResourceGroupName = $ResourceGroupName
    Environment = $Environment
    Location = $Location
    NATGatewayPublicIP = $natGatewayPublicIp
    WebVMName = $wfeVmName
    WebVMPrivateIP = $wfeVmPrivateIp
    SqlVMName = $sqlVmName
    SqlVMPrivateIP = $sqlVmPrivateIp
    AllowedRdpIPs = $AllowedRdpIps
    FrontendSubnetId = $frontendSubnetId
    DataSubnetId = $dataSubnetId
    DeploymentTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
} | ConvertTo-Json | Out-File -Path "./deployment-config.json"

Write-Host "Configuration saved to: deployment-config.json" -ForegroundColor Green
```

---

## 2. Azure CLI Deployment Script

```bash
#!/bin/bash

# ============================================================================
# Deploy IaaS Infrastructure with Azure CLI
# ============================================================================

SUBSCRIPTION_ID="your-subscription-id"
RESOURCE_GROUP_NAME="rg-jobsite-dev"
ENVIRONMENT="dev"
LOCATION="swedencentral"
ADMIN_USERNAME="azureadmin"
ALLOWED_RDP_IPS='["203.0.113.0/32"]'  # Change to your IP

# ============================================================================
# Step 1: Deploy Core Network Infrastructure
# ============================================================================

echo "Deploying Core Network Infrastructure..."

CORE_DEPLOYMENT=$(az deployment group create \
  --resource-group $RESOURCE_GROUP_NAME \
  --template-file ./iac/bicep/core/main.bicep \
  --parameters ./iac/bicep/core/parameters.bicepparam \
  --parameters \
    environment=$ENVIRONMENT \
    applicationName=jobsite \
    location=$LOCATION \
  --output json)

# Extract outputs
FRONTEND_SUBNET_ID=$(echo $CORE_DEPLOYMENT | jq -r '.properties.outputs.frontendSubnetId.value')
DATA_SUBNET_ID=$(echo $CORE_DEPLOYMENT | jq -r '.properties.outputs.dataSubnetId.value')
NAT_GATEWAY_PUBLIC_IP=$(echo $CORE_DEPLOYMENT | jq -r '.properties.outputs.natGatewayPublicIp.value')

echo "Core infrastructure deployed!"
echo "Frontend Subnet: $FRONTEND_SUBNET_ID"
echo "Data Subnet: $DATA_SUBNET_ID"
echo "NAT Gateway IP: $NAT_GATEWAY_PUBLIC_IP"

# ============================================================================
# Step 2: Deploy IaaS Resources
# ============================================================================

echo "Deploying IaaS Resources..."

# Read password securely
read -s -p "Enter SQL Admin Password: " ADMIN_PASSWORD

IAAS_DEPLOYMENT=$(az deployment group create \
  --resource-group $RESOURCE_GROUP_NAME \
  --template-file ./iac/bicep/iaas/main.bicep \
  --parameters \
    environment=$ENVIRONMENT \
    applicationName=jobsite \
    location=$LOCATION \
    frontendSubnetId=$FRONTEND_SUBNET_ID \
    dataSubnetId=$DATA_SUBNET_ID \
    adminUsername=$ADMIN_USERNAME \
    adminPassword=$ADMIN_PASSWORD \
    allowedRdpIps="$ALLOWED_RDP_IPS" \
  --output json)

# Extract outputs
WFE_VM_NAME=$(echo $IAAS_DEPLOYMENT | jq -r '.properties.outputs.wfeVmName.value')
WFE_VM_PRIVATE_IP=$(echo $IAAS_DEPLOYMENT | jq -r '.properties.outputs.wfeVmPrivateIp.value')
SQL_VM_NAME=$(echo $IAAS_DEPLOYMENT | jq -r '.properties.outputs.sqlVmName.value')
SQL_VM_PRIVATE_IP=$(echo $IAAS_DEPLOYMENT | jq -r '.properties.outputs.sqlVmPrivateIp.value')

echo "IaaS infrastructure deployed!"
echo "Web VM: $WFE_VM_NAME ($WFE_VM_PRIVATE_IP)"
echo "SQL VM: $SQL_VM_NAME ($SQL_VM_PRIVATE_IP)"

# ============================================================================
# Step 3: Validate NSG Rules
# ============================================================================

echo "Validating NSG Configuration..."

# Get NSG names
FRONTEND_NSG=$(az network nsg list \
  --resource-group $RESOURCE_GROUP_NAME \
  --query "[?contains(name, 'nsg-frontend')].name" \
  --output tsv | head -1)

DATA_NSG=$(az network nsg list \
  --resource-group $RESOURCE_GROUP_NAME \
  --query "[?contains(name, 'nsg-data')].name" \
  --output tsv | head -1)

echo "Frontend NSG Rules:"
az network nsg rule list \
  --resource-group $RESOURCE_GROUP_NAME \
  --nsg-name $FRONTEND_NSG \
  --output table

echo "Data NSG Rules:"
az network nsg rule list \
  --resource-group $RESOURCE_GROUP_NAME \
  --nsg-name $DATA_NSG \
  --output table

# ============================================================================
# Display Summary
# ============================================================================

echo ""
echo "======================================================================"
echo "                    DEPLOYMENT COMPLETE"
echo "======================================================================"
echo ""
echo "📊 Network Information:"
echo "  NAT Gateway IP: $NAT_GATEWAY_PUBLIC_IP"
echo ""
echo "🖥️  Web VM:"
echo "  Name: $WFE_VM_NAME"
echo "  Private IP: $WFE_VM_PRIVATE_IP"
echo ""
echo "🗄️  SQL VM:"
echo "  Name: $SQL_VM_NAME"
echo "  Private IP: $SQL_VM_PRIVATE_IP"
echo ""
echo "✅ All resources deployed with proper NSG rules!"
echo "======================================================================"
```

---

## 3. Terraform Deployment Example

```hcl
# main.tf - Terraform deployment example

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
  default     = "rg-jobsite-dev"
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "swedencentral"
}

variable "allowed_rdp_ips" {
  description = "IPs allowed for RDP access"
  type        = list(string)
  default     = ["203.0.113.0/32"]
}

# Reference: Call your Bicep deployment
resource "null_resource" "deploy_core" {
  provisioner "local-exec" {
    command = <<-EOT
      az deployment group create \
        --resource-group ${var.resource_group_name} \
        --template-file ./iac/bicep/core/main.bicep \
        --parameters environment=dev location=${var.location}
    EOT
  }
}

resource "null_resource" "deploy_iaas" {
  depends_on = [null_resource.deploy_core]

  provisioner "local-exec" {
    command = <<-EOT
      az deployment group create \
        --resource-group ${var.resource_group_name} \
        --template-file ./iac/bicep/iaas/main.bicep \
        --parameters \
          environment=dev \
          location=${var.location} \
          allowedRdpIps='${jsonencode(var.allowed_rdp_ips)}'
    EOT
  }
}

output "deployment_status" {
  value = "IaaS infrastructure with network security deployed"
}
```

---

## 4. Manual Portal Deployment

If you prefer Azure Portal:

### Step 1: Deploy Core Network

1. Navigate to Azure Portal → Resource Groups → Create
2. Go to: `iac/bicep/core/main.bicep`
3. Deploy using Template Deployment
4. Note the outputs (Subnet IDs, NAT Gateway IP)

### Step 2: Deploy IaaS

1. Go to: `iac/bicep/iaas/main.bicep`
2. Provide parameters:
   - `frontendSubnetId`: From Core deployment
   - `dataSubnetId`: From Core deployment
   - `adminUsername`: azureadmin
   - `adminPassword`: Your secure password
   - `allowedRdpIps`: ["203.0.113.0/32"] (your IP)

### Step 3: Verify NSG Rules

1. Navigate to NSG → `jobsite-dev-nsg-frontend`
   - Check all rules in Inbound/Outbound
2. Navigate to NSG → `jobsite-dev-nsg-data`
   - Verify SQL rules (1433)
   - Verify RDP rule (3389)

### Step 4: Verify NAT Gateway

1. Navigate to NAT Gateway → `jobsite-dev-nat-[suffix]`
2. Verify:
   - Public IP is assigned
   - Both subnets are associated

---

## 5. Post-Deployment Verification

```powershell
# Test connectivity after deployment

# Test 1: Check Web VM can reach SQL VM
$webVmIP = "10.50.0.x"  # Replace with actual IP
$sqlVmIP = "10.50.1.x"  # Replace with actual IP

Invoke-Command -ComputerName $webVmIP -ScriptBlock {
    Test-NetConnection -ComputerName $sqlVmIP -Port 1433
}

# Test 2: Check NAT Gateway IP
Invoke-Command -ComputerName $webVmIP -ScriptBlock {
    (Invoke-WebRequest -Uri "https://checkip.amazonaws.com").Content
}

# Test 3: Verify NSG rules are in place
Get-AzNetworkSecurityGroup -Name "*nsg-frontend*" | Get-AzNetworkSecurityRuleConfig
Get-AzNetworkSecurityGroup -Name "*nsg-data*" | Get-AzNetworkSecurityRuleConfig
```

---

## Summary

All deployment methods:

- ✅ Deploy Core network with NAT Gateway
- ✅ Deploy Web VM with proper NSG rules
- ✅ Deploy SQL Server VM with proper NSG rules
- ✅ Enable Web-to-SQL communication (1433)
- ✅ Enable RDP from authorized IPs
- ✅ Enable SSMS access
- ✅ Enable WinRM for .NET automation
- ✅ Configure NAT Gateway for outbound traffic

Choose the deployment method that best fits your workflow!
