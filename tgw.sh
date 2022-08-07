##!/bin/bash
REGION=us-west-2
VPC_A_NAME="EKS-VPC-A"
VPC_B_NAME="EKS-VPC-B"
VPC_A_CIDR="192.168.16.0/20"
VPC_B_CIDR="192.168.32.0/20"
VPC_A_ID=$(aws ec2 describe-vpcs --filters Name=tag:Name,Values=$VPC_A_NAME Name=cidr,Values=$VPC_A_CIDR --query "Vpcs[].VpcId" --output text --region $REGION)
VPC_B_ID=$(aws ec2 describe-vpcs --filters Name=tag:Name,Values=$VPC_B_NAME Name=cidr,Values=$VPC_B_CIDR --query "Vpcs[].VpcId" --output text --region $REGION)
VPC_A_SUBNET_IDS=$(aws ec2 describe-subnets --filters "Name=tag-key,Values=kubernetes.io/role/internal-elb" "Name=vpc-id,Values=$VPC_A_ID" --query "Subnets[].SubnetId" --output json --region $REGION)
VPC_B_SUBNET_IDS=$(aws ec2 describe-subnets --filters "Name=tag-key,Values=kubernetes.io/role/internal-elb" "Name=vpc-id,Values=$VPC_B_ID" --query "Subnets[].SubnetId" --output json --region $REGION)

TGW_ID=$(aws ec2 create-transit-gateway \
--description eks-tgw \
--options=AutoAcceptSharedAttachments=enable,DefaultRouteTableAssociation=enable,DefaultRouteTablePropagation=disable,VpnEcmpSupport=enable,DnsSupport=enable \
--query "TransitGateway.TransitGatewayId" --output text --region $REGION)

tgwStatus() {
  aws ec2 describe-transit-gateways --transit-gateway-ids $TGW_ID  --query "TransitGateways[].State" --output text --region $REGION
}

until [ $(tgwStatus) != "pending" ]; do
  echo "Waiting for transit gateway $TGW_ID to be ready ..."
  sleep 5s
  if [ $(tgwStatus) = "available" ]; then
    echo "Transit gateway $TGW_ID is ready"
    break
  fi
done

TGW_ATTACHMENT_A_ID=$(aws ec2 create-transit-gateway-vpc-attachment \
--transit-gateway-id $TGW_ID \
--vpc-id $VPC_A_ID \
--subnet-ids $VPC_A_SUBNET_IDS \
--tag-specifications "ResourceType=transit-gateway-attachment,Tags=[{Key=Name,Value=tgw_attachment_vpc_a}]" \
--query "TransitGatewayVpcAttachment.TransitGatewayAttachmentId" --output text \
--region $REGION)

TGW_ATTACHMENT_B_ID=$(aws ec2 create-transit-gateway-vpc-attachment \
--transit-gateway-id $TGW_ID \
--vpc-id $VPC_B_ID \
--subnet-ids $VPC_B_SUBNET_IDS \
--tag-specifications "ResourceType=transit-gateway-attachment,Tags=[{Key=Name,Value=tgw_attachment_vpc_b}]" \
--query "TransitGatewayVpcAttachment.TransitGatewayAttachmentId" --output text \
--region $REGION)

tqwAttachmentAStatus() {
  aws ec2 describe-transit-gateway-vpc-attachments --transit-gateway-attachment-ids $TGW_ATTACHMENT_A_ID --query "TransitGatewayVpcAttachments[].State" --output text --region $REGION
}

tqwAttachmentBStatus() {
  aws ec2 describe-transit-gateway-vpc-attachments --transit-gateway-attachment-ids $TGW_ATTACHMENT_B_ID --query "TransitGatewayVpcAttachments[].State" --output text --region $REGION
}

until [ $(tqwAttachmentAStatus) != "pending" ] || [ $(tqwAttachmentBStatus) != "pending" ]; do
  echo "Waiting for transit gateway attachments $TGW_ATTACHMENT_A_ID and $TGW_ATTACHMENT_B_ID to be ready ..."
  sleep 5s
  if [ $(tqwAttachmentAStatus) = "available" ] && [ $(tqwAttachmentBStatus) = "available" ]; then
    echo "Transit gateway attachments $TGW_ATTACHMENT_A_ID and $TGW_ATTACHMENT_B_ID are ready"
    break
  fi
done