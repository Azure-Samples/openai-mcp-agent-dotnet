metadata description = 'Creates an API on Azure API Management instance.'
param name string

param productName string = 'default'

param apiName string
param apiDisplayName string
param apiDescription string
param apiServiceUrl string
param apiPath string
param apiSubscriptionRequired bool = true

@allowed([
  'graphql'
  'grpc'
  'http'
  'odata'
  'soap'
  'websocket'
])
param apiType string = 'http'

@allowed([
  'graphql-link'
  'grpc'
  'grpc-link'
  'odata'
  'odata-link'
  'openapi'
  'openapi+json'
  'openapi+json-link'
  'openapi-link'
  'swagger-json'
  'swagger-link-json'
  'wadl-link-json'
  'wadl-xml'
  'wsdl'
  'wsdl-link'
])
param apiFormat string = 'openapi-link'
param apiValue string

resource apim 'Microsoft.ApiManagement/service@2024-06-01-preview' existing = {
  name: name
}

// Provision APIM API
resource apimApi 'Microsoft.ApiManagement/service/apis@2024-06-01-preview' = {
  name: apiName
  parent: apim
  properties: {
    type: apiType
    displayName: apiDisplayName
    description: apiDescription
    serviceUrl: apiServiceUrl
    path: apiPath
    protocols: [
      'https'
    ]
    subscriptionRequired: apiSubscriptionRequired
    subscriptionKeyParameterNames: {
      header: 'subscription-key'
      query: 'api-key'
    }
    // format: apiFormat
    // value: apiValue
  }
}

resource apimProduct 'Microsoft.ApiManagement/service/products@2024-06-01-preview' existing = {
  name: productName
  parent: apim
}

// Link API to product
resource apimProductApi 'Microsoft.ApiManagement/service/products/apis@2024-06-01-preview' = {
  name: apiName
  parent: apimProduct
  dependsOn: [
    apimApi
  ]
}

// Add SSE operation to the API
resource mcpSseOperation 'Microsoft.ApiManagement/service/apis/operations@2024-06-01-preview' = {
  name: 'mcp-sse'
  parent: apimApi
  properties: {
    displayName: 'MCP SSE Endpoint'
    method: 'GET'
    urlTemplate: '/sse'
    description: 'Server-Sent Events endpoint for MCP Server'
  }
}

// Add Message operation to the API
resource mcpMessageOperation 'Microsoft.ApiManagement/service/apis/operations@2024-06-01-preview' = {
  name: 'mcp-message'
  parent: apimApi
  properties: {
    displayName: 'MCP Message Endpoint'
    method: 'POST'
    urlTemplate: '/message'
    description: 'Message endpoint for MCP Server'
  }
}
