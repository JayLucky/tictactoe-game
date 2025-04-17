#!/bin/bash

# Check if bucket name is provided
if [ -z "$1" ]; then
  echo "Usage: ./destroy.sh <bucket-name>"
  echo "Example: ./destroy.sh my-s3-bucket"
  exit 1
fi

BUCKET_NAME=$1

# Check if the environment is bootstrapped
echo "Checking if AWS environment is bootstrapped..."
# Get the AWS account ID and region
ACCOUNT=$(aws sts get-caller-identity --query Account --output text 2>/dev/null)
REGION=$(aws configure get region 2>/dev/null)

if [ -z "$ACCOUNT" ] || [ -z "$REGION" ]; then
  echo "Error: Could not determine AWS account ID or region."
  echo "Please configure your AWS CLI with 'aws configure'."
  exit 1
fi

# Check if the CDK bootstrap stack exists
aws cloudformation describe-stacks --stack-name CDKToolkit --region $REGION > /dev/null 2>&1
if [ $? -ne 0 ]; then
  echo "Error: AWS environment is not bootstrapped."
  echo "Please run './bootstrap.sh' first to bootstrap your AWS environment."
  echo "See TROUBLESHOOTING.md for more information."
  exit 1
fi
echo "AWS environment is bootstrapped."

# Check if the CloudFormation stack exists
echo "Checking if CloudFormation stack exists..."
aws cloudformation describe-stacks --stack-name TictactoeCdkDeployStack --region $REGION > /dev/null 2>&1
if [ $? -ne 0 ]; then
  echo "CloudFormation stack 'TictactoeCdkDeployStack' does not exist or has already been deleted."
  echo "No action needed."
  exit 0
fi

# Destroy the stack
echo "Removing deployment from bucket: $BUCKET_NAME"
npx cdk destroy -c bucketName=$BUCKET_NAME --force

if [ $? -eq 0 ]; then
  echo "Removal complete!"
  echo "Note: This only removed the files deployed by CDK."
  echo "The bucket itself and any bucket configurations (website hosting, CORS, policy) remain unchanged."
else
  echo "Removal failed. Please check the error messages above."
  echo "The stack may be in a ROLLBACK_FAILED state and need to be manually deleted."
  echo "To manually delete the stack:"
  echo "1. Go to the AWS CloudFormation console"
  echo "2. Find the stack named 'TictactoeCdkDeployStack'"
  echo "3. Select the stack and click 'Delete'"
  echo "4. Wait for the stack to be deleted"
  echo "See TROUBLESHOOTING.md for more information."
  exit 1
fi
