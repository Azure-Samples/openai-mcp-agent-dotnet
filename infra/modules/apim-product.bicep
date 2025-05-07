metadata description = 'Creates an Azure API Management product and subscription.'
param name string

param productName string
param productDisplayName string
param productDescription string
param productSubscriptionRequired bool = true

resource apim 'Microsoft.ApiManagement/service@2024-06-01-preview' existing = {
  name: name
}

// Provision APIM product
resource apimProduct 'Microsoft.ApiManagement/service/products@2024-06-01-preview' = {
  name: productName
  parent: apim
  properties: {
    displayName: productDisplayName
    description: productDescription
    state: 'published'
    subscriptionRequired: productSubscriptionRequired
  }
}

output id string = apimProduct.id
output name string = apimProduct.name
