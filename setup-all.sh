#!/bin/bash

# Check if bucket name is provided
if [ -z "$1" ]; then
  echo "Usage: ./setup-all.sh <bucket-name>"
  echo "Example: ./setup-all.sh my-s3-bucket"
  exit 1
fi

BUCKET_NAME=$1

echo "========================================="
echo "TicTacToe Game - Complete Setup Process"
echo "========================================="
echo ""

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
echo ""

# Step 1: Build and deploy the TicTacToe game
echo "Step 1: Building and deploying the TicTacToe game..."
./deploy.sh $BUCKET_NAME
if [ $? -ne 0 ]; then
  echo "Error: Deployment failed. Please check the error messages above."
  echo "See TROUBLESHOOTING.md for common issues and solutions."
  exit 1
fi
echo ""

# Step 2: Enable static website hosting
echo "Step 2: Enabling static website hosting..."
./enable-website.sh $BUCKET_NAME
if [ $? -ne 0 ]; then
  echo "Error: Failed to enable static website hosting. Please check the error messages above."
  exit 1
fi
echo ""

# Step 3: Apply bucket policy
echo "Step 3: Applying bucket policy for public access..."
./apply-policy.sh $BUCKET_NAME
if [ $? -ne 0 ]; then
  echo "Error: Failed to apply bucket policy. Please check the error messages above."
  exit 1
fi
echo ""

# Step 4: Configure CORS
echo "Step 4: Configuring CORS settings..."
./apply-cors.sh $BUCKET_NAME
if [ $? -ne 0 ]; then
  echo "Error: Failed to configure CORS. Please check the error messages above."
  exit 1
fi
echo ""

# Get the website URL
REGION=$(aws configure get region)
if [ -z "$REGION" ]; then
  REGION="us-east-1"  # Default region if not configured
fi

WEBSITE_URL="http://$BUCKET_NAME.s3-website-$REGION.amazonaws.com/tictactoe/index.html"

echo "========================================="
echo "Setup Complete!"
echo "========================================="
echo ""
echo "Your TicTacToe game is now deployed and publicly accessible at:"
echo "$WEBSITE_URL"
echo ""
echo "To remove the deployment, run:"
echo "./destroy.sh $BUCKET_NAME"
