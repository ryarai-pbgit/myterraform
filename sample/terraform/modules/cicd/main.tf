# Service account for cloudbuild
resource "google_service_account" "mybuildsa" {
  account_id   = "mybuildsa"
  display_name = "CloudBuild service account"
}

# add roles
resource "google_project_iam_member" "mybuildsauser" {
  count   = "${length(var.mybuildsaroles)}"
  project = var.project_id
  role    = "${element(var.mybuildsaroles, count.index)}"
  member  = "serviceAccount:${google_service_account.mybuildsa.email}"
  depends_on = [google_service_account.mybuildsa]
}

# create source repository
resource "google_sourcerepo_repository" "myrepo" {
  name = "myrepo"
}

# create artifact registry repository
resource "google_artifact_registry_repository" "myreg" {
  location      = var.region
  repository_id = "myreg"
  description   = "my docker repository"
  format        = "DOCKER"
}

# create bucket name for cloudbuild 
resource "random_string" "bucketname" {
  length = 16
  lower  = true
  upper = false
  special = false
}

# create bucket for cloudbuild
resource "google_storage_bucket" "cloudbuild_log_bucket" {
  name          = "cloudbuildlog${random_string.bucketname.result}"
  location      = var.region
  force_destroy = true

  public_access_prevention = "enforced"
}

# create cloudbuild trigger
resource "google_cloudbuild_trigger" "filename-trigger" {
  location = var.region
  service_account = google_service_account.mybuildsa.id
  trigger_template {
    branch_name = "master"
    repo_name   = "myrepo"
  }

  substitutions = {
  }

  filename = "cloudbuild.yaml"

  depends_on = [ google_service_account.mybuildsa, google_project_iam_member.mybuildsauser ]
}

# create cloudbuild worker pool
resource "google_cloudbuild_worker_pool" "mybuildpool" {
  name = "mybuildpool"
  location = var.region
  worker_config {
    disk_size_gb = 100
    machine_type = "e2-medium"
    no_external_ip = false
  }
}
