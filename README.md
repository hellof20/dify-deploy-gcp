# Deploy Dify on Google Cloud
- Data is stored in Cloud SQL and Memstore for Redis to improve durability, and the components of Dify are deployed in GKE to improve reliability and scalability.
- Cloud Armor and Global Load Balancing can provide global acceleration capabilities, DDoS protection, and WAF strategies.

## Architect
![image](https://github.com/hellof20/dify-deploy-gcp/assets/8756642/e8064b98-b46c-4e92-beb5-5144f287e76a)

## How to use
[![Open in Cloud Shell](https://gstatic.com/cloudssh/images/open-btn.svg)](https://shell.cloud.google.com/cloudshell/editor?cloudshell_git_repo=https://github.com/hellof20/dify-deploy-gcp.git)
- set parameters
```
export PROJECT_ID=speedy-victory-336109
export REGION=us-central1
export VPC_NETWORK=myvpc
export GKE_CLUSTER_NAME=dify
export REDIS_CLUSTER_NAME=dify
export DB_CLUSTER_NAME=dify
export DB_PASSWORD=">)4-Z4rTL7Ai'23H"
export DIFY_VERSION=0.6.9
export ZONE=${REGION}-b
```
- deploy
```
bash deploy.sh
```
- wait for the script to finish, it takes about 15 minutes

## Clean resources
- set parameters
```
PROJECT_ID=speedy-victory-336109
REGION=us-central1
VPC_NETWORK=myvpc
GKE_CLUSTER_NAME=dify
REDIS_CLUSTER_NAME=dify
DB_CLUSTER_NAME=dify
```
2. clean
```
bash clean.sh
```

## Upgrade Dify version
todo
