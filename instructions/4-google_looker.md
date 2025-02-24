# Data Visualization in Looker Studio

We now want to visualise our data and validate that we are getting the expected results. Google Looker Studio is a great option for a personal project, as it is free and reports are easily published and shared.


## Google Looker Studio


### Adding your PostgreSQL DB as a Data Source
1. Navigate [here](https://lookerstudio.google.com) and follow the setup instructions. 
1. Click `Create` on the top left, then `Data Source`
1. Search for `PostgreSQL`
1. Enter the required credentials and click `Authenticate`
1. Select your table

You can now feel free to create some visualisations. Some tutorial/guides [here](https://cloud.google.com/looker/docs/studio?hl=en&visit_id=638759559392901347-1940849564&rd=1).



### Using My Report as a Template

You can then publicly share your report by navigating to Share > Manage access.

### What to do once resources are terminated

One thing to note... you don't want to keep your Redshift cluster up past 2 months, as it'll incur a cost once the free trial period comes to an end. You also probably don't want the Airflow Docker containers running on your local machine all the time as this will drain resources and memory.

As such, your Redshift-Google Data Studio connection will eventually be broken. If you want to display a dashboard on your resume even after this happens, one option is to download your Redshift as a CSV as use this as the data source in Google Data Studio:

1. Run the `download_redshift_to_csv.py` file under the `extraction` folder to download your Redshift table as a CSV to your `/tmp` folder. Store this CSV somewhere safe. If you want to download the transformed version of your table, you may need to amend this script slightly to include the new table name, as well as the schema.
1. If you've already created your report in Google, try navigating to File > Make a copy, and select the CSV as the new data source. This should maintain all your existing visualisations.
1. You could also refactor the pipeline to use [CRON](https://en.wikipedia.org/wiki/Cron) and [PostgreSQL](https://www.postgresql.org). You could leave this pipeline running as long as you want without incurring a charge, and your Google Data Studio report will be continuously updated with new data.