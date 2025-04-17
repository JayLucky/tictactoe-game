# TicTacToe CDK Deployment

This CDK project deploys a TicTacToe game to an existing S3 bucket. The deployment can be easily installed or removed using AWS CDK.

## Prerequisites

- [AWS CLI](https://aws.amazon.com/cli/) installed and configured
- [Node.js](https://nodejs.org/) (v14 or later)
- [AWS CDK](https://aws.amazon.com/cdk/) installed (`npm install -g aws-cdk`)
- An existing S3 bucket with appropriate permissions

## Setup

1. Clone this repository
2. Install dependencies:
   ```
   npm install
   ```
3. Bootstrap your AWS environment (if you haven't already):
   ```
   ./bootstrap.sh
   ```
   
   You can also bootstrap a specific account and region:
   ```
   ./bootstrap.sh 123456789012 us-east-1
   ```
   
   See [Troubleshooting](#troubleshooting) if you encounter any issues with bootstrapping.

## Deployment

To deploy the TicTacToe game to your S3 bucket, run:

```bash
cdk deploy -c bucketName=your-bucket-name
```

Replace `your-bucket-name` with the name of your existing S3 bucket.

After deployment, the CDK will output the URL where you can access the TicTacToe game.

## Removal

To remove the TicTacToe game from your S3 bucket, run:

```bash
cdk destroy -c bucketName=your-bucket-name
```

This will remove all files deployed by this CDK stack from your S3 bucket.

## Structure

- `bin/tictactoe-cdk-deploy.ts` - Entry point for the CDK application
- `lib/tictactoe-cdk-deploy-stack.ts` - Main stack definition
- `assets/` - Contains the TicTacToe game files to be deployed

## Notes

- The deployment uses the `retainOnDelete: false` option, which means the files will be removed when the stack is destroyed.
- The game is deployed to a `tictactoe/` prefix in the bucket, so it won't interfere with other content.
- Make sure your S3 bucket has the appropriate permissions and CORS configuration if you plan to access the game from a browser.

## Helper Scripts

This project includes several helper scripts to make deployment and management easier:

### Deploy Script

```bash
./deploy.sh your-bucket-name
# or
npm run deploy your-bucket-name
```

### Destroy Script

```bash
./destroy.sh your-bucket-name
# or
npm run destroy your-bucket-name
```

### CORS Configuration

If you need to configure CORS for your S3 bucket (required if accessing the game from a different domain):

```bash
./apply-cors.sh your-bucket-name
```

This script applies a permissive CORS configuration that allows GET requests from any origin.

### Static Website Hosting

To enable static website hosting on your S3 bucket:

```bash
./enable-website.sh your-bucket-name
```

After configuring static website hosting, your game will be accessible at:
`http://your-bucket-name.s3-website-<region>.amazonaws.com/tictactoe/index.html`

### Bucket Policy

To make your TicTacToe game publicly accessible, you need to apply a bucket policy:

```bash
./apply-policy.sh your-bucket-name
```

This script applies a policy that allows public read access to the TicTacToe game files.

## Complete Setup Process

### All-in-One Setup

For a complete setup in one step, use the all-in-one setup script:

```bash
./setup-all.sh your-bucket-name
```

This script will:
1. Build and deploy the TicTacToe game
2. Enable static website hosting
3. Apply the bucket policy for public access
4. Configure CORS settings

After completion, your TicTacToe game will be publicly accessible at:
`http://your-bucket-name.s3-website-<region>.amazonaws.com/tictactoe/index.html`

### Manual Step-by-Step Setup

If you prefer to perform the setup manually, follow these steps:

1. Install dependencies:
   ```bash
   npm install
   ```

2. Deploy the TicTacToe game to your bucket:
   ```bash
   ./deploy.sh your-bucket-name
   ```

3. Enable static website hosting:
   ```bash
   ./enable-website.sh your-bucket-name
   ```

4. Apply the bucket policy to make the game publicly accessible:
   ```bash
   ./apply-policy.sh your-bucket-name
   ```

5. Configure CORS if needed:
   ```bash
   ./apply-cors.sh your-bucket-name
   ```

## Removal Process

To completely remove the TicTacToe game from your bucket:

```bash
./destroy.sh your-bucket-name
```

This will remove all files deployed by this CDK stack from your S3 bucket. Note that it will not remove the bucket itself or revert any bucket configurations (website hosting, CORS, policy).

## Troubleshooting

If you encounter any issues during deployment or setup, please refer to the [TROUBLESHOOTING.md](./TROUBLESHOOTING.md) file for common issues and their solutions.

Common issues include:
- AWS environment not bootstrapped
- Insufficient permissions
- S3 bucket configuration issues
- Region configuration

For detailed guidance on resolving these issues, see the troubleshooting guide.

## License

This project is licensed under the MIT License - see the [LICENSE](./LICENSE) file for details.
