extension microsoftGraphV1

param containerAppIdentityId string

param appName string
param appDisplayName string = appName

param issuer string

param containerAppEndpoint string

var identifierId = guid(appName)

var groupClaim = {
  name: 'groups'
  essential: false
  additionalProperties: [
    'emit_as_roles'
  ]
  source: null
}

resource app 'Microsoft.Graph/applications@v1.0' = {
  uniqueName: appName
  displayName: appDisplayName
  web: {
    redirectUris: [
      '${containerAppEndpoint}/.auth/login/aad/callback'
    ]
    implicitGrantSettings: {
      enableIdTokenIssuance: true
    }
  }
  api: {
    requestedAccessTokenVersion: 2
    oauth2PermissionScopes: [
      {
        id: identifierId
        type: 'User'
        isEnabled: true
        value: 'user_impersonation'
        adminConsentDisplayName: 'Access as the signed-in user'
        adminConsentDescription: 'Access as the signed-in user'
      }
    ]
  }
  requiredResourceAccess: [
    {
      resourceAppId: '00000003-0000-0000-c000-000000000000'
      resourceAccess: [
        // email
        { id: '64a6cdd6-aab1-4aaf-94b8-3cc8405e90d0', type: 'Scope' }
        // offline_access
        { id: '7427e0e9-2fba-42fe-b0c0-848c9e6a8182', type: 'Scope' }
        // openid
        { id: '37f7f235-527c-4136-accd-4a02d197296e', type: 'Scope' }
        // profile
        { id: '14dad69e-099b-42c9-810b-d002981feec1', type: 'Scope' }
      ]
    }
  ]
  optionalClaims: {
    accessToken: [
      groupClaim
    ]
    saml2Token: [
      groupClaim
    ]
    idToken: [
      groupClaim
    ]
  }
  groupMembershipClaims: 'SecurityGroup'

  resource appFicContainerApp 'federatedIdentityCredentials@v1.0' = {
    name: '${app.uniqueName}/fic-containerapp'
    issuer: issuer
    subject: containerAppIdentityId
    audiences: [
      'api://AzureADTokenExchange'
    ]
  }
}

resource sp 'Microsoft.Graph/servicePrincipals@v1.0' = {
  appId: app.appId
}

output appId string = app.appId
output spId string = sp.id
