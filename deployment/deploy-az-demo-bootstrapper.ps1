# ------------------------------------------------------------
#  Copyright (c) Microsoft Corporation.  All rights reserved.
#  Licensed under the MIT License (MIT). See License.txt in the repo root for license information.
# ------------------------------------------------------------
Param(
    [string]
    [Parameter(mandatory=$true)]
    $ApplicationName
)

Clear-Host

$ProgressPreference = 'SilentlyContinue'
$baseLocation = "https://raw.githubusercontent.com/suneetnangia/distributed-az-edge-framework/main"

# bootstrap functions
Invoke-WebRequest -Uri "$baseLocation/deployment/functions.ps1" -OutFile "functions.ps1"
. .\functions.ps1

# ----- Copy scripts from source location
Write-Title("Download Scripts")

Write-Host "Downloading deploy-core-infrastructure.ps1..."
Invoke-WebRequest -Uri "$baseLocation/deployment/deploy-core-infrastructure.ps1" -OutFile "deploy-core-infrastructure.ps1"
Write-Host "Downloading deploy-core-platform.ps1..."
Invoke-WebRequest -Uri "$baseLocation/deployment/deploy-core-platform.ps1" -OutFile "deploy-core-platform.ps1"
Write-Host "Downloading deploy-app.ps1..."
Invoke-WebRequest -Uri "$baseLocation/deployment/deploy-app.ps1" -OutFile "deploy-app.ps1"

Write-Host "Downloading bicep files..."
mkdir -p bicep/modules | Out-Null

Invoke-WebRequest -Uri "$baseLocation/deployment/bicep/core-infrastructure.bicep" -OutFile "./bicep/core-infrastructure.bicep"
Invoke-WebRequest -Uri "$baseLocation/deployment/bicep/app.bicep" -OutFile "./bicep/app.bicep"
Invoke-WebRequest -Uri "$baseLocation/deployment/bicep/modules/aks.bicep" -OutFile "./bicep/modules/aks.bicep"
Invoke-WebRequest -Uri "$baseLocation/deployment/bicep/modules/azurestorage.bicep" -OutFile "./bicep/modules/azurestorage.bicep"
Invoke-WebRequest -Uri "$baseLocation/deployment/bicep/modules/eventhub.bicep" -OutFile "./bicep/modules/eventhub.bicep"

./deploy-core-infrastructure.ps1 -ApplicationName $ApplicationName

./deploy-core-platform.ps1 -ApplicationName $ApplicationName

./deploy-app.ps1 -ApplicationName $ApplicationName -AKSClusterResourceGroupName $env:RESOURCEGROUPNAME -AKSClusterName $env:AKSCLUSTERNAME

Write-Title
Write-Host "Distributed Edge Accelerator is now deployed in Azure Resource Group '$env:RESOURCEGROUPNAME', please use the Event Hub instance to view the OPC UA and Simulated Sensor telemetry." -ForegroundColor Yellow
Write-Title
