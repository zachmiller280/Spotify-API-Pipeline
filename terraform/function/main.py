import urllib3
import json
from urllib.parse import urlencode
import os
import logging
import boto3
from botocore.exceptions import ClientError

import psycopg2 # type: ignore # Package used for interacting with PostgreSQL db

logger = logging.getLogger()
logger.setLevel('INFO')

aws_region = os.environ['aws_region']
secrets_name = os.environ['secret_name'] 


def get_secret():
    secret_name = secrets_name
    region_name = aws_region

    # Create a Secrets Manager client
    session = boto3.session.Session()
    client = session.client(
        service_name='secretsmanager',
        region_name=region_name
    )

    try:
        get_secret_value_response = client.get_secret_value(SecretId=secret_name)
    except ClientError as e:
        # For a list of exceptions thrown, see
        # https://docs.aws.amazon.com/secretsmanager/latest/apireference/API_GetSecretValue.html
        raise e
    secret = json.loads(get_secret_value_response['SecretString'])
    
    return secret
    
    
def lambda_handler(event, context):
    credential = get_secret() # Get secret from AWS Secrets Manager

    SPOTIFY_CLIENT_ID = credential['SPOTIFY_CLIENT_ID']
    SPOTIFY_CLIENT_SECRET = credential['SPOTIFY_CLIENT_SECRET']
    SPOTIFY_REFRESH_TOKEN  = credential['SPOTIFY_REFRESH_TOKEN']
    HOST_IP  = credential['HOST_IP']
    DB_NAME  = credential['DB_NAME']
    DB_USER_NAME  = credential['DB_USER_NAME']
    DB_USER_PASSWORD  = credential['DB_USER_PASSWORD']

    """Retrieve the user's recent listening history from Spotify and store it in a PostgreSQL database."""
    # Initialize a PoolManager instance
    http = urllib3.PoolManager()

    # Define the URL for the token refresh endpoint
    url = 'https://accounts.spotify.com/api/token'

    # Define the headers
    headers = {
        'Content-Type': 'application/x-www-form-urlencoded'
    }

    # Define the payload with the required parameters
    payload = {
        'client_id': SPOTIFY_CLIENT_ID,
        'client_secret': SPOTIFY_CLIENT_SECRET,
        'refresh_token': SPOTIFY_REFRESH_TOKEN,
        'grant_type': 'refresh_token'
    }

    # Encode the payload
    encoded_payload = urlencode(payload)

    # Make the POST request
    response = http.request(
        'POST',
        url,
        body=encoded_payload,
        headers=headers
    )
    # Parse the response
    response_data = json.loads(response.data.decode('utf-8'))
    access_token =  response_data['access_token']

    # Retrieve the recently played tracks
    response = http.request(
        "GET",
        "https://api.spotify.com/v1/me/player/recently-played?limit=50",
        headers={
            "Authorization": f"Bearer {access_token}",
            "Content-Type": "application/json",
        },
    )

    # Parse the response to get the recently played tracks
    results = json.loads(response.data.decode('utf-8'))

    # Establishing connection to database
    conn = psycopg2.connect(
        host= HOST_IP,
        database=DB_NAME,
        user=DB_USER_NAME,
        password=DB_USER_PASSWORD,
        port = '5432'
    )
    cur = conn.cursor()

    tracks_count = 0
    for track in results["items"]:
        track_uri = track["track"]["uri"]
        track_name = track["track"]["name"]
        album_name = track["track"]["album"]["name"]
        artist_name = track["track"]["artists"][0]["name"]
        played_at = track["played_at"]
        ms_played = track["track"]["duration_ms"]
        popularity = track["track"]["popularity"]
        
        cur.execute(
            """INSERT INTO listening_history (track_uri, track_name, artist_name, album_name, played_at, ms_played, popularity)
            VALUES (%s, %s, %s, %s, %s, %s, %s) 
            ON CONFLICT (played_at) DO NOTHING""",
            (track_uri, track_name, artist_name, album_name, played_at, ms_played, popularity),
        )
        tracks_count += 1
        logger.info("Added %s by %s to Postgres DB" %(track_name,artist_name))

    conn.commit()
    conn.close()
    logger.info("Successfully added %d tracks to the Postgres DB" %(tracks_count))
    
    
    # Fetches audio features of my recently played tracks
    def get_track_features(results):
      # Extract track IDs
      track_ids = [item['track']['id'] for item in results['items']]
      ids_string = "%2C".join(track_ids)
    
      # Retrieve the audio features of recently played tracks
      response = http.request(
          "GET",
          "https://api.spotify.com/v1/audio-features?ids= {}".format(ids_string),
          headers={
              "Authorization": f"Bearer {access_token}",
              "Content-Type": "application/json",
          },
      )
      audio_feature_results = json.loads(response.data.decode('utf-8'))['audio_features']
    
      features_filtered = []
      for i in range(len(audio_feature_results)):
        track = audio_feature_results[i]
        # Ensure all required fields are present and not None
        required_fields = [
            'uri', 'danceability', 'energy', 'key', 'loudness', 'mode', 
            'speechiness', 'acousticness', 'instrumentalness', 'liveness', 
            'valence', 'tempo', 'duration_ms', 'time_signature'
        ]
        
        if track is None:
          continue
        elif all(field in track for field in required_fields):
          features_filtered.append(track)
        else:
          continue   
      return features_filtered
    
    # Insert track features into PostgreSQL database
    def insert_track_features(features):
        conn = None
        conn = psycopg2.connect(
            host=HOST_IP,
            database=DB_NAME,
            user=DB_USER_NAME,
            password=DB_USER_PASSWORD,)
    
        for track in features:
          track_uri = track['uri']
          danceability = track['danceability']
          energy=  track['energy']
          key =  track['key']
          loudness =  track['loudness']
          mode =  track['mode']
          speechiness =  track['speechiness']
          acousticness =  track['acousticness']
          instrumentalness =  track['instrumentalness']
          liveness =  track['liveness']
          valence =  track['valence']
          tempo =  track['tempo']
          duration_ms =  track['duration_ms']
          time_signature =  track['time_signature']
          cur = conn.cursor()
          cur.execute(
              """INSERT INTO track_features (track_uri, danceability, energy, key, loudness, mode, speechiness, acousticness, instrumentalness, liveness, valence, tempo, duration_ms, time_signature)
              VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
              ON CONFLICT (track_uri) DO NOTHING""",
              (track_uri, danceability, energy, key, loudness, mode, speechiness, acousticness, instrumentalness, liveness, valence, tempo, duration_ms, time_signature),
          )
        conn.commit()
        cur.close()
    
    try:
        insert_track_features(get_track_features(results))
        return {
            'statusCode': 200,
            'body': 'Successfully added %d tracks to the Postgres DB' %(tracks_count)
        }

    except:
        return {
            'statusCode': 400,
            'body': 'Error: Failed to retrieve Track Features'
        }
