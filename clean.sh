#!/bin/bash
PROJECT_ID=speedy-victory-336109
REGION=us-central1
VPC_NETWORK=myvpc
GKE_CLUSTER_NAME=dify
REDIS_CLUSTER_NAME=dify
DB_CLUSTER_NAME=dify

echo "Deleting GKE resource ..."
gcloud container clusters delete ${GKE_CLUSTER_NAME} --project ${PROJECT_ID} --region ${REGION} --async --quiet > /dev/null

echo "Deleting Redis ..."
gcloud redis instances delete ${REDIS_CLUSTER_NAME} --region ${REGION} --project ${PROJECT_ID} --async --quiet > /dev/null

echo "Deleting DB ..."
gcloud sql instances delete ${DB_CLUSTER_NAME} --project ${PROJECT_ID} --async --quiet > /dev/null

echo "Deleteing service account ..."
gcloud projects remove-iam-policy-binding ${PROJECT_ID} \
    --member=serviceAccount:dify-sa@${PROJECT_ID}.iam.gserviceaccount.com \
    --role='roles/editor' \
    --condition=None \
    --quiet > /dev/null

gcloud iam service-accounts delete dify-sa@${PROJECT_ID}.iam.gserviceaccount.com --project=${PROJECT_ID} --quiet

echo "Completed, the resource will be deleted asynchronously."