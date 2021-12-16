// ------------------------------------------------------------
//  Copyright (c) Microsoft Corporation.  All rights reserved.
//  Licensed under the MIT License (MIT). See License.txt in the repo root for license information.
// ------------------------------------------------------------
@maxLength(20)
@description('AKS Name')
param aksName string

@maxLength(20)
@description('ACR Name')
param acrName string

@description('EventHub Connection String')
param eventHubConnectionString string

@maxLength(20)
@description('Storage Account Name')
param storageName string

@description('Storage Account Key')
param storageKey string

var userAssignedIdentityName = 'Deployer'
var roleAssignmentName = guid(resourceGroup().id, 'contributor')
var contributorRoleDefinitionId = resourceId('Microsoft.Authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c')
var deploymentScriptName = 'DeploymentScript'

resource userAssignedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: userAssignedIdentityName
  location: resourceGroup().location
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: roleAssignmentName
  properties: {
    roleDefinitionId: contributorRoleDefinitionId
    principalId: userAssignedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

resource deploymentScript 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: deploymentScriptName
  location: resourceGroup().location
  kind: 'AzureCLI'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${userAssignedIdentity.id}': {}
    }
  }
  properties: {
    azCliVersion: '2.30.0'
    environmentVariables: [
      {
        name: 'RESOURCEGROUPNAME'
        value: resourceGroup().name
      }
      {
        name: 'AKSNAME'
        value: aksName
      }
      {
        name: 'ACRNAME'
        value: acrName
      }
      {
        name: 'EVENTHUB_CONNECTIONSTRING'
        value: eventHubConnectionString
      }
      {
        name: 'STORAGENAME'
        value: storageName
      }
      {
        name: 'STORAGEKEY'
        value: storageKey
      }
      {
        name: 'TAG'
        value: uniqueString(resourceGroup().name)
      }
    ]
  scriptContent: loadTextContent('../deploy.sh')
  cleanupPreference: 'OnSuccess'
  retentionInterval: 'P1D'
  }
}
