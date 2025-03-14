# Data Visualization in Looker Studio

We now want to visualise our data and validate that we are getting the expected results. Google Looker Studio is a great option for a personal project, as it is free and reports are easily published and shared.

A sample export of my report can be found [here](https://github.com/zachmiller280/Spotify-API-Pipeline/blob/main/images/listening_stats.pdf)

## Google Looker Studio

First, we will need to add our database as a data source within Looker Studio.

### Adding your PostgreSQL DB as a Data Source
1. Navigate [here](https://lookerstudio.google.com) and follow the setup instructions. 
1. Click `Create` on the top left, then `Data Source`
1. Search for `PostgreSQL`
1. Enter the required credentials and click `Authenticate`
1. Select your table

You can now feel free to create visualisations. To help you get started, here are some tutorials/guides can be found [here](https://cloud.google.com/looker/docs/studio?hl=en&visit_id=638759559392901347-1940849564&rd=1).



### Using My Report as a Template

My report can be found [here](https://lookerstudio.google.com/u/0/reporting/f873f57c-0a28-4a8c-961f-5567ca9e753f/page/p_ijh6tw1upd/preview)


To use my template report with your data, follow this [guide](https://cloud.google.com/looker/docs/studio/create-a-report-from-a-template)

### Table of Contents
0. [Project Overview](https://github.com/zachmiller280/Spotify-API-Pipeline/tree/main)
1. [Spotify API Configuration](1-spotify_api.md)
1. [AWS Account & AWS CLI Setup](2-aws.md)
1. [AWS Infrastructure with Terraform](3-aws_infrastructure.md)
1. [Dashboarding](4-google_looker.md)
1. [Insert Spotify Extended Listening History](5-spotify_extended_listening.md)
