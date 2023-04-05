Environment preparation:
1. gcp sdk installed (gcloud).
    https://cloud.google.com/sdk/docs/install

2. terraform installed.
    https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli
    
    editor: 
3. gcloud auth application-default login
   C:\Users\willy\AppData\Roaming\gcloud\application_default_credentials.json

4. Run Terraform
    Terraform init
        Terraform validate
        Terraform fmt
    
    Terraform plan -out tf.plan
    
    Terraform state list
    Terraform console
    Terraform destroy