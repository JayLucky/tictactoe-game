#!/bin/bash

# Check if bucket name is provided
if [ -z "$1" ]; then
  echo "Usage: ./apply-cors.sh <bucket-name>"
  echo "Example: ./apply-cors.sh my-s3-bucket"
  exit 1
fi

BUCKET_NAME=$1

# Apply CORS configuration to the bucket
echo "Applying CORS configuration to bucket: $BUCKET_NAME"
aws s3api put-bucket-cors --bucket $BUCKET_NAME --cors-configuration file://cors-config.json

echo "CORS configuration applied successfully!"
echo "Note: You may need to configure your bucket for static website hosting if not already done."
echo "You can do this with the following command:"
echo "aws s3 website s3://$BUCKET_NAME --index-document tictactoe/index.html"
