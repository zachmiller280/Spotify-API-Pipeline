# This code snippet demonstrates how to obtain a refresh token using the authorization code flow.
# The refresh token is obtained through an intermediary step of authorization.

import requests

# Replace with your actual Spotify API credentials from userdata
client_id ='SPOTIFY_CLIENT_ID'
client_secret = 'SPOTIFY_CLIENT_SECRET'
redirect_uri = 'SPOTIFY_REDIRECT_URI'


# 1. Authorization Code Request
# Construct the authorization URL.  Replace with appropriate scope.
auth_url = (
    'https://accounts.spotify.com/authorize?'
    f'client_id={client_id}&'
    'response_type=code&'
    f'redirect_uri={redirect_uri}&'
    'scope=user-read-recently-played' # Example scope
)
print(f"Please visit this URL to authorize the app: {auth_url}")

# 2. User Authorization and Code Retrieval
authorization_code = input("Enter the authorization code from the redirect URL: ")


# 3. Access Token Request (using the Authorization Code)
token_url = 'https://accounts.spotify.com/api/token'
data = {
    'grant_type': 'authorization_code',
    'code': authorization_code,
    'redirect_uri': redirect_uri,
    'client_id': client_id,
    'client_secret': client_secret
}
response = requests.post(token_url, data=data)
response.raise_for_status() # Raise an exception for bad status codes (4xx or 5xx)
token_info = response.json()

# 4. Extract Refresh Token
refresh_token = token_info.get('refresh_token')
if refresh_token:
  print(f"Your refresh token is: {refresh_token}")
else:
  print("Error: Refresh token not found in the response.")

# Store the refresh token securely for later use.