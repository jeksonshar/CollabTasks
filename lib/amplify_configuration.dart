/// Amplify configuration for AWS Cognito, API, and Storage.
///
/// Replace placeholder values with your real:
/// - region
/// - userPoolId
/// - userPoolClientId
/// - bucket
/// - ApiUrl
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
            "PoolId": "eu-central-1_eFhEsK3Fo",
            "AppClientId": "1lr13oaa6tp4cv7kdrqevmbbmh",
            "Region": "eu-central-1"
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
              "WebDomain": "collabtasks-app.auth.eu-central-1.amazoncognito.com",
              "AppClientId": "1lr13oaa6tp4cv7kdrqevmbbmh",
              "SignInRedirectURI": "http://localhost:3000/,collabtasks://callback/",
              "SignOutRedirectURI": "http://localhost:3000/,collabtasks://callback/",
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
  },
  "storage": {
    "plugins": {
      "awsS3StoragePlugin": {
        "bucket": "amplify-collabtasks-admin-collabtasksfilesbucket2f-rgwyq1xzyhmd",
        "region": "eu-central-1",
        "defaultAccessLevel": "guest"
      }
    }
  },
  "api": {
    "plugins": {
      "awsAppSyncApiPlugin": {
        "Default": {
          "ApiUrl": "https://jgj2ctj7njgq5bl34jvmtxlyjq.appsync-api.eu-central-1.amazonaws.com/graphql",
          "Region": "eu-central-1",
          "AuthMode": "AMAZON_COGNITO_USER_POOLS"
        }
      }
    }
  }
}
''';
