#!/bin/bash

# Path to the bootstrap app directory
BOOTSTRAP_APP_DIR="./bootstrap-app"

# Check if the bootstrap app dependencies are installed
if [ ! -d "$BOOTSTRAP_APP_DIR/node_modules" ]; then
  echo "Installing dependencies for bootstrap app..."
  (cd $BOOTSTRAP_APP_DIR && npm install)
  if [ $? -ne 0 ]; then
    echo "Error: Failed to install dependencies for bootstrap app."
    exit 1
  fi
fi

# Check if account and region are provided
if [ "$#" -eq 0 ]; then
  echo "Using default AWS account and region from AWS CLI configuration..."
  
  # Get the AWS account ID and region from AWS CLI configuration
  ACCOUNT=$(aws sts get-caller-identity --query Account --output text 2>/dev/null)
  REGION=$(aws configure get region 2>/dev/null)
  
  if [ -z "$ACCOUNT" ] || [ -z "$REGION" ]; then
    echo "Error: Could not determine AWS account ID or region."
    echo "Please configure your AWS CLI with 'aws configure' or provide account and region explicitly."
    exit 1
  fi
  
  echo "Detected AWS account $ACCOUNT in region $REGION"
  
  # Run the bootstrap command using our separate bootstrap app
  echo "Bootstrapping AWS environment..."
  (cd $BOOTSTRAP_APP_DIR && npx cdk bootstrap aws://$ACCOUNT/$REGION --app "node app.js")
  
  BOOTSTRAP_RESULT=$?
elif [ "$#" -eq 2 ]; then
  ACCOUNT=$1
  REGION=$2
  echo "Bootstrapping AWS account $ACCOUNT in region $REGION..."
  
  # Run the bootstrap command using our separate bootstrap app
  echo "Bootstrapping AWS environment..."
  (cd $BOOTSTRAP_APP_DIR && npx cdk bootstrap aws://$ACCOUNT/$REGION --app "node app.js")
  
  BOOTSTRAP_RESULT=$?
else
  echo "Usage: ./bootstrap.sh [account-number region]"
  echo "Examples:"
  echo "  ./bootstrap.sh                      # Use default account and region from AWS CLI config"
  echo "  ./bootstrap.sh 123456789012 us-east-1  # Bootstrap specific account and region"
  exit 1
fi

# Check if bootstrap was successful
if [ $BOOTSTRAP_RESULT -eq 0 ]; then
  echo "Bootstrap completed successfully!"
  echo "You can now deploy your CDK stack using:"
  echo "./deploy.sh your-bucket-name"
  echo "or"
  echo "./setup-all.sh your-bucket-name"
else
  echo "Bootstrap failed. Please check the error messages above."
  echo "You may need additional permissions to bootstrap your AWS environment."
  echo "See TROUBLESHOOTING.md for more information."
  exit 1
fi
