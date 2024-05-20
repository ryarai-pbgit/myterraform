provider "google" {
  project     = "YOUR_PROJECT_ID"
  region      = "asia-northeast1"
}

run "network_setup" {

    variables {
        region = "asia-northeast1"
        zone = "asia-northeast1-a"
        vm_tags = "operation"
        ip_cidr_range = "10.1.0.0/16"
        ip_cidr_range_secondary = "172.16.0.0/16"
        range_name = "mysecondaryrange"
    }

    command = apply

    module {
      source = "./modules/network"
    }

}

run "gke_module_test" {

    variables {
        region = "asia-northeast1"
        zone = "asia-northeast1-a"
        project_id = "YOUR_PROJECT_ID"
        myvpc_self_link = run.network_setup.myvpc_selflink
        mysubnet_self_link = run.network_setup.mysubnet_selflink
        machine_type = "e2-medium"
        mysagkeroles = [
            "roles/secretmanager.viewer",
            "roles/logging.logWriter",
            "roles/monitoring.metricWriter",
            "roles/monitoring.viewer",
            "roles/stackdriver.resourceMetadata.writer",
            "roles/artifactregistry.reader",
            "roles/storage.objectViewer",
            "roles/iam.serviceAccountTokenCreator"
        ]
    }

    command = plan

    module {
        source = "./modules/gke"
    }

    # Service Account
    assert {
        condition     = google_service_account.mysagke.account_id == "mysagke"
        error_message = "google_service_account account_id did not match expected" 
    }

    assert {
        condition     = google_service_account.mysagke.display_name == "GKE service account"
        error_message = "google_service_account display_name did not match expected" 
    }

    # IAM
    assert {
        condition     = google_project_iam_member.mysagkeroles[0].role == "roles/secretmanager.viewer"
        error_message = "role did not match expected" 
    }
    assert {
        condition     = google_project_iam_member.mysagkeroles[1].role == "roles/logging.logWriter"
        error_message = "role did not match expected" 
    }
    assert {
        condition     = google_project_iam_member.mysagkeroles[2].role == "roles/monitoring.metricWriter"
        error_message = "role did not match expected" 
    }
    assert {
        condition     = google_project_iam_member.mysagkeroles[3].role == "roles/monitoring.viewer"
        error_message = "role did not match expected" 
    }
    assert {
        condition     = google_project_iam_member.mysagkeroles[4].role == "roles/stackdriver.resourceMetadata.writer"
        error_message = "role did not match expected" 
    }
    assert {
        condition     = google_project_iam_member.mysagkeroles[5].role == "roles/artifactregistry.reader"
        error_message = "role did not match expected" 
    }
    assert {
        condition     = google_project_iam_member.mysagkeroles[6].role == "roles/storage.objectViewer"
        error_message = "role did not match expected" 
    }
    assert {
        condition     = google_project_iam_member.mysagkeroles[7].role == "roles/iam.serviceAccountTokenCreator"
        error_message = "role did not match expected" 
    }

    # GKE Cluster
    assert {
        condition     = google_container_cluster.mygke-cluster.name == "mygkecluster"
        error_message = "gkecluster name did not match expected" 
    }

    assert {
        condition     =  google_container_cluster.mygke-cluster.location == var.region
        error_message = "gkecluster region did not match expected" 
    }

    assert {
        condition     =  google_container_cluster.mygke-cluster.remove_default_node_pool == true
        error_message = "gkecluster remove_default_node_pool did not match expected" 
    }

    assert {
        condition     =  google_container_cluster.mygke-cluster.initial_node_count == 1
        error_message = "gkecluster initial_node_count did not match expected" 
    }

    assert {
        condition     =  google_container_cluster.mygke-cluster.release_channel[0].channel == "STABLE"
        error_message = "gkecluster release_channel did not match expected" 
    }

    assert {
        condition     =  google_container_cluster.mygke-cluster.network == run.network_setup.myvpc_selflink
        error_message = "gkecluster network did not match expected" 
    }

    assert {
        condition     =  google_container_cluster.mygke-cluster.subnetwork == run.network_setup.mysubnet_selflink
        error_message = "gkecluster subnetwork did not match expected" 
    }

    assert {
        condition     =  google_container_cluster.mygke-cluster.deletion_protection == false
        error_message = "gkecluster deletion_protection did not match expected" 
    }

    # GKE nodepool
    assert {
        condition     =  google_container_node_pool.mygke-node-pool.name == "mygkenodepool"
        error_message = "gke node pool name did not match expected" 
    }

    assert {
        condition     =  google_container_node_pool.mygke-node-pool.location == var.region
        error_message = "gke node pool region did not match expected" 
    }

    assert {
        condition     =  google_container_node_pool.mygke-node-pool.cluster == "mygkecluster"
        error_message = "gke node pool cluster did not match expected" 
    }

    assert {
        condition     =  google_container_node_pool.mygke-node-pool.node_count == 1
        error_message = "gke node pool cluster did not match expected" 
    }

    assert {
        condition     =  google_container_node_pool.mygke-node-pool.autoscaling[0].min_node_count == 1
        error_message = "gke node pool autoscaling min_node_count did not match expected" 
    }

    assert {
        condition     =  google_container_node_pool.mygke-node-pool.autoscaling[0].max_node_count == 1
        error_message = "gke node pool autoscaling max_node_count did not match expected" 
    }

    assert {
        condition     =  google_container_node_pool.mygke-node-pool.upgrade_settings[0].max_surge == 1
        error_message = "gke node pool upgrade_settings max_surge did not match expected" 
    }

    assert {
        condition     =  google_container_node_pool.mygke-node-pool.upgrade_settings[0].max_unavailable == 0
        error_message = "gke node pool upgrade_settings max_unavailable did not match expected" 
    }

    assert {
        condition     =  google_container_node_pool.mygke-node-pool.management[0].auto_repair == true
        error_message = "gke node pool management auto_repair max_unavailable did not match expected" 
    }

    assert {
        condition     =  google_container_node_pool.mygke-node-pool.management[0].auto_upgrade == true
        error_message = "gke node pool management auto_upgrade max_unavailable did not match expected" 
    }

    assert {
        condition     =  google_container_node_pool.mygke-node-pool.node_config[0].machine_type == "e2-medium"
        error_message = "gke node pool node_config machine_type did not match expected" 
    }

    assert {
        condition     =  tolist(google_container_node_pool.mygke-node-pool.node_config[0].oauth_scopes)[0] == "https://www.googleapis.com/auth/cloud-platform"
        error_message = "gke node pool node_config oauth_scopes did not match expected" 
    }

}