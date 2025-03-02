# Terraforming Tracks: Automating Spotify Listening History Collection and Storage with AWS Serverless


## Purpose

As a music and data nerd, I wanted a way to capture all of my listening data for dashboarding, exploritory analysis, and extracting insights. While Spotify does offer a method to request extended listening history, this process is rather slow (taking at least 3-4 weeks to complete) and difficult to automate. This solution offers a near real-time view into my listening habits.

This project provided an opportunity to work with a variety of commonly used tools I haven’t had exposure to before. Because of this, this project is rather ‘over-engineered’.


## Architecture

<img src="https://github.com/zachmiller280/Spotify-API-Pipeline/blob/main/images/architecture_diagram.png" width=70% height=70%>

1. Create AWS resources with [Terraform](https://www.terraform.io)
1. Extract data using [Spotify's API](https://developer.spotify.com/documentation/web-api)
1. Transform data using [AWS Lambda](https://aws.amazon.com/pm/lambda/)
1. Load into PostgreSQL Database on [AWS EC2](https://aws.amazon.com/ec2/)
1. Create [Google Looker](https://lookerstudio.google.com/) Dashboard
1. Insert Extended Listening History data provided by [Spotify](https://www.spotify.com/us/account/privacy/)


## Result

A dashboard in Google Looker Studio using the data collected:

[<img src="https://github.com/zachmiller280/Spotify-API-Pipeline/blob/main/images/looker_dashboard.png" width=70% height=70%>](https://datastudio.google.com/reporting/e927fef6-b605-421c-ae29-89a66e11ea18)

* A full print out of my report can be found [here](images/listening_stats.pdf)


* To view my report within Looker Studio, please look  [here](https://lookerstudio.google.com/u/0/reporting/f873f57c-0a28-4a8c-961f-5567ca9e753f/page/p_ijh6tw1upd/preview)

## Setup

Follow the below steps to setup pipeline. I used Terraform to try to simplify as much of the setup as possible, so most the the work will be ensuring the correct software is installed and you have the appropriate permissions. 


I am using AWS offer a free tier, however, you should be aware that depending on the amount of listening data you have you may exceed the free tier's EC2 limit. Also, AWS Secrets Manager is **not included** in this tier, and incurs a cost for each secret (at the time I built this, it was $0.40/secret/month). Please make sure to review [AWS free tier](https://aws.amazon.com/free/?all-free-tier.sort-by=item.additionalFields.SortRank&all-free-tier.sort-order=asc&awsf.Free%20Tier%20Types=*all&awsf.Free%20Tier%20Categories=*all) limits, as this may change over time.

Before we get started, clone this repository into your local directory.

  ```bash
  git clone https://github.com/zachmiller280/Spotify-API-Pipeline.git
  cd Spotify-API-Pipeline
  ```
1. [Spotify API Configuration](instructions/1-spotify_api.md)
1. [AWS Account & AWS CLI Setup](instructions/2-aws.md)
1. [AWS Infrastructure with Terraform](instructions/3-aws_infrastructure.md)
1. [Dashboarding](instructions/4-google_looker.md)
1. [Insert Spotify Extended Listening History](instructions/5-spotify_extended_listening.md)


## Important Notes

1. Spotify's `recently-played` endpoint does not capture tracks which have been skipped. The endpoint seems to only capture songs which are played until the end, so you can start a track, scrub to near the end of the track, and it should be captured.

1. Spotify's `recently-played` endpoint allows us to capture a track's popularity at the time it was played. However, our historical listening data will not include this attribute. **This will cause nulls in all historical records.** 
