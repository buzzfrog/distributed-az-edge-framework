// ------------------------------------------------------------
//  Copyright (c) Microsoft Corporation.  All rights reserved.
//  Licensed under the MIT License (MIT). See License.txt in the repo root for license information.
// ------------------------------------------------------------
targetScope = 'subscription'

@description('The common name for this application')
param applicationName string

@description('Location of resources')
@allowed([
  'westeurope'
  'northeurope'
  'westus'
])
param location string = 'westeurope'

@description('Run deployment script')
param runDeployScript bool = false

var applicationNameWithoutDashes = '${replace(applicationName,'-','')}'
var resourceGroupName = 'rg-${applicationNameWithoutDashes}'
var aksName = '${take('aks-${applicationNameWithoutDashes}',20)}'
var acrName = 'acr${applicationNameWithoutDashes}'
var storageAccountName = 'st${take(applicationNameWithoutDashes,14)}'
var eventHubNameSpaceName = 'evh${take(applicationNameWithoutDashes,14)}'

resource rg 'Microsoft.Resources/resourceGroups@2020-10-01' = {
  name: resourceGroupName
  location: location
}

module aks 'modules/aks.bicep' = {
  name: 'aksDeployment'
  scope: resourceGroup(rg.name)
  params: {
    aksName: aksName
  }
}

module acr 'modules/arc.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'acrDeployment'
  params: {
    acrName: acrName
    aksPrincipalId: aks.outputs.clusterPrincipalID
  }

  dependsOn: [
    aks
  ]
}

module storage 'modules/azurestorage.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'storageDeployment'
  params: {
    storageAccountName: storageAccountName
  }
}

module eventhub 'modules/eventhub.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'eventHubDeployment'
  params: {
    eventHubNameSpaceName: eventHubNameSpaceName
  }
}

module script 'modules/script.bicep' = if(runDeployScript) {
  scope: resourceGroup(rg.name)
  name: 'scriptDeployment'
  params:{
    storageKey: storage.outputs.storageKey
    storageName: storage.outputs.storageName
    acrName: acrName
    aksName: aksName
    eventHubConnectionString: eventhub.outputs.eventHubConnectionString
  }

  dependsOn: [
    aks
    acr
    storage
    eventhub
  ]
}

output acrName string = acrName
output aksName string = aks.outputs.aksName
output resourceGroupName string = resourceGroupName
output storageKey string = storage.outputs.storageKey
output storageName string = storage.outputs.storageName
output eventHubConnectionString string = eventhub.outputs.eventHubConnectionString
