# Spotify API Pipeline

### Purpose
I wanted to capture all of my listening data for usage in dashboarding, analysis, and extracting insights. Spotify offers a way to request extended listening history, but this process is rather slow (taking 3-4 weeks to complete) and difficult to automate. This solution offers a real-time view into my listening habits.

This project was also an opportunity to work with a variety of commonly used tools I haven’t had exposure to before. Because of this, this project is rather ‘over-engineered’.


### Prerequisites

* You have an AWS account (I am using the free trial).
* You have installed and logged into AWS CLI (Refer to this [guide](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-sso.html)).
* SSO account is configured. Once AWS CLI is setup, run: `aws configure sso` to establish profile username.
> **Note:**This username should be added to `variable.tf`
* Spotify for developers account & a Spotify API application (Learn more [here](https://developer.spotify.com/documentation/web-api/tutorials/getting-started)).
* Extended listening history (may take 30 days to receive from Spotify). You can use Spotify's [Account Privacy](https://www.spotify.com/us/account/privacy/) page to submit this request.
* You have installed Terraform (You can download [here](https://developer.hashicorp.com/terraform/install?ajs_aid=52acce47-ebbd-459f-932d-f80efaff74a6&product_intent=terraform)).


### Credentials:
* Outline
* Create EC2 instance
* Create and configure PostgreSQL database hosted on EC2 instance
* Create  Lambda function and schedule using AWS CloudEvents
* Insert past listening history from Spotify.
* Connect Database to Google Looker for reporting



### Components
AWS:
* A single EC2 instance containing:
* One database
Two tables (listening_history & track_features)
One CloudEvents instance
One Lambda function with a single layer which will:
Get credentials (Spotify & EC2 Database) from AWS Secrets Manager.
Get recently played tracks from Spotify
Insert recently played tracks into listening history table
Get track analysis of recently played tracks
Insert track analysis into analysis table
Spotify:
A single application
Google Looker
Data:

played_at: Returns time track was played at in UTC timezone.






listening_history Table
Stores information about each track the user has listened to on Spotify, including playback details and track metadata. 
For more information, refer to: https://developer.spotify.com/documentation/web-api/reference/get-recently-played 

Column Name
Data Type
Description
id
SERIAL
Unique identifier for each listening history record.
track_uri
VARCHAR(255)
The unique URI for the track, used as an identifier within Spotify.
Example: “spotify:track:6rqhFgbbKwnb9MLmUQDhG6”
track_name
VARCHAR(255)
The name of the track.
artist_name
VARCHAR(255)
The name of the track's main artist.
album_name
VARCHAR(255)
The name of the album the track is part of.
played_at
TIMESTAMP
The date and time when the track was played; each timestamp is unique to avoid duplicates.
ms_played
INT
The total milliseconds the track was played, representing playback duration.
popularity
INT
The popularity of the track. The value will be between 0 and 100, with 100 being the most popular.
The popularity of a track is a value between 0 and 100, with 100 being the most popular. The popularity is calculated by algorithm and is based, in the most part, on the total number of plays the track has had and how recent those plays are.
Generally speaking, songs that are being played a lot now will have a higher popularity than songs that were played a lot in the past. Duplicate tracks (e.g. the same track from a single and an album) are rated independently. Artist and album popularity is derived mathematically from track popularity. 
Note: the popularity value may lag actual popularity by a few days: the value is not updated in real time.

track_features Table
Stores audio feature data for each unique track, providing insights into the track’s characteristics as analyzed by Spotify.
For more information, refer to: https://developer.spotify.com/documentation/web-api/reference/get-audio-features 

Column Name
Data Type
Description
id
SERIAL
Unique identifier for each track feature record.
track_uri
VARCHAR(255)
The unique URI for the track, ensuring one set of features per track.
Example: “spotify:track:6rqhFgbbKwnb9MLmUQDhG6”
danceability
FLOAT
A measure from 0.0 to 1.0 describing how suitable the track is for dancing, based on tempo, rhythm stability, and more.
energy
FLOAT
A measure from 0.0 to 1.0 representing the intensity and activity of the track.
key
INTEGER
The estimated musical key of the track, encoded as an integer (e.g., 0 = C, 1 = C♯/D♭). 
If no key was detected, the value is -1.
loudness
FLOAT
The overall loudness of the track in decibels (dB), averaged across the entire track.
mode
INTEGER
Indicates the modality of the track, where 1 is major and 0 is minor.
speechiness
FLOAT
A measure from 0.0 to 1.0 describing the presence of spoken words in the track.
acousticness
FLOAT
A confidence measure from 0.0 to 1.0 of whether the track is acoustic.
instrumentalness
FLOAT
Predicts whether a track contains no vocals, with values closer to 1.0 indicating higher confidence in instrumentalness.
liveness
FLOAT
Detects the presence of a live audience in the track; higher values suggest a greater likelihood of live performance.
valence
FLOAT
A measure from 0.0 to 1.0 describing the musical positiveness conveyed by the track. Tracks with high valence sound more positive (e.g. happy, cheerful, euphoric), while tracks with low valence sound more negative (e.g. sad, depressed, angry).
tempo
FLOAT
The overall tempo of the track in beats per minute (BPM).
duration_ms
INTEGER
The track's duration in milliseconds.
time_signature
INTEGER
The estimated time signature of the track, indicating the number of beats per bar (e.g., 4 indicates a 4/4 time).


