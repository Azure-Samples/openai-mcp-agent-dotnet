@allowed([
  'Device'
  'ForeignGroup'
  'Group'
  'ServicePrincipal'
  'User'
])
param principalType string = 'ServicePrincipal'
param roleDefinitions array = [
  {
    id: 'ba92f5b4-2d11-453d-a403-e96b0029c9fe'
    name: 'Storage Blob Data Contributor'
  }
]

param managedIdentityName string
param storageAccountName string

resource userAssignedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = {
  name: managedIdentityName
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' existing = {
  name: storageAccountName
}

resource roles 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for roleDefinition in roleDefinitions: {
  name: guid(subscription().id, resourceGroup().id, managedIdentityName, roleDefinition.id)
  scope: storageAccount
  properties: {
    principalId: userAssignedIdentity.properties.principalId
    principalType: principalType
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', roleDefinition.id)
  }
}]
