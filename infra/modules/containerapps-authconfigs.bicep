param containerAppName string
param managedIdentityName string
param storageAccountName string

@description('The client ID of the Microsoft Entra application.')
param clientId string

param openIdIssuer string

@allowed([
  'AllowAnonymous'
  'RedirectToLoginPage'
  'Return401'
  'Return403'
])
param unauthenticatedClientAction string = 'RedirectToLoginPage'


resource containerapp 'Microsoft.App/containerApps@2024-10-02-preview' existing = {
  name: containerAppName
}

resource userAssignedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = {
  name: managedIdentityName
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' existing = {
  name: storageAccountName
}

resource containerappAuthConfig 'Microsoft.App/containerApps/authConfigs@2024-10-02-preview' = {
  name: 'current'
  parent: containerapp
  properties: {
    platform: {
      enabled: true
    }
    globalValidation: {
      unauthenticatedClientAction: unauthenticatedClientAction
      redirectToProvider: 'AzureActiveDirectory'
    }
    identityProviders: {
      azureActiveDirectory: {
        enabled: true
        registration: {
          clientId: clientId
          openIdIssuer: openIdIssuer
        }
        validation: {
          defaultAuthorizationPolicy: {
            allowedApplications: [
              clientId
            ]
          }
        }
      }
    }
    login: {
      tokenStore: {
        enabled: true
        azureBlobStorage: {
          blobContainerUri: '${storageAccount.properties.primaryEndpoints.blob}/token-store'
          managedIdentityResourceId: userAssignedIdentity.id
        }
      }
    }
  }
}
