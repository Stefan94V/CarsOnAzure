param appName string
param location string = resourceGroup().location

// storage accounts must be between 3 and 24 characters in length and use numbers and lower-case letters only
var functionAppName = '${appName}${uniqueString(resourceGroup().id)}-fa'
var storageAccountName = '${substring(appName,0,8)}${uniqueString(resourceGroup().id)}-sa' 
var hostingPlanName = '${appName}${uniqueString(resourceGroup().id)}-sa'
var appInsightsName = '${appName}${uniqueString(resourceGroup().id)}-ai'
var keyVaultName = '${appName}${uniqueString(resourceGroup().id)}-kv'
var keyVaultObjectId = guid(appName)

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-09-01' = {
  name: storageAccountName
  location: location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
    tier: 'Standard'
  }
}

resource keyVault 'Microsoft.KeyVault/vaults@2021-10-01' = {
  name:keyVaultName
  location:location
  properties: {
    tenantId: subscription().tenantId
    sku: {
      family: 'A'
      name: 'standard'
    }
    accessPolicies: [
      {
        tenantId: subscription().tenantId
        objectId: keyVaultObjectId
        permissions: {
          secrets: [
            'all'
          ]
          certificates: [
            'all'
          ]
          keys:[
            'all'
          ]
        }
      }
    ]
    enabledForDeployment: true          // VMs can retrieve certificates
    enabledForTemplateDeployment: true  // ARM can retrieve values
    enablePurgeProtection: true         // Not allowing to purge key vault or its objects after deletion
    enableSoftDelete: true              // Deleting a key vault or key/certificate/secret will not remove it completely, but it will be in soft deleted mode for the number of days specified in softDeleteRetentionInDays
    softDeleteRetentionInDays: 7        // Specifies for how long key vault will be kept in soft deleted mode before being deleted permanently
    createMode: 'default'               // Creating or updating the key vault (not recovering)
  }
}

var blobStorageConnectionString = 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${listKeys(storageAccount.id, storageAccount.apiVersion).keys[0].value}'

resource cosmosSecretKey 'Microsoft.KeyVault/vaults/secrets@2021-10-01' = {
  name: '${keyVaultName}/blobStorageConnectionString'
  properties: {
    value: blobStorageConnectionString
  }
}

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: location
  kind: 'web'
  properties: { 
    Application_Type: 'web'
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
  tags: {
    // circular dependency means we can't reference functionApp directly  /subscriptions/<subscriptionId>/resourceGroups/<rg-name>/providers/Microsoft.Web/sites/<appName>"
     'hidden-link:/subscriptions/${subscription().id}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Web/sites/${functionAppName}': 'Resource'
  }
}

resource hostingPlan 'Microsoft.Web/serverfarms@2020-10-01' = {
  name: hostingPlanName
  location: location
  sku: {
    name: 'Y1' 
    tier: 'Dynamic'
  }
}

resource functionApp 'Microsoft.Web/sites@2021-03-01' = {
  name: functionAppName
  location: location
  kind: 'functionapp'
  properties: {
    httpsOnly: true
    serverFarmId: hostingPlan.id
    clientAffinityEnabled: true
    siteConfig: {
      appSettings: [
        {
          'name': 'APPINSIGHTS_INSTRUMENTATIONKEY'
          'value': appInsights.properties.InstrumentationKey
        }
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${listKeys(storageAccount.id, storageAccount.apiVersion).keys[0].value}'
        }
        {
          'name': 'FUNCTIONS_EXTENSION_VERSION'
          'value': '~3'
        }
        {
          'name': 'FUNCTIONS_WORKER_RUNTIME'
          'value': 'dotnet'
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${listKeys(storageAccount.id, storageAccount.apiVersion).keys[0].value}'
        }
        // WEBSITE_CONTENTSHARE will also be auto-generated - https://docs.microsoft.com/en-us/azure/azure-functions/functions-app-settings#website_contentshare
        // WEBSITE_RUN_FROM_PACKAGE will be set to 1 by func azure functionapp publish
      ]
    }
  }

  dependsOn: [
    appInsights
    hostingPlan
    storageAccount
    keyVault
  ]
}

output functionAppName string = functionApp.name
