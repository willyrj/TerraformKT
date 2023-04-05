/**
 * Copyright 2022 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

# tfdoc:file:description Service identities and supporting resources.

locals {
  _service_accounts_cmek_service_dependencies = {
    "composer" : [
      "composer",
      "artifactregistry", "container-engine", "compute", "pubsub", "storage"
    ]
    "dataflow" : ["dataflow", "compute"]
  }
  _service_accounts_robot_services = {
    aiplatform        = "service-%s@gcp-sa-aiplatform"
    apigee            = "service-%s@gcp-sa-apigee"
    artifactregistry  = "service-%s@gcp-sa-artifactregistry"
    bq                = "bq-%s@bigquery-encryption"
    cloudasset        = "service-%s@gcp-sa-cloudasset"
    cloudbuild        = "service-%s@gcp-sa-cloudbuild"
    cloudfunctions    = "service-%s@gcf-admin-robot"
    cloudrun          = "service-%s@serverless-robot-prod"
    composer          = "service-%s@cloudcomposer-accounts"
    compute           = "service-%s@compute-system"
    container-engine  = "service-%s@container-engine-robot"
    containerregistry = "service-%s@containerregistry"
    dataflow          = "service-%s@dataflow-service-producer-prod"
    dataproc          = "service-%s@dataproc-accounts"
    fleet             = "service-%s@gcp-sa-gkehub"
    gae-flex          = "service-%s@gae-api-prod"
    # TODO: deprecate gcf
    gcf = "service-%s@gcf-admin-robot"
    # TODO: jit?
    gke-mcs                  = "service-%s@gcp-sa-mcsd"
    monitoring-notifications = "service-%s@gcp-sa-monitoring-notification"
    multicluster-ingress     = "service-%s@gcp-sa-multiclusteringress"
    multicluster-discovery   = "service-%s@gcp-sa-mcsd"
    notebooks                = "service-%s@gcp-sa-notebooks"
    pubsub                   = "service-%s@gcp-sa-pubsub"
    secretmanager            = "service-%s@gcp-sa-secretmanager"
    servicemesh              = "service-%s@gcp-sa-servicemesh"
    sql                      = "service-%s@gcp-sa-cloud-sql"
    sqladmin                 = "service-%s@gcp-sa-cloud-sql"
    storage                  = "service-%s@gs-project-accounts"
  }
  service_accounts_default = {
    compute = "${local.project.number}-compute@developer.gserviceaccount.com"
    gae     = "${local.project.project_id}@appspot.gserviceaccount.com"
  }
  service_account_cloud_services = (
    "${local.project.number}@cloudservices.gserviceaccount.com"
  )
  service_accounts_robots = merge(
    {
      for k, v in local._service_accounts_robot_services :
      k => "${format(v, local.project.number)}.iam.gserviceaccount.com"
    },
    {
      gke-mcs-importer = "${local.project.project_id}.svc.id.goog[gke-mcs/gke-mcs-importer]"
    }
  )
  # JIT-ed service accounts are created without default roles granted, these needs to be assigned manually to them
  # Roles can be found here: https://cloud.google.com/iam/docs/service-agents
  # Remember to update "Service identities requiring manual IAM grants" in README.md when updating this list
  service_accounts_jit_services = [
    "apigee.googleapis.com",              # grant roles/apigee.serviceAgent to apigee
    "artifactregistry.googleapis.com",    # grant roles/artifactregistry.serviceAgent to artifactregistry
    "cloudasset.googleapis.com",          # grant roles/cloudasset.serviceAgent to cloudasset
    "cloudbuild.googleapis.com",          # grant roles/cloudbuild.builds.builder to cloudbuild
    "gkehub.googleapis.com",              # grant roles/gkehub.serviceAgent to fleet
    "multiclusteringress.googleapis.com", # grant roles/multiclusteringress.serviceAgent to multicluster-ingress
    "pubsub.googleapis.com",              # grant roles/pubsub.serviceAgent to pubsub
    "meshconfig.googleapis.com",          # grant roles/anthosservicemesh.serviceAgent to meshconfig
    "notebooks.googleapis.com",           # no grants needed
    "secretmanager.googleapis.com",       # no grants needed
    "sqladmin.googleapis.com",            # grant roles/cloudsql.serviceAgent to sqladmin (TODO: verify)
  ]
  service_accounts_cmek_service_keys = distinct(flatten([
    for s in keys(var.service_encryption_key_ids) : [
      for ss in try(local._service_accounts_cmek_service_dependencies[s], [s]) : [
        for key in var.service_encryption_key_ids[s] : {
          service = ss
          key     = key
        } if key != null
      ]
    ]
  ]))
}

data "google_storage_project_service_account" "gcs_sa" {
  count      = contains(var.services, "storage.googleapis.com") ? 1 : 0
  project    = local.project.project_id
  depends_on = [google_project_service.project_services]
}

data "google_bigquery_default_service_account" "bq_sa" {
  count      = contains(var.services, "bigquery.googleapis.com") ? 1 : 0
  project    = local.project.project_id
  depends_on = [google_project_service.project_services]
}

resource "google_project_service_identity" "servicenetworking" {
  provider   = google-beta
  count      = contains(var.services, "servicenetworking.googleapis.com") ? 1 : 0
  project    = local.project.project_id
  service    = "servicenetworking.googleapis.com"
  depends_on = [google_project_service.project_services]
}

resource "google_project_iam_member" "servicenetworking" {
  count   = contains(var.services, "servicenetworking.googleapis.com") ? 1 : 0
  project = local.project.project_id
  role    = "roles/servicenetworking.serviceAgent"
  member  = "serviceAccount:${google_project_service_identity.servicenetworking.0.email}"
}

# Secret Manager SA created just in time, we need to trigger the creation.
resource "google_project_service_identity" "jit_si" {
  for_each   = setintersection(var.services, local.service_accounts_jit_services)
  provider   = google-beta
  project    = local.project.project_id
  service    = each.value
  depends_on = [google_project_service.project_services]
}

resource "google_kms_crypto_key_iam_member" "service_identity_cmek" {
  for_each = {
    for service_key in local.service_accounts_cmek_service_keys :
    "${service_key.service}.${service_key.key}" => service_key
    if service_key != service_key.key
  }
  crypto_key_id = each.value.key
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:${local.service_accounts_robots[each.value.service]}"
  depends_on = [
    google_project.project,
    google_project_service.project_services,
    google_project_service_identity.jit_si,
    data.google_bigquery_default_service_account.bq_sa,
    data.google_project.project,
    data.google_storage_project_service_account.gcs_sa,
  ]
}

resource "google_project_default_service_accounts" "default_service_accounts" {
  count          = upper(var.default_service_account) == "KEEP" ? 0 : 1
  action         = upper(var.default_service_account)
  project        = local.project.project_id
  restore_policy = "REVERT_AND_IGNORE_FAILURE"
  depends_on     = [google_project_service.project_services]
}
