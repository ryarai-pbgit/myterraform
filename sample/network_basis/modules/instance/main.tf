# VM用のサービスアカウントを作成する
resource "google_service_account" "myvmsa" {
  account_id   = var.account_id
  display_name = "Custom SA for VM Instance"
}

# 作成したサービスアカウントにIAMロールを付与する。
resource "google_project_iam_member" "myvmsa_roles" {
  count   = "${length(var.myvmsa_roles)}"
  project = var.project_id
  role    = "${element(var.myvmsa_roles, count.index)}"
  member  = "serviceAccount:${google_service_account.myvmsa.email}"
  depends_on = [google_service_account.myvmsa]
}

# VM本体を作成する
resource "google_compute_instance" "myvm" {
  name         = var.vmname
  machine_type = var.machine_type
  zone         = var.zone
  tags         = [var.vm_tags]

  boot_disk {
    mode = "READ_WRITE"
    initialize_params {
      image = var.boot_disk_image
      size  = var.boot_disk_size
      type  = var.boot_disk_type
    }
  }

  network_interface {
    subnetwork = var.mysubnet_self_link
  }

  service_account {
    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    email  = google_service_account.myvmsa.email
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }

  lifecycle {
    ignore_changes = [
      metadata
    ]
  }

}
