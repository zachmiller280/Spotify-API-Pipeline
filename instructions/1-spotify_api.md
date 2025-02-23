## Spotify Web API

We will be utilizing [Spotify's Web API](https://developer.spotify.com/documentation/web-api) to extract our listening history. Primarily, we will use the `./player/recently-played` endpoint to retrieve your most recently listened to tracks. 

To get started, we first need to create a Spotify API application. To do this we must:
1. Sign into Spotify for Developers account
1. Navigate to your [dashboard](https://developer.spotify.com/dashboard)
1. Create new application
    * Note: For `Redirect URIs` I am using: http://localhost:8888/callback  
1. Go to your new app's settings and capture your `Client ID` and `Client Secret`


Next, we need to retrieve your Spotify refresh token. Because Spotify API access tokens are only valid for 1 hour, each time we run this function, we will need to generate a fresh access token using our refresh token. We will store this refresh token and then used each time our Lambda function is ran.

By using our app's Redirect URI, Client ID, and Client Secret, we can retrieve our `Spotify Refresh Token`. There are a variety of methods to retrieve your refresh token, but I have gone ahead and included a Python script that should simplify this process.

> You can find this script here: [instructions\code_snippets\get_spotify_refresh_token.py](instructions\code_snippets\get_spotify_refresh_token.py)

