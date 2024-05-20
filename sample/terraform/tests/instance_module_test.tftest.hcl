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

run "instance_module_test" {

    variables {
        region = "asia-northeast1"
        zone = "asia-northeast1-a"
        vm_tags = "operation"
        project_id = "YOUR_PROJECT_ID"
        mysubnet_self_link = run.network_setup.mysubnet_selflink
    }

    command = plan

    module {
        source = "./modules/instance"
    }

    # Service Account
    assert {
        condition     = google_service_account.myvmsa.account_id == "myvmsa"
        error_message = "google_service_account account_id did not match expected" 
    }

    assert {
        condition     = google_service_account.myvmsa.display_name == "Custom SA for VM Instance"
        error_message = "google_service_account display_name did not match expected" 
    }

    # IAM
    assert {
        condition     = google_project_iam_member.myvmsa_roles[0].role == "roles/container.admin"
        error_message = "role did not match expected" 
    }

    # VM
    assert {
        condition     = google_compute_instance.myvm.name == "myvm"
        error_message = "vm name did not match expected" 
    }

    assert {
        condition     = google_compute_instance.myvm.machine_type == "e2-medium"
        error_message = "vm machine_type did not match expected" 
    }

    assert {
        condition     = google_compute_instance.myvm.zone == var.zone
        error_message = "vm zone did not match expected" 
    }

    assert {
        condition     = tolist(google_compute_instance.myvm.tags)[0] == var.vm_tags
        error_message = "vm vm_tags did not match expected" 
    }
    
    assert {
        condition     = google_compute_instance.myvm.boot_disk[0].mode == "READ_WRITE"
        error_message = "vm subnetwork did not match expected" 
    }

    assert {
        condition     = google_compute_instance.myvm.boot_disk[0].initialize_params[0].image == "projects/debian-cloud/global/images/debian-12-bookworm-v20240312"
        error_message = "boot disk image did not match expected" 
    }

    assert {
        condition     = google_compute_instance.myvm.boot_disk[0].initialize_params[0].size == 10
        error_message = "boot disk size did not match expected" 
    }

    assert {
        condition     = google_compute_instance.myvm.boot_disk[0].initialize_params[0].type == "pd-balanced"
        error_message = "boot disk type did not match expected" 
    }

    assert {
        condition     = google_compute_instance.myvm.network_interface[0].subnetwork == run.network_setup.mysubnet_selflink
        error_message = "vm subnetwork did not match expected" 
    }

    # VMのapplyが必要なため今回は対象外にしている。
    // assert {
    //     condition     = google_compute_instance.myvm.service_account[0].email == "myvmsa@YOUR_PROJECT_ID.iam.gserviceaccount.com"
    //     error_message = "vm service_account email did not match expected" 
    // }

    assert {
        condition     = tolist(google_compute_instance.myvm.service_account[0].scopes)[0] == "https://www.googleapis.com/auth/cloud-platform"
        error_message = "vm service_account email did not match expected" 
    }

}