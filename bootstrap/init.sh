# if running outside of Cloud Shell tutorial, uncomment - sets the current project for gcloud
#gcloud config set project $PROJECT_ID
# Set $PROJECT_ID environment variable to current project value
export PROJECT_ID=$(gcloud config get-value project)
# exit if PROJECT_ID is not set
if [[ -z "${PROJECT_ID}" ]]; then
  echo "The value of PROJECT_ID is not set. Be sure to run export PROJECT_ID=YOUR-PROJECT first"
  return
fi
# Enables the GKE API
gcloud services enable container.googleapis.com 
# Create demo cluster
echo "creating ap-demo-cluster..."
gcloud container --project "$PROJECT_ID" clusters create-auto "ap-demo-cluster" \
--region "asia-northeast1" --release-channel "regular"

echo "All done, proceed to the next step - demos!"
