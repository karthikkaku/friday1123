#!/bin/bash

# Instance ID, Base AMI Name, and Description
InstanceID=$1
BaseAMIName=$2
Description=$3

echo "Instance ID: $InstanceID"
echo "BaseAMIName: $BaseAMIName"
echo "Description: $Description"

# Set your Slack API token here
SLACK_API_TOKEN="xoxb-6304431362048-6320659208197-YqD4S8FA2leoPaceMnKOEM2m"

# Set your AWS credentials here
export AWS_ACCESS_KEY_ID="AKIAY7SEYN2PAKWIB7MX"
export AWS_SECRET_ACCESS_KEY="hbzGl96S+KRip53HEgN6ib5icbocvPSvVmsNr21z"
export AWS_DEFAULT_REGION="us-east-2"

# Generate a unique timestamp
Timestamp=$(date +"%Y%m%d%H%M%S")

# Create a unique AMI name by appending the timestamp to the base AMI name
AMIName="${BaseAMIName}_${Timestamp}"

# Check if an AMI with the specified name already exists
existingAmi=$(aws ec2 describe-images --owners self --filters "Name=name,Values=$AMIName" --query 'Images[*].ImageId' --output text)

if [ -n "$existingAmi" ]; then
    echo "An AMI with the name '$AMIName' already exists (AMI ID: $existingAmi). Please choose a different base AMI name."
    exit 0
fi

# Create an AMI from the specified EC2 instance
AMIId=$(aws ec2 create-image --instance-id "$InstanceID" --name "$AMIName" --description "$Description" --output text)

echo "Creating AMI with ID: $AMIId and name: $AMIName"

# Wait for the AMI creation to complete
amiStatus="pending"
while [ "$amiStatus" = "pending" ]; do
    sleep 30  # Wait for 30 seconds before checking again
    ami=$(aws ec2 describe-images --image-ids "$AMIId" --query 'Images[*].State' --output text)
    amiStatus="$ami"
done

if [ "$amiStatus" = "available" ]; then
    echo "AMI creation completed. AMI ID: $AMIId"

    # Construct the Slack message
    slackMessage="AMI updated. New AMI ID: $AMIId"

    # Slack API call using curl
    curl -X POST -H "Content-Type: application/json" -H "Authorization: Bearer $SLACK_API_TOKEN" -d "{\"text\":\"$slackMessage\"}" https://slack.com/api/chat.postMessage

else
    echo "AMI creation failed or timed out."
fi
