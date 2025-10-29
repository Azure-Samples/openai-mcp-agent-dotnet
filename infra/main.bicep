targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@description('Name of the environment that can be used as part of naming resource convention')
param environmentName string

@minLength(1)
@description('Primary location for all resources')
param location string

@minLength(1)
@description('Primary location for Azure AI Foundry resources')
@allowed([
  'australiaeast'
  'eastus'
  'eastus2'
  'japaneast'
  'koreacentral'
  'southindia'
  'swedencentral'
  'switzerlandnorth'
  'uksouth'
])
@metadata({
  azd: {
    type: 'location'
  }
})
param aoaiLocation string

@description('Enable development mode for both MCP server and client')
@allowed([
  'None'
  'Server'
  'Client'
  'Both'
])
param enableDevelopmentMode string

param mcpTodoServerAppExists bool
param mcpTodoClientAppExists bool

@description('Id of the user or app to assign application roles')
param principalId string

@description('Whether to use the built-in login feature for the application or not')
param useLogin bool = true

@description('The SKU for the Azure OpenAI resource')
@allowed([
  'S0'
])
param aoaiSkuName string = 'S0'
@description('Whether to use API Key authentication for Azure OpenAI')
param aoaiUseApiKey bool
@description('GPT model to deploy')
param gptModelName string = 'gpt-5-mini'
@description('GPT model version')
param gptModelVersion string = '2025-08-07'
@description('GPT deployment capacity')
param gptCapacity int = 10

@description('The JWT audience for auth.')
@secure()
param jwtAudience string = ''
@description('The JWT issuer for auth.')
@secure()
param jwtIssuer string = ''
@description('The JWT expiry for auth.')
@secure()
param jwtExpiry string = ''
@description('The JWT secret for auth.')
@secure()
param jwtSecret string = ''
@description('The JWT token for auth.')
@secure()
param jwtToken string = ''

param mcpServerIngressPort int = 3000
param mcpClientIngressPort int = 8080

// Tags that should be applied to all resources.
// 
// Note that 'azd-service-name' tags should be applied separately to service host resources.
// Example usage:
//   tags: union(tags, { 'azd-service-name': <service name in azure.yaml> })
var tags = {
  'azd-env-name': environmentName
}

// Organize resources in a resource group
resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: 'rg-${environmentName}'
  location: location
  tags: tags
}

module resources 'resources.bicep' = {
  scope: rg
  name: 'resources'
  params: {
    environmentName: environmentName
    location: location
    aoaiLocation: aoaiLocation
    tags: tags
    principalId: principalId
    mcpTodoServerAppExists: mcpTodoServerAppExists
    mcpTodoClientAppExists: mcpTodoClientAppExists
    useLogin: useLogin
    aoaiSkuName: aoaiSkuName
    aoaiUseApiKey: aoaiUseApiKey
    gptModelName: gptModelName
    gptModelVersion: gptModelVersion
    gptCapacity: gptCapacity
    jwtAudience: jwtAudience
    jwtIssuer: jwtIssuer
    jwtExpiry: jwtExpiry
    jwtSecret: jwtSecret
    jwtToken: jwtToken
    enableDevelopmentMode: enableDevelopmentMode
    mcpServerIngressPort: mcpServerIngressPort
    mcpClientIngressPort: mcpClientIngressPort
    mcpServerIngressExternal: true
  }
}

output AZURE_PRINCIPAL_ID string = resources.outputs.AZURE_PRINCIPAL_ID

output AZURE_CONTAINER_REGISTRY_ENDPOINT string = resources.outputs.AZURE_CONTAINER_REGISTRY_ENDPOINT

output AZURE_RESOURCE_MCPTODO_SERVERAPP_ID string = resources.outputs.AZURE_RESOURCE_MCPTODO_SERVERAPP_ID
output AZURE_RESOURCE_MCPTODO_SERVERAPP_NAME string = resources.outputs.AZURE_RESOURCE_MCPTODO_SERVERAPP_NAME
output AZURE_RESOURCE_MCPTODO_SERVERAPP_URL string = resources.outputs.AZURE_RESOURCE_MCPTODO_SERVERAPP_URL

output AZURE_RESOURCE_MCPTODO_CLIENTAPP_ID string = resources.outputs.AZURE_RESOURCE_MCPTODO_CLIENTAPP_ID
output AZURE_RESOURCE_MCPTODO_CLIENTAPP_NAME string = resources.outputs.AZURE_RESOURCE_MCPTODO_CLIENTAPP_NAME
output AZURE_RESOURCE_MCPTODO_CLIENTAPP_URL string = resources.outputs.AZURE_RESOURCE_MCPTODO_CLIENTAPP_URL
