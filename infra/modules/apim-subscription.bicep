metadata description = 'Creates an Azure API Management subscription.'
param name string
param productName string

param subscriptionName string
param subscriptionDisplayName string

resource apim 'Microsoft.ApiManagement/service@2024-06-01-preview' existing = {
  name: name
}

// Provision APIM product
resource apimProduct 'Microsoft.ApiManagement/service/products@2024-06-01-preview' existing = {
  name: productName
  parent: apim
}

// Provision APIM subscription belongs to the product
resource apimSubscription 'Microsoft.ApiManagement/service/subscriptions@2024-06-01-preview' = {
  name: subscriptionName
  parent: apim
  properties: {
    displayName: subscriptionDisplayName
    scope: apimProduct.id
  }
}
