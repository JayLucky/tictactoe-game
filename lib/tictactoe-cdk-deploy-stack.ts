import * as cdk from 'aws-cdk-lib';
import { Construct } from 'constructs';
import * as s3 from 'aws-cdk-lib/aws-s3';
import * as s3deploy from 'aws-cdk-lib/aws-s3-deployment';
import * as path from 'path';

export interface TictactoeCdkDeployStackProps extends cdk.StackProps {
  bucketName: string;
}

export class TictactoeCdkDeployStack extends cdk.Stack {
  constructor(scope: Construct, id: string, props: TictactoeCdkDeployStackProps) {
    super(scope, id, props);

    // Reference the existing S3 bucket
    const bucket = s3.Bucket.fromBucketName(
      this, 
      'ExistingBucket', 
      props.bucketName
    );

    // Deploy the TicTacToe game to the bucket
    new s3deploy.BucketDeployment(this, 'DeployTicTacToe', {
      sources: [s3deploy.Source.asset(path.join(__dirname, '..', 'assets'))],
      destinationBucket: bucket,
      destinationKeyPrefix: 'tictactoe', // Optional: deploy to a subfolder
      retainOnDelete: false, // Files will be removed when stack is destroyed
    });

    // Output the URL to access the game
    new cdk.CfnOutput(this, 'TicTacToeUrl', {
      value: `https://${props.bucketName}.s3.amazonaws.com/tictactoe/index.html`,
      description: 'URL to access the TicTacToe game',
    });
  }
}
