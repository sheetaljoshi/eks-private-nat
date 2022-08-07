
REGION=us-west-2
ZONE=us-west-2a
VPC_CIDR="192.168.32.0/20"
VPC_NAME="EKS-VPC-B"
SG_NAME="AuroraIngressSecurityGroup"
VPC_ID=$(aws ec2 describe-vpcs --filters Name=tag:Name,Values=$VPC_NAME Name=cidr,Values=$VPC_CIDR --query "Vpcs[].VpcId" --output text --region $REGION)
SG_ID=$(aws ec2 describe-security-groups --filters Name=tag:Name,Values=$SG_NAME Name=vpc-id,Values=$VPC_ID --query "SecurityGroups[].GroupId" --output text --region $REGION)
PRIVATE_SUBNET_IDS=$(aws ec2 describe-subnets --filters "Name=tag-key,Values=kubernetes.io/role/internal-elb" "Name=vpc-id,Values=$VPC_ID" --query "Subnets[].SubnetId" --region $REGION)

DB_SUBNET_GROUP="eks-subnet-group"
DB_CLUSTER="aurora-eks-cluster"
DB_INSTANCE="eks"
DB_ENGINE="aurora-postgresql"
DB_ENGINE_VERSION="10.18"
--db-subnet-group-name $DB_SUBNET_GROUP \
--db-subnet-group-description "Aurora PostgreSQL subnet group" \
--subnet-ids $PRIVATE_SUBNET_IDS \
--region $REGION

aws rds create-db-cluster \
--db-cluster-identifier $DB_CLUSTER \
--engine $DB_ENGINE \
--engine-version $DB_ENGINE_VERSION \
--vpc-security-group-ids $SG_ID \
--master-username postgres \
--master-user-password postgres \
--db-subnet-group-name $DB_SUBNET_GROUP \
--availability-zone $ZONE \
--region $REGION

aws rds create-db-instance \
--db-cluster-identifier $DB_CLUSTER \
--db-instance-identifier $DB_INSTANCE \
--engine $DB_ENGINE \
--engine-version $DB_ENGINE_VERSION \
--db-instance-class db.r5.large \
--db-subnet-group-name $DB_SUBNET_GROUP \
--availability-zone $ZONE \
--no-multi-az \
--no-publicly-accessible \
--region $REGION


#
# Run these commands from an EC2 instance which is in the same VPC as the Aurora/RDS PostgreSQL database.
# Install 'psql' tool on the instance using the following command
# 
sudo amazon-linux-extras install postgresql10 -y

#
# Export the environmane variables in the 'exports' file
# 
source exports

#
# Now, run these scripts
# We are connecting to the remote Postgres database and running the PSQL commands against it.
# This will setup the database, schema, table etc.
#
./init-1.sh
./init-2.sh

#
# Now, import data into Postgres database
# First login into the remote Postgres instance
# Then, run the '\copy' commands from within the Postgres shell
# Modify the path names of the CSV files you are using for the import
#
psql --host=$DBHOST --user=$DBROLE --dbname=$DBNAME
\copy analytics.popularity_bucket_permanent from 'postgres-data.csv' WITH DELIMITER ',' CSV HEADER;
