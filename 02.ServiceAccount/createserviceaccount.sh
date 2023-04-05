# Define variables
GCP_PROJECT="hub01-379813"
SERVICE_ACCOUNT_NAME="Terraform Automation"
SERVICE_ACCOUNT_PUBLISHER="terraform-publisher1"
TERRAFORM_PUBLISHER=$SERVICE_ACCOUNT_PUBLISHER@$GCP_PROJECT.iam.gserviceaccount.com
gcloud config set project $GCP_PROJECT
# Create Service Account
gcloud iam service-accounts create $SERVICE_ACCOUNT_PUBLISHER --display-name="$SERVICE_ACCOUNT_NAME"
# Grant Storage IAM role to Service Account
gcloud config set project $GCP_PROJECT
gcloud projects add-iam-policy-binding $GCP_PROJECT --member serviceAccount:$TERRAFORM_PUBLISHER --role roles/admin   
gcloud projects add-iam-policy-binding $GCP_PROJECT --member serviceAccount:$TERRAFORM_PUBLISHER --role roles/compute.admin
gcloud projects add-iam-policy-binding $GCP_PROJECT --member serviceAccount:$TERRAFORM_PUBLISHER --role roles/container.admin
gcloud projects add-iam-policy-binding $GCP_PROJECT --member serviceAccount:$TERRAFORM_PUBLISHER --role roles/storage.admin
# Generate Service Account Key
gcloud iam service-accounts keys create $SERVICE_ACCOUNT_PUBLISHER.json --iam-account $TERRAFORM_PUBLISHER
tr -d '\n' < $SERVICE_ACCOUNT_PUBLISHER.json > $SERVICE_ACCOUNT_PUBLISHER-online.json
# View key file
echo $(<$SERVICE_ACCOUNT_PUBLISHER-online.json)
