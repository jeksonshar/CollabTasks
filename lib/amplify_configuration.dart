/// Amplify configuration for AWS Cognito.
///
/// Replace placeholder values with your real:
/// - region
/// - userPoolId
/// - userPoolClientId
const String amplifyConfig = '''
{
  "auth": {
    "plugins": {
      "awsCognitoAuthPlugin": {
        "UserAgent": "aws-amplify-cli/2.0",
        "Version": "0.1.0",
        "IdentityManager": {
          "Default": {}
        },
        "CognitoUserPool": {
          "Default": {
            "PoolId": "eu-north-1_gG4RPjCTa",
            "AppClientId": "67n1ier0tol0fmsfbmg2bur2c0",
            "Region": "eu-north-1"
          }
        },
        "Auth": {
          "Default": {
            "authenticationFlowType": "USER_SRP_AUTH",
            "socialProviders": [
              "GOOGLE"
            ],
            "usernameAttributes": [
              "EMAIL"
            ],
            "signupAttributes": [
              "EMAIL"
            ],
            "passwordProtectionSettings": {
              "passwordPolicyMinLength": 8,
              "passwordPolicyCharacters": []
            },
            "mfaConfiguration": "OFF",
            "mfaTypes": [
              "SMS"
            ],
            "verificationMechanisms": [
              "EMAIL"
            ],
            "OAuth": {
              "WebDomain": "eu-north-1gg4rpjcta.auth.eu-north-1.amazoncognito.com",
              "AppClientId": "67n1ier0tol0fmsfbmg2bur2c0",
              "SignInRedirectURI": "collabtasks://",
              "SignOutRedirectURI": "collabtasks://",
              "Scopes": [
                "phone",
                "email",
                "openid",
                "profile",
                "aws.cognito.signin.user.admin"
              ]
            }
          }
        }
      }
    }
  }
}
''';
