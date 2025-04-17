#!/usr/bin/env node
import * as cdk from 'aws-cdk-lib';
import { TictactoeCdkDeployStack } from '../lib/tictactoe-cdk-deploy-stack';

const app = new cdk.App();

// Get the bucket name from context or use a default value
const bucketName = app.node.tryGetContext('bucketName');

if (!bucketName) {
  throw new Error('Please provide a bucket name using -c bucketName=your-bucket-name');
}

new TictactoeCdkDeployStack(app, 'TictactoeCdkDeployStack', {
  // Use the current AWS account and region by default
  env: { 
    account: process.env.CDK_DEFAULT_ACCOUNT, 
    region: process.env.CDK_DEFAULT_REGION 
  },
  
  // Pass the bucket name to the stack
  bucketName: bucketName,
  
  // Add a description to the CloudFormation stack
  description: 'Deploys the TicTacToe game to an existing S3 bucket',
});
