#!/bin/bash

# Check if bucket name is provided
if [ -z "$1" ]; then
  echo "Usage: ./apply-policy.sh <bucket-name>"
  echo "Example: ./apply-policy.sh my-s3-bucket"
  exit 1
fi

BUCKET_NAME=$1

# Check if Block Public Access is enabled
echo "Checking Block Public Access settings for bucket: $BUCKET_NAME"
BPA_SETTINGS=$(aws s3api get-public-access-block --bucket $BUCKET_NAME 2>/dev/null)
BPA_ENABLED=$?

if [ $BPA_ENABLED -eq 0 ]; then
  echo "Block Public Access is enabled for this bucket."
  echo "Would you like to disable Block Public Access to allow public access to your game? (y/n)"
  read -r DISABLE_BPA
  if [[ $DISABLE_BPA =~ ^[Yy]$ ]]; then
    echo "Disabling Block Public Access for bucket: $BUCKET_NAME"
    aws s3api delete-public-access-block --bucket $BUCKET_NAME
    if [ $? -ne 0 ]; then
      echo "Error: Failed to disable Block Public Access."
      echo "You may not have sufficient permissions to modify bucket settings."
      echo "Please disable Block Public Access manually in the AWS S3 console."
      exit 1
    fi
    echo "Block Public Access disabled successfully."
  else
    echo "Keeping Block Public Access enabled."
    echo "Note: Your bucket policy will not allow public access while Block Public Access is enabled."
    echo "You can manually disable Block Public Access in the AWS S3 console if needed."
  fi
else
  echo "Block Public Access is not enabled for this bucket."
fi

# Create a temporary policy file with the bucket name replaced
echo "Creating bucket policy for: $BUCKET_NAME"
sed "s/BUCKET_NAME_PLACEHOLDER/$BUCKET_NAME/g" bucket-policy-template.json > bucket-policy.json

# Apply the bucket policy
echo "Applying bucket policy to: $BUCKET_NAME"
aws s3api put-bucket-policy --bucket $BUCKET_NAME --policy file://bucket-policy.json
POLICY_RESULT=$?

# Clean up the temporary file
rm bucket-policy.json

if [ $POLICY_RESULT -eq 0 ]; then
  echo "Bucket policy applied successfully!"
  echo "Your TicTacToe game files should now be publicly accessible."
else
  echo "Failed to apply bucket policy."
  echo "This could be due to:"
  echo "1. Block Public Access settings are still enabled"
  echo "2. You don't have sufficient permissions to modify the bucket policy"
  echo "3. The bucket doesn't exist or is in a different region"
  echo ""
  echo "You can manually apply the bucket policy in the AWS S3 console:"
  echo "1. Go to the S3 console"
  echo "2. Select your bucket"
  echo "3. Go to the 'Permissions' tab"
  echo "4. Edit the 'Bucket Policy'"
  echo "5. Paste the following policy:"
  echo ""
  cat bucket-policy-template.json | sed "s/BUCKET_NAME_PLACEHOLDER/$BUCKET_NAME/g"
  exit 1
fi
echo ""
echo "Note: Make sure you have also enabled static website hosting using the enable-website.sh script."
echo "If you've done that, your game should be accessible at:"
echo "http://$BUCKET_NAME.s3-website-$(aws configure get region || echo 'us-east-1').amazonaws.com/tictactoe/index.html"
