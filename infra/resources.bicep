@description('Name of the environment that can be used as part of naming resource convention')
param environmentName string

@description('The location used for all deployed resources')
param location string = resourceGroup().location

@description('Tags that will be applied to all resources')
param tags object = {}

param mcpTodoClientAppExists bool
param mcpTodoServerAppExists bool

@description('Id of the user or app to assign application roles')
param principalId string

@description('Whether to use the built-in login feature for the application or not')
param useLogin bool = true

@description('Whether to use API Management or not')
param useApiManagement bool = false

@description('The connection string to OpenAI.')
@secure()
param openAIConnectionString string

var abbrs = loadJsonContent('./abbreviations.json')
var resourceToken = uniqueString(subscription().id, resourceGroup().id, location)

// Monitor application with Azure Monitor
module monitoring 'br/public:avm/ptn/azd/monitoring:0.1.0' = {
  name: 'monitoring'
  params: {
    logAnalyticsName: '${abbrs.operationalInsightsWorkspaces}${resourceToken}'
    applicationInsightsName: '${abbrs.insightsComponents}${resourceToken}'
    applicationInsightsDashboardName: '${abbrs.portalDashboards}${resourceToken}'
    location: location
    tags: tags
  }
}

// Storage account
module storageAccount 'br/public:avm/res/storage/storage-account:0.15.0' = if (useLogin == true) {
  name: 'storageAccount'
  params: {
    name: '${abbrs.storageStorageAccounts}${resourceToken}'
    kind: 'StorageV2'
    location: location
    tags: tags
    skuName: 'Standard_LRS'
    blobServices: {
      containers: [
        {
          name: 'token-store'
          publicAccess: 'None'
        }
      ]
    }
  }
}

// API Management
module apiManagement 'br/public:avm/res/api-management/service:0.9.1' = if (useApiManagement == true) {
  name: 'apimanagement'
  params: {
    name: '${abbrs.apiManagementService}${resourceToken}'
    location: location
    tags: tags
    publisherName: 'MCP Todo Agent'
    publisherEmail: 'mcp-todo@contoso.com'
    sku: 'BasicV2'
    skuCapacity: 1
    managedIdentities: {
      systemAssigned: false
      userAssignedResourceIds: [
        mcpTodoClientAppIdentity.outputs.resourceId
      ]
    }
  }
}

module apimProduct './modules/apim-product.bicep' = if (useApiManagement == true) {
  name: 'apimanagement-product'
  params: {
    name: apiManagement.outputs.name
    productName: 'default'
    productDisplayName: 'default'
    productDescription: 'Default product'
    productSubscriptionRequired: false
  }
}

module apimSubscription './modules/apim-subscription.bicep' = if (useApiManagement == true) {
  name: 'apimanagement-subscription'
  params: {
    name: apiManagement.outputs.name
    productName: apimProduct.outputs.name
    subscriptionName: 'default'
    subscriptionDisplayName: 'Default subscription'
  }
}

module apimApi './modules/apim-api.bicep' = if (useApiManagement == true) {
  name: 'apimanagement-api'
  params: {
    name: apiManagement.outputs.name
    apiName: 'mcp-server'
    apiDisplayName: 'MCP Server'
    apiDescription: 'API for MCP Server'
    apiServiceUrl: 'https://${mcpTodoServerApp.outputs.fqdn}'
    apiPath: 'mcp-server'
    apiSubscriptionRequired: false
    apiFormat: 'openapi+json'
    apiValue: loadTextContent('./apis/openapi.json')
  }
  dependsOn: [
    apimProduct
  ]
}

// Container registry
module containerRegistry 'br/public:avm/res/container-registry/registry:0.6.0' = {
  name: 'registry'
  params: {
    name: '${abbrs.containerRegistryRegistries}${resourceToken}'
    location: location
    tags: tags
    acrAdminUserEnabled: true
    exportPolicyStatus: 'enabled'
    publicNetworkAccess: 'Enabled'
    roleAssignments: [
      {
        principalId: mcpTodoServerAppIdentity.outputs.principalId
        principalType: 'ServicePrincipal'
        // ACR Pull role
        roleDefinitionIdOrName: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d')
      }
      {
        principalId: mcpTodoClientAppIdentity.outputs.principalId
        principalType: 'ServicePrincipal'
        // ACR Pull role
        roleDefinitionIdOrName: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d')
      }
    ]
  }
}

// Container apps environment
module containerAppsEnvironment 'br/public:avm/res/app/managed-environment:0.8.1' = {
  name: 'container-apps-environment'
  params: {
    logAnalyticsWorkspaceResourceId: monitoring.outputs.logAnalyticsWorkspaceResourceId
    name: '${abbrs.appManagedEnvironments}${resourceToken}'
    location: location
    zoneRedundant: false
  }
}

module mcpTodoServerAppIdentity 'br/public:avm/res/managed-identity/user-assigned-identity:0.4.0' = {
  name: 'mcpTodoServerAppIdentity'
  params: {
    name: '${abbrs.managedIdentityUserAssignedIdentities}mcptodoserverapp-${resourceToken}'
    location: location
  }
}

module mcpTodoServerAppIdentityRoleAssignment './modules/role-assignment.bicep' = if (useLogin == true) {
  name: 'mcpTodoServerAppIdentityRoleAssignment'
  params: {
    managedIdentityName: mcpTodoServerAppIdentity.outputs.name
    storageAccountName: storageAccount.outputs.name
    principalType: 'ServicePrincipal'
  }
}

module mcpTodoServerAppFetchLatestImage './modules/fetch-container-image.bicep' = {
  name: 'mcptodo-serverapp-fetch-image'
  params: {
    exists: mcpTodoServerAppExists
    name: 'mcptodo-serverapp'
  }
}

module mcpTodoServerApp 'br/public:avm/res/app/container-app:0.16.0' = {
  name: 'mcpTodoServerApp'
  params: {
    name: 'mcptodo-serverapp'
    ingressTargetPort: 3000
    ingressExternal: false
    scaleSettings: {
      minReplicas: 1
      maxReplicas: 10
    }
    secrets: [
    ]
    containers: [
      {
        image: mcpTodoServerAppFetchLatestImage.outputs.?containers[?0].?image ?? 'mcr.microsoft.com/azuredocs/containerapps-helloworld:latest'
        name: 'main'
        resources: {
          cpu: json('0.5')
          memory: '1.0Gi'
        }
        env: [
          {
            name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
            value: monitoring.outputs.applicationInsightsConnectionString
          }
          {
            name: 'AZURE_CLIENT_ID'
            value: mcpTodoServerAppIdentity.outputs.clientId
          }
          {
            name: 'PORT'
            value: '3000'
          }
        ]
      }
    ]
    managedIdentities: {
      systemAssigned: false
      userAssignedResourceIds: [
        mcpTodoServerAppIdentity.outputs.resourceId
      ]
    }
    registries: [
      {
        server: containerRegistry.outputs.loginServer
        identity: mcpTodoServerAppIdentity.outputs.resourceId
      }
    ]
    environmentResourceId: containerAppsEnvironment.outputs.resourceId
    location: location
    tags: union(tags, { 'azd-service-name': 'mcptodo-serverapp' })
  }
}

module mcpTodoClientAppIdentity 'br/public:avm/res/managed-identity/user-assigned-identity:0.4.0' = {
  name: 'mcpTodoClientAppIdentity'
  params: {
    name: '${abbrs.managedIdentityUserAssignedIdentities}mcptodoclientapp-${resourceToken}'
    location: location
  }
}

module mcpTodoClientAppIdentityRoleAssignment './modules/role-assignment.bicep' = if (useLogin == true) {
  name: 'mcpTodoClientAppIdentityRoleAssignment'
  params: {
    managedIdentityName: mcpTodoClientAppIdentity.outputs.name
    storageAccountName: storageAccount.outputs.name
    principalType: 'ServicePrincipal'
  }
}

module mcpTodoClientAppFetchLatestImage './modules/fetch-container-image.bicep' = {
  name: 'mcptodo-clientapp-fetch-image'
  params: {
    exists: mcpTodoClientAppExists
    name: 'mcptodo-clientapp'
  }
}

module mcpTodoClientApp 'br/public:avm/res/app/container-app:0.16.0' = {
  name: 'mcpTodoClientApp'
  params: {
    name: 'mcptodo-clientapp'
    ingressTargetPort: 8080
    ingressExternal: true
    scaleSettings: {
      minReplicas: 1
      maxReplicas: 10
    }
    secrets: [
      {
        name: 'connectionstrings-openai'
        value: openAIConnectionString
      }
    ]
    containers: [
      {
        image: mcpTodoClientAppFetchLatestImage.outputs.?containers[?0].?image ?? 'mcr.microsoft.com/azuredocs/containerapps-helloworld:latest'
        name: 'main'
        resources: {
          cpu: json('0.5')
          memory: '1.0Gi'
        }
        env: [
          {
            name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
            value: monitoring.outputs.applicationInsightsConnectionString
          }
          {
            name: 'AZURE_CLIENT_ID'
            value: mcpTodoClientAppIdentity.outputs.clientId
          }
          {
            name: 'PORT'
            value: '8080'
          }
          {
            name: 'McpServers__TodoList'
            value: useApiManagement ? 'https://${apiManagement.outputs.name}.azure-api.net' : 'https://${mcpTodoServerApp.outputs.fqdn}'
          }
          {
            name: 'ConnectionStrings__OpenAI'
            secretRef: 'connectionstrings-openai'
          }
        ]
      }
    ]
    managedIdentities: {
      systemAssigned: false
      userAssignedResourceIds: [
        mcpTodoClientAppIdentity.outputs.resourceId
      ]
    }
    registries: [
      {
        server: containerRegistry.outputs.loginServer
        identity: mcpTodoClientAppIdentity.outputs.resourceId
      }
    ]
    environmentResourceId: containerAppsEnvironment.outputs.resourceId
    location: location
    tags: union(tags, { 'azd-service-name': 'mcptodo-clientapp' })
  }
}

// EasyAuth
var issuer = '${environment().authentication.loginEndpoint}${tenant().tenantId}/v2.0'

module appRegistration './modules/app-registration.bicep' = if (useLogin == true) {
  name: 'appRegistration'
  params: {
    appName: 'spn-${environmentName}'
    issuer: issuer
    containerAppIdentityId: mcpTodoClientAppIdentity.outputs.principalId
    containerAppEndpoint: 'https://${mcpTodoClientApp.outputs.fqdn}'
  }
}

module mcpTodoClientAppAuthConfig './modules/containerapps-authconfigs.bicep' = if (useLogin == true) {
  name: 'mcpTodoClientAppAuthConfig'
  params: {
    containerAppName: mcpTodoClientApp.outputs.name
    managedIdentityName: mcpTodoClientAppIdentity.outputs.name
    storageAccountName: storageAccount.outputs.name
    clientId: appRegistration.outputs.appId
    openIdIssuer: issuer
    unauthenticatedClientAction: 'RedirectToLoginPage'
  }
}

output AZURE_PRINCIPAL_ID string = useLogin ? appRegistration.outputs.appId : ''

output AZURE_CONTAINER_REGISTRY_ENDPOINT string = containerRegistry.outputs.loginServer

output AZURE_RESOURCE_MCPTODO_SERVERAPP_ID string = mcpTodoServerApp.outputs.resourceId
output AZURE_RESOURCE_MCPTODO_SERVERAPP_NAME string = mcpTodoServerApp.outputs.name
output AZURE_RESOURCE_MCPTODO_SERVERAPP_URL string = 'https://${mcpTodoServerApp.outputs.fqdn}'

output AZURE_RESOURCE_MCPTODO_CLIENTAPP_ID string = mcpTodoClientApp.outputs.resourceId
output AZURE_RESOURCE_MCPTODO_CLIENTAPP_NAME string = mcpTodoClientApp.outputs.name
output AZURE_RESOURCE_MCPTODO_CLIENTAPP_URL string = 'https://${mcpTodoClientApp.outputs.fqdn}'
