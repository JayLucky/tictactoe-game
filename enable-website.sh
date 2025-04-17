#!/bin/bash

# Check if bucket name is provided
if [ -z "$1" ]; then
  echo "Usage: ./enable-website.sh <bucket-name>"
  echo "Example: ./enable-website.sh my-s3-bucket"
  exit 1
fi

BUCKET_NAME=$1

# Enable static website hosting
echo "Enabling static website hosting for bucket: $BUCKET_NAME"
aws s3 website s3://$BUCKET_NAME --index-document index.html
echo "Note: The index document is set to 'index.html' at the root level."
echo "The TicTacToe game will be accessible at the 'tictactoe' prefix."

# Get the website URL
REGION=$(aws configure get region)
if [ -z "$REGION" ]; then
  REGION="us-east-1"  # Default region if not configured
fi

WEBSITE_URL="http://$BUCKET_NAME.s3-website-$REGION.amazonaws.com/tictactoe/index.html"

echo "Static website hosting enabled successfully!"
echo "Your TicTacToe game is now accessible at:"
echo "$WEBSITE_URL"
echo ""
echo "Note: Make sure your bucket policy allows public access if you want the game to be publicly accessible."
echo "You can use the following bucket policy as a template (save to bucket-policy.json and modify as needed):"
echo ""
echo '{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "PublicReadGetObject",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::'$BUCKET_NAME'/tictactoe/*"
    }
  ]
}'
echo ""
echo "Then apply it with:"
echo "aws s3api put-bucket-policy --bucket $BUCKET_NAME --policy file://bucket-policy.json"
