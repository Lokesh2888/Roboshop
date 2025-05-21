#!/bin/bash

AMI_ID="ami-09c813fb71547fc4f"
SG_ID="sg-0016b491173d15acd"  #replace with our SG ID
Instances=("mongoDB" "Redis" "mysql" "rabbitmq" "catalogue" "user" "cart" "shipping" "payment" "dispatch" "frontend")
ZONE_ID="Z07885981OQ6FL0MLB24C"
DOMAIN_NAME="pothina.store"

for instance in ${Instances[@]}
do
   INSTANCE_ID=$(aws ec2 run-instances --image-id ami-09c813fb71547fc4f --instance-type t2.micro --security-group-ids sg-0016b491173d15acd --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance}]" --query "Instances[0].PrivateIpAddress" --output text)
   if [ $instance != "frontend" ]
    then
        IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query "Reservations[*].Instances[*].PrivateIpAddress" --output text)
    else
        IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query "Reservations[*].Instances[*].PublicIpAddress" --output text)
    fi
        echo "$instance IP address is $IP"
done