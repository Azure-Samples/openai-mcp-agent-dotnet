@allowed([
  'Device'
  'ForeignGroup'
  'Group'
  'ServicePrincipal'
  'User'
])
param principalType string = 'ServicePrincipal'
param storageRoleDefinitions array = [
  {
    id: 'ba92f5b4-2d11-453d-a403-e96b0029c9fe'
    name: 'Storage Blob Data Contributor'
  }
]
param aifRoleDefinitions array = [
  {
    id: '5e0bd9bd-7b93-4f28-af87-19fc36ad61bd'
    name: 'Cognitive Services OpenAI User'
  }
]

param managedIdentityName string
param storageAccountName string = ''
param aifAccountName string = ''

resource userAssignedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = {
  name: managedIdentityName
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' existing = if (storageAccountName != '' ) {
  name: storageAccountName
}

resource storageRoles 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for roleDefinition in storageRoleDefinitions: if (storageAccountName != '' ) {
  name: guid(subscription().id, resourceGroup().id, managedIdentityName, roleDefinition.id)
  scope: storageAccount
  properties: {
    principalId: userAssignedIdentity.properties.principalId
    principalType: principalType
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', roleDefinition.id)
  }
}]

resource aifAccount 'Microsoft.CognitiveServices/accounts@2025-07-01-preview' existing = if (aifAccountName != '' ) {
  name: aifAccountName
}

resource aifRoles 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for roleDefinition in aifRoleDefinitions: if (aifAccountName != '' ) {
  name: guid(subscription().id, resourceGroup().id, managedIdentityName, roleDefinition.id)
  scope: aifAccount
  properties: {
    principalId: userAssignedIdentity.properties.principalId
    principalType: principalType
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', roleDefinition.id)
  }
}]
