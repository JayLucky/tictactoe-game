#!/bin/bash

# Check if bucket name is provided
if [ -z "$1" ]; then
  echo "Usage: ./deploy.sh <bucket-name>"
  echo "Example: ./deploy.sh my-s3-bucket"
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

# Check if the bucket exists
echo "Checking if bucket '$BUCKET_NAME' exists..."
aws s3 ls s3://$BUCKET_NAME > /dev/null 2>&1
if [ $? -ne 0 ]; then
  echo "Error: Bucket '$BUCKET_NAME' does not exist or you don't have permission to access it."
  echo "Would you like to create the bucket? (y/n)"
  read -r CREATE_BUCKET
  if [[ $CREATE_BUCKET =~ ^[Yy]$ ]]; then
    echo "Creating bucket '$BUCKET_NAME'..."
    aws s3 mb s3://$BUCKET_NAME
    if [ $? -ne 0 ]; then
      echo "Error: Failed to create bucket '$BUCKET_NAME'."
      echo "This could be because the bucket name is already taken by someone else or it's invalid."
      echo "S3 bucket names must be globally unique and follow certain rules:"
      echo "- Must be between 3 and 63 characters long"
      echo "- Can only contain lowercase letters, numbers, periods, and hyphens"
      echo "- Must start with a letter or number"
      echo "- Cannot be formatted as an IP address"
      echo "Please try again with a different bucket name."
      exit 1
    fi
    echo "Bucket '$BUCKET_NAME' created successfully."
  else
    echo "Deployment cancelled."
    exit 1
  fi
else
  echo "Bucket '$BUCKET_NAME' exists."
fi

# Build the TypeScript code
echo "Building the CDK project..."
npm run build

# Deploy the stack
echo "Deploying to bucket: $BUCKET_NAME"
npx cdk deploy -c bucketName=$BUCKET_NAME --require-approval never

if [ $? -eq 0 ]; then
  echo "Deployment complete!"
  echo "To make the game publicly accessible, you may need to:"
  echo "1. Enable static website hosting: ./enable-website.sh $BUCKET_NAME"
  echo "2. Apply bucket policy: ./apply-policy.sh $BUCKET_NAME"
  echo "3. Configure CORS: ./apply-cors.sh $BUCKET_NAME"
  echo ""
  echo "Or run the all-in-one setup: ./setup-all.sh $BUCKET_NAME"
else
  echo "Deployment failed. Please check the error messages above."
  echo "See TROUBLESHOOTING.md for common issues and solutions."
  exit 1
fi
