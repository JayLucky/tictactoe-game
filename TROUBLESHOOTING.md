# Troubleshooting CDK Deployment Issues

## Bootstrap Errors

### Missing Bootstrap Resources

If you see an error like this:

```
current credentials could not be used to assume 'arn:aws:iam::149537428939:role/cdk-hnb659fds-deploy-role-149537428939-us-west-2', but are for the right account. Proceeding anyway.
TictactoeCdkDeployStack: SSM parameter /cdk-bootstrap/hnb659fds/version not found. Has the environment been bootstrapped? Please run 'cdk bootstrap' (see https://docs.aws.amazon.com/cdk/latest/guide/bootstrapping.html)
```

#### What This Means

The AWS CDK requires certain resources to be provisioned in your AWS account before you can deploy CDK applications. This process is called "bootstrapping." The error indicates that your AWS environment (account/region) has not been bootstrapped yet.

#### How to Fix It

Use our bootstrap script to bootstrap your AWS environment:

```bash
./bootstrap.sh
```

This command will:
1. Create an S3 bucket in your account to store assets
2. Create IAM roles that the CDK will assume to perform deployments
3. Create other resources needed for CDK deployments

If you want to bootstrap a specific account and region, you can use:

```bash
./bootstrap.sh ACCOUNT-NUMBER REGION
```

For example:
```bash
./bootstrap.sh 149537428939 us-west-2
```

### Bucket Name Required Error

If you see an error like this when running the bootstrap script:

```
Error: Please provide a bucket name using -c bucketName=your-bucket-name
```

#### What This Means

This error occurs because our CDK application is designed to require a bucket name parameter, but the bootstrap process doesn't need a bucket name.

#### How to Fix It

We've updated the bootstrap script to fix this issue by using a separate minimal CDK app just for bootstrapping. This app is located in the `bootstrap-app` directory and doesn't require any parameters.

Make sure you're using the latest version of the bootstrap.sh script. The script will:

1. Check if the bootstrap app dependencies are installed
2. Install them if needed
3. Run the bootstrap command using the separate app

If you're still seeing this error, you can manually bootstrap your AWS environment with these commands:

```bash
# Navigate to the bootstrap app directory
cd bootstrap-app

# Install dependencies if needed
npm install

# Get your AWS account ID and region
ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
REGION=$(aws configure get region)

# Run the bootstrap command
npx cdk bootstrap aws://$ACCOUNT/$REGION --app "node app.js"
```

This approach uses a separate minimal CDK app that doesn't require any parameters, allowing the bootstrap process to run without errors.

### Module Not Found Error

If you see an error like this when running the bootstrap script:

```
Error: Cannot find module 'aws-cdk-lib'
```

#### What This Means

This error occurs because the bootstrap app is missing its dependencies.

#### How to Fix It

Make sure you're in the project root directory when running the bootstrap script. The script will automatically install the required dependencies for the bootstrap app.

If you're still seeing this error, you can manually install the dependencies:

```bash
cd bootstrap-app
npm install
```

Then try running the bootstrap script again.

### This App Contains No Stacks Error

If you see an error like this when running the bootstrap script:

```
This app contains no stacks
```

#### What This Means

The CDK CLI expects at least one stack to be defined in the app, but our bootstrap app doesn't define any stacks.

#### How to Fix It

We've updated the bootstrap app to include a dummy stack that won't actually be deployed but will satisfy the CDK CLI. Make sure you're using the latest version of the bootstrap app.

If you're still seeing this error, you can manually update the bootstrap app:

```bash
# Edit bootstrap-app/app.js to include a dummy stack
cat > bootstrap-app/app.js << 'EOF'
#!/usr/bin/env node
const { App, Stack } = require('aws-cdk-lib');

// Create a minimal CDK app with a dummy stack
const app = new App();

// Create a dummy stack that won't actually be deployed
class DummyStack extends Stack {
  constructor(scope, id, props) {
    super(scope, id, props);
    // No resources needed, this is just a placeholder
  }
}

// Add the dummy stack to the app
new DummyStack(app, 'DummyStack');

app.synth();
EOF

# Make it executable
chmod +x bootstrap-app/app.js
```

Then try running the bootstrap script again.

### Permissions Required

To bootstrap an environment, you need permissions to:
- Create S3 buckets
- Create IAM roles
- Create CloudFormation stacks
- Create SSM parameters

If you're using an IAM user or role with restricted permissions, you might need to request these permissions from your AWS administrator.

### After Bootstrapping

Once the bootstrapping process is complete, try deploying your CDK stack again:

```bash
./deploy.sh your-bucket-name
```

Or using the all-in-one setup script:

```bash
./setup-all.sh your-bucket-name
```

## Deployment Errors

### S3 Sync Failed Error

If you see an error like this during deployment:

```
Received response status [FAILED] from custom resource. Message returned: Command '['/opt/awscli/aws', 's3', 'sync', '--delete', '/tmp/tmp6b6gb6kv/contents', 's3://your-bucket-name/tictactoe']' returned non-zero exit status 1.
```

#### What This Means

The CDK deployment is failing when trying to sync files to the S3 bucket. This could be due to several reasons:

1. The S3 bucket doesn't exist
2. The IAM user/role doesn't have permission to write to the S3 bucket
3. The bucket name is invalid or has some special characters

#### How to Fix It

1. **Verify the bucket exists**: Make sure the bucket you're trying to deploy to actually exists.

   ```bash
   aws s3 ls | grep your-bucket-name
   ```

   If the bucket doesn't exist, you need to create it first:

   ```bash
   aws s3 mb s3://your-bucket-name
   ```

2. **Check permissions**: Make sure your IAM user/role has permission to write to the S3 bucket.

   ```bash
   aws s3 ls s3://your-bucket-name
   ```

   If you get an access denied error, you need to update the bucket policy or IAM permissions.

3. **Verify bucket name**: S3 bucket names must follow certain rules:
   - Must be between 3 and 63 characters long
   - Can only contain lowercase letters, numbers, periods, and hyphens
   - Must start with a letter or number
   - Cannot be formatted as an IP address

4. **Check if the bucket is in the same region**: Make sure the bucket is in the same region as your CDK deployment.

   ```bash
   aws s3api get-bucket-location --bucket your-bucket-name
   ```

### Invalid Index Document Suffix Error

If you see an error like this when enabling static website hosting:

```
An error occurred (InvalidArgument) when calling the PutBucketWebsite operation: The IndexDocument Suffix is not well formed
```

#### What This Means

The index document suffix must be a file name, not a path. For example, `index.html` is valid, but `tictactoe/index.html` is not.

#### How to Fix It

We've updated the enable-website.sh script to use a valid index document suffix. Make sure you're using the latest version of the script.

If you're still seeing this error, you can manually enable static website hosting:

```bash
aws s3 website s3://your-bucket-name --index-document index.html
```

### Block Public Access Error

If you see an error like this when applying the bucket policy:

```
An error occurred (AccessDenied) when calling the PutBucketPolicy operation: User is not authorized to perform: s3:PutBucketPolicy on resource because public policies are blocked by the BlockPublicPolicy block public access setting.
```

#### What This Means

The bucket has Block Public Access settings enabled, which is preventing you from applying a public bucket policy.

#### How to Fix It

We've updated the apply-policy.sh script to check for and handle Block Public Access settings. Make sure you're using the latest version of the script.

If you're still seeing this error, you can manually disable Block Public Access:

1. **Check Block Public Access settings**:

   ```bash
   aws s3api get-public-access-block --bucket your-bucket-name
   ```

2. **Disable Block Public Access**:

   ```bash
   aws s3api delete-public-access-block --bucket your-bucket-name
   ```

3. **Apply the bucket policy**:

   ```bash
   aws s3api put-bucket-policy --bucket your-bucket-name --policy file://bucket-policy.json
   ```

Alternatively, you can disable Block Public Access in the AWS S3 console:

1. Go to the S3 console
2. Select your bucket
3. Go to the 'Permissions' tab
4. Click 'Edit' in the 'Block public access' section
5. Uncheck the options and save

### CloudFormation Stack Rollback Failed

If you see an error like this:

```
The stack named TictactoeCdkDeployStack failed creation, it may need to be manually deleted from the AWS console: ROLLBACK_FAILED
```

#### What This Means

The CloudFormation stack failed to create and then also failed to roll back. This means you'll need to manually delete the stack before you can try again.

#### How to Fix It

1. Go to the AWS CloudFormation console
2. Find the stack named "TictactoeCdkDeployStack"
3. Select the stack and click "Delete"
4. Wait for the stack to be deleted
5. Try deploying again

## Other Common Issues

### S3 Bucket Already Exists

If you see an error about the S3 bucket already existing, it means another AWS account has already created a bucket with the same name. S3 bucket names must be globally unique across all AWS accounts.

Solution: Choose a different bucket name.

### Insufficient Permissions

If you see access denied errors, it means your AWS credentials don't have sufficient permissions to perform the required actions.

Solution: Ensure your AWS credentials have the necessary permissions for S3 operations, CloudFormation, and IAM (if using the bootstrap process).

### Region Configuration

Make sure your AWS CLI is configured with the correct region where your S3 bucket exists.

You can check your current region with:
```bash
aws configure get region
```

You can set a different region with:
```bash
aws configure set region us-west-2
```
