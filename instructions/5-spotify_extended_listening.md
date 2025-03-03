# Spotify Extended Listening History

Congrats, you are now collecting your Spotify listening data in (near) real-time! However, ideally our database would also contain our complete listening history since the account was created. Thankfully, this is quite simple to accomplish, as Spotify has a feature which allows users to request their extended listening history. 

## How to request your data
1. Go to **https://www.spotify.com/us/account/privacy/**
1. Request **Extended streaming history**
1. Confirm your request

Once your data request has been completed, you will receive several files in JSON format. 

Now we will conduct some preprocessing to consolidate these JSON files, prepare the data, and then insert the historical data into our database.


## How to insert your data

At a high-level, there are a few things we need to do before this data is ready to be inserted into our database.

1. Combine all JSON files into a single table.
1. Limit the columns to those we are interested in.
1. Filter out nulls or tracks that were'nt actually played.
1. Optional - Adjust records with duplicate timestamps so that all timestamps are unique.
1. Insert records into listening history table.

I have provided a Jupyter notebook which will help guide you through this process. 
This notebook can be found at [./instructions/code_snippets/spotifyPostgresInsert.ipynb](code_snippets/spotifyPostgresInsert.ipynb)



### Table of Contents
0. [Project Overview](https://github.com/zachmiller280/Spotify-API-Pipeline/tree/main)
1. [Spotify API Configuration](1-spotify_api.md)
1. [AWS Account & AWS CLI Setup](2-aws.md)
1. [AWS Infrastructure with Terraform](3-aws_infrastructure.md)
1. [Dashboarding](4-google_looker.md)
1. [Insert Spotify Extended Listening History](5-spotify_extended_listening.md)
