### Instructions for initializing the Aurora PostgreSQL database instance 
First, laumch an EC2 instance in the same VPC as the Aurora/RDS PostgreSQL database. Copy the following files over to that instance from your local environment using a CLI utility such as 'scp'
- exports
- init-1.sh
- init-2.sh
- postgres-data.csv

Then, run the commands manually one by one.

<br/>

Install 'psql' tool on the instance using the following command.
```
sudo amazon-linux-extras install postgresql10 -y
```


Export the environmane variables in the **exports** file. Make sure to update the value of variable **DBHOST** to the endpoint URL of the Aurora PostgreSQL database.
```
source exports
```

#
# Now, run these scripts
# We are connecting to the remote Postgres database and running the PSQL commands against it.
# This will setup the database, schema, table etc.
#
./init-1.sh  # When prompted for password, enter 'postgres'
./init-2.sh  # When prompted for password, enter 'eks'

#
# Now, import data into Postgres database
# First login into the remote Postgres instance
# Then, run the '\copy' commands from within the Postgres shell
# Modify the path names of the CSV files you are using for the import
#
psql --host=$DBHOST --user=$DBROLE --dbname=$DBNAME
\copy analytics.popularity_bucket_permanent from 'postgres-data.csv' WITH DELIMITER ',' CSV HEADER;
