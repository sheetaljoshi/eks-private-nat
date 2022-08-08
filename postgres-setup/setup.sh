
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

aws rds create-db-subnet-group \
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
