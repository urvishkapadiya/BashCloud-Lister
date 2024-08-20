#!/bin/bash

###############################################################################
# Author: Urvish Kapadiya
# Version: v0.0.2

# Below are the services that are supported by this script:
# 1. EC2
# 2. RDS
# 3. S3
# 4. CloudFront
# 5. VPC
# 6. IAM
# 7. Route53
# 8. CloudWatch
# 9. CloudFormation
# 10. Lambda
# 11. SNS
# 12. SQS
# 13. DynamoDB
# 14. VPC
# 15. EBS

# The script will prompt the user to enter the AWS region and the service for which the resources need to be listed.

# Usage: ./aws_resource_list.sh <aws_region> <aws_service>
# Example: ./aws_resource_list.sh us-east-1 ec2

# functionalities:
# 1. Support for listing resources in all regions.
# 2. Log output to a file.
# 3. Interactive mode for user input.
# 4. Error handling and messages.
# 5. Counting and listing details of resources.
###############################################################################

# Log file setup
log_file="aws_resource_list_$(date +%F_%T).log"
exec > >(tee -i "$log_file") 2>&1

# Function to list and count resources
list_resources() {
    aws_service=$1
    aws_region=$2

    echo "Listing $aws_service resources in $aws_region"

    case $aws_service in
        ec2)
            resource_output=$(aws ec2 describe-instances --region $aws_region)
            resource_count=$(echo "$resource_output" | grep -o '"InstanceId"' | wc -l)
            ;;
        rds)
            resource_output=$(aws rds describe-db-instances --region $aws_region)
            resource_count=$(echo "$resource_output" | grep -o '"DBInstanceIdentifier"' | wc -l)
            ;;
        s3)
            resource_output=$(aws s3api list-buckets --region $aws_region)
            resource_count=$(echo "$resource_output" | grep -o '"BucketName"' | wc -l)
            ;;
        cloudfront)
            resource_output=$(aws cloudfront list-distributions --region $aws_region)
            resource_count=$(echo "$resource_output" | grep -o '"Id"' | wc -l)
            ;;
        vpc)
            resource_output=$(aws ec2 describe-vpcs --region $aws_region)
            resource_count=$(echo "$resource_output" | grep -o '"VpcId"' | wc -l)
            ;;
        iam)
            resource_output=$(aws iam list-users --region $aws_region)
            resource_count=$(echo "$resource_output" | grep -o '"UserName"' | wc -l)
            ;;
        route53)
            resource_output=$(aws route53 list-hosted-zones --region $aws_region)
            resource_count=$(echo "$resource_output" | grep -o '"Name"' | wc -l)
            ;;
        cloudwatch)
            resource_output=$(aws cloudwatch describe-alarms --region $aws_region)
            resource_count=$(echo "$resource_output" | grep -o '"AlarmName"' | wc -l)
            ;;
        cloudformation)
            resource_output=$(aws cloudformation describe-stacks --region $aws_region)
            resource_count=$(echo "$resource_output" | grep -o '"StackName"' | wc -l)
            ;;
        lambda)
            resource_output=$(aws lambda list-functions --region $aws_region)
            resource_count=$(echo "$resource_output" | grep -o '"FunctionName"' | wc -l)
            ;;
        sns)
            resource_output=$(aws sns list-topics --region $aws_region)
            resource_count=$(echo "$resource_output" | grep -o '"TopicArn"' | wc -l)
            ;;
        sqs)
            resource_output=$(aws sqs list-queues --region $aws_region)
            resource_count=$(echo "$resource_output" | grep -o '"QueueUrl"' | wc -l)
            ;;
        dynamodb)
            resource_output=$(aws dynamodb list-tables --region $aws_region)
            resource_count=$(echo "$resource_output" | grep -o '"TableName"' | wc -l)
            ;;
        ebs)
            resource_output=$(aws ec2 describe-volumes --region $aws_region)
            resource_count=$(echo "$resource_output" | grep -o '"VolumeId"' | wc -l)
            ;;
        *)
            echo "Invalid service: $aws_service"
            return 1
            ;;
    esac

    echo "Total $aws_service resources found: $resource_count"
    echo "$resource_output" | jq '.' # Pretty print the JSON output
}

# Function to handle multiple regions
handle_regions() {
    aws_service=$1
    aws_region=$2

    if [ "$aws_region" == "all" ]; then
        regions=$(aws ec2 describe-regions --query "Regions[*].RegionName" --output text)
        for region in $regions; do
            echo "Processing region: $region"
            list_resources $aws_service $region || echo "Error processing $aws_service in $region"
        done
    else
        list_resources $aws_service $aws_region || echo "Error processing $aws_service in $aws_region"
    fi
}

# Function for interactive mode
interactive_mode() {
    echo "Enter AWS region (or type 'all' for all regions):"
    read aws_region
    echo "Enter AWS service:"
    read aws_service
}

# Main script
if [ $# -ne 2 ]; then
    echo "Entering interactive mode as no arguments were provided..."
    interactive_mode
else
    aws_region=$1
    aws_service=$2
fi

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo "AWS CLI is not installed. Please install the AWS CLI and try again."
    exit 1
fi

# Check if AWS CLI is configured
if [ ! -d ~/.aws ]; then
    echo "AWS CLI is not configured. Please configure the AWS CLI and try again."
    exit 1
fi

# Call the function to handle regions and services
handle_regions $aws_service $aws_region

echo "Resource listing complete. Log file saved as $log_file."
