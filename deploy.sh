#!/bin/bash
set -e

# export PROJECT_ID=project2-382305
# export REGION=us-central1
# export VPC_NETWORK=default
# export GKE_CLUSTER_NAME=dify
# export REDIS_CLUSTER_NAME=dify
# export DB_CLUSTER_NAME=dify
# export DB_PASSWORD=">)4-Z4rTL7Ai'23H"
# export DIFY_VERSION=0.6.11
# export ZONE=${REGION}-b
# export GOOGLE_STORAGE_BUCKET_NAME=pwm-dify-001

echo "Enable services ... "
gcloud services enable compute.googleapis.com \
    container.googleapis.com \
    aiplatform.googleapis.com \
    sqladmin.googleapis.com \
    redis.googleapis.com \
    servicenetworking.googleapis.com \
    --project ${PROJECT_ID}


echo "Create DB instance ..."
gcloud sql instances create ${DB_CLUSTER_NAME} \
    --project=${PROJECT_ID} \
    --database-version=POSTGRES_15 --cpu=2 --memory=8GiB \
    --region=${REGION} \
    --root-password=${DB_PASSWORD} \
    --network=${VPC_NETWORK} \
    --storage-size=20 \
    --async


echo "Create Redis instance ..."
gcloud redis instances create ${REDIS_CLUSTER_NAME} \
    --project=${PROJECT_ID}  \
    --tier=basic \
    --size=5 \
    --region=${REGION} \
    --redis-version=redis_6_x \
    --network=${VPC_NETWORK} \
    --zone=${ZONE} \
    --connect-mode=private-service-access \
    --async


echo "Create service account for dify ... "
gcloud iam service-accounts create dify-sa \
    --description="Service account for dify" \
    --display-name="dify-sa" \
    --project=${PROJECT_ID}
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
    --member=serviceAccount:dify-sa@${PROJECT_ID}.iam.gserviceaccount.com \
    --role='roles/editor' \
    --condition=None \
    --quiet > /dev/null


echo "Create GKE instance ..."
gcloud container clusters create ${GKE_CLUSTER_NAME} \
    --project ${PROJECT_ID} \
    --network ${VPC_NETWORK} \
    --num-nodes 1 \
    --enable-autoscaling --total-min-nodes "1" --total-max-nodes "3" --location-policy "BALANCED" \
    --machine-type "n2-standard-4" \
    --addons HorizontalPodAutoscaling,HttpLoadBalancing,GcePersistentDiskCsiDriver \
    --scopes "https://www.googleapis.com/auth/cloud-platform" \
    --region ${REGION} \
    --node-locations ${ZONE} \
    --service-account dify-sa@${PROJECT_ID}.iam.gserviceaccount.com \
    --async


waitTime=0
ready="ok"
until [[ $(gcloud container clusters describe ${GKE_CLUSTER_NAME} --region ${REGION} --project ${PROJECT_ID} --format json | jq -r .status) == "RUNNING" ]] && [[ $(gcloud sql instances describe ${DB_CLUSTER_NAME} --project ${PROJECT_ID} --format json| jq -r .state) == "RUNNABLE" ]] && [[ $(gcloud redis instances describe ${REDIS_CLUSTER_NAME} --region ${REGION} --project ${PROJECT_ID} --format json| jq -r .state) == "READY" ]]; do
    sleep 10;
    waitTime=$(expr ${waitTime} + 10);
    echo "waited ${waitTime} secconds for GKE/DB/Redis to be ready ...";
    if [ ${waitTime} -gt 600 ]; then
        ready="failed";
        echo "Wait too long, deploy failed.";
        exit 1;
    fi
done

echo "Create dify database ... "
gcloud sql databases create dify --project=${PROJECT_ID} --instance=${DB_CLUSTER_NAME}

export REDIS_HOST=$(gcloud redis instances describe ${REDIS_CLUSTER_NAME} --project=${PROJECT_ID} --region=${REGION} --format json|jq -r .host)
export DB_HOST=$(gcloud sql instances describe ${DB_CLUSTER_NAME} --project=${PROJECT_ID} --format json|jq -r '.ipAddresses[] | select( .type | contains("PRIVATE")) | .ipAddress')

echo "Get GKE Cluster Credential ..."
gcloud container clusters get-credentials ${GKE_CLUSTER_NAME} \
    --region ${REGION} \
    --project ${PROJECT_ID}


echo "Deply Dify to GKE ..."
envsubst < kubernetes/api.yaml | kubectl apply -f -
envsubst < kubernetes/worker.yaml | kubectl apply -f -
envsubst < kubernetes/web.yaml | kubectl apply -f -
kubectl apply -f kubernetes/weaviate.yaml
kubectl apply -f kubernetes/sandbox.yaml
kubectl apply -f kubernetes/ingress.yaml


# Wait Ingrss be ready
until [[ $(kubectl get ingress -o jsonpath='{.items[].status.loadBalancer.ingress[].ip}') != "" ]];do
    sleep 30;
    echo "Waiting ingress to be ready ..."
done
ip=$(kubectl get ingress -o jsonpath='{.items[].status.loadBalancer.ingress[].ip}')
sleep 180
echo "Please access: http://$ip"
