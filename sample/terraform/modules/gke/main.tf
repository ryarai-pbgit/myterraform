# Service account for GKE Cluster node
resource "google_service_account" "mysagke" {
  account_id   = "mysagke" 
  display_name = "GKE service account"
}

# add roles
resource "google_project_iam_member" "mysagkeroles" {
  count   = "${length(var.mysagkeroles)}"
  project = var.project_id
  role    = "${element(var.mysagkeroles, count.index)}"
  member  = "serviceAccount:${google_service_account.mysagke.email}"
  depends_on = [google_service_account.mysagke]
}

# GKE cluster(Standard)
resource "google_container_cluster" "mygke-cluster" {
  name     = "mygkecluster"
  location = var.region

  remove_default_node_pool = true
  initial_node_count       = 1

  release_channel {
    channel = "STABLE"
  }

  network    = var.myvpc_self_link
  subnetwork = var.mysubnet_self_link

  deletion_protection=false

}

# GKE nodepool
resource "google_container_node_pool" "mygke-node-pool" {
  name       = "mygkenodepool"
  location   = var.region
  cluster    = google_container_cluster.mygke-cluster.name
  node_count = 1

  autoscaling {
    min_node_count = 1
    max_node_count = 1
  }

  upgrade_settings {
    max_surge       = 1
    max_unavailable = 0
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }

  node_config {
    machine_type = var.machine_type
    service_account = google_service_account.mysagke.email
    oauth_scopes    = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }
  depends_on = [google_container_cluster.mygke-cluster]
}



