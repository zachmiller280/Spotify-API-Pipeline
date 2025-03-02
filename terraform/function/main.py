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