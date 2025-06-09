#!/bin/bash
set -e

AWS_REGION="eu-central-1"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

LAMBDA_DIR="infra/lambda"
LAMBDA_DOCKERFILE_NAMES=$(ls -1 $LAMBDA_DIR)

for LAMBDA in $LAMBDA_DOCKERFILE_NAMES; do
  LAMBDA_PATH="$LAMBDA_DIR/$LAMBDA"

  FILE_NAME=$(basename "$LAMBDA")
  ECR_REPO_NAME="${FILE_NAME%.Dockerfile}_lambda"
  IMAGE_URI="$ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPO_NAME:latest"

  echo "Building and pushing $ECR_REPO_NAME using $LAMBDA"

  # Create ECR repo if it doesn't exist
  aws ecr describe-repositories --repository-names "$ECR_REPO_NAME" --region $AWS_REGION >/dev/null 2>&1 || \
  aws ecr create-repository --repository-name "$ECR_REPO_NAME" --region $AWS_REGION

  aws ecr get-login-password --region $AWS_REGION | \
    docker login --username AWS --password-stdin "$ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com"

  # Build with the specified Dockerfile
  docker buildx build --platform linux/amd64 --provenance=false -t "$ECR_REPO_NAME" -f "$LAMBDA_PATH" .

  # Tag and push
  docker tag "$ECR_REPO_NAME":latest "$IMAGE_URI"
  docker push "$IMAGE_URI"

  echo "$ECR_REPO_NAME pushed to $IMAGE_URI"
done
