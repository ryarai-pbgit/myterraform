# First VM

### 1. 前提条件
02_first_vmが完了していること。

### 2. 今回の構成図
Router, NATを作成する。
![vm](asset/03.png "vm")

### 3. 今回のコード
main.tfを下記のように作成する。
```
locals {
  ip_cidr_range = "10.1.0.0/16"
  ip_cidr_range_secondary = "172.16.0.0/16"
  region = "asia-northeast1"
  zone = "asia-northeast1-a"
  range_name = "mysecondaryrange"
  vm_tags = "operation"
  machine_type = "e2-medium"
  boot_disk_image = "projects/debian-cloud/global/images/debian-12-bookworm-v20240312"
  boot_disk_size = 10
  boot_disk_type = "pd-balanced"
}

resource "google_compute_network" "myvpc" {
  name                    = "myvpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "mysubnet" {
  name          = "mysubnet"
  ip_cidr_range = local.ip_cidr_range
  region        = local.region
  network       = google_compute_network.myvpc.id
  secondary_ip_range {
    range_name    = local.range_name
    ip_cidr_range = local.ip_cidr_range_secondary
  }
  depends_on = [ google_compute_network.myvpc ]
}

# VM用のサービスアカウントを作成する
resource "google_service_account" "myvmsa" {
  account_id   = "myvmsa"
  display_name = "Custom SA for VM Instance"
}

# 作成したサービスアカウントにIAMロールを付与する。
# count構文を使う題材として、後ほど実施する。

# VM本体を作成する
resource "google_compute_instance" "myvm" {
  name         = "myvm"
  machine_type = local.machine_type
  zone         = local.zone
  tags         = [local.vm_tags]

  boot_disk {
    mode = "READ_WRITE"
    initialize_params {
      image = local.boot_disk_image
      size  = local.boot_disk_size
      type  = local.boot_disk_type
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.mysubnet.self_link
  }

  service_account {
    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    email  = google_service_account.myvmsa.email
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }

}

# IAP用のファイアウォールルールを作成する
# ソースIPアドレスは、GoogleのIAPのIPアドレス範囲を指定する。
# ターゲットは、VMに付与するタグを指定する。
resource "google_compute_firewall" "myvmfirewall" {
  name    = "myvmfirewall"
  network = google_compute_network.myvpc.self_link

  allow {
    protocol = "tcp"
    ports    = ["22"]

  }
  # source ranges for Identity-Aware Proxy
  source_ranges = ["35.235.240.0/20"]
  target_tags = [local.vm_tags]
}

##### 03_first_nat add start #####
resource "google_compute_router" "myrouter" {
  name    = "myrouter"
  region  = local.region
  network = google_compute_network.myvpc.id

  bgp {
    asn = 64516
  }
}

resource "google_compute_router_nat" "mynat" {
  name                               = "mynat"
  router                             = google_compute_router.myrouter.name
  region                             = google_compute_router.myrouter.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}
##### 03_first_nat add end #####
```
前回と同じように下記のようにコマンドを実行する。
```
% terraform init
% terraform plan
% terraform apply --auto-approve
```

### 4. 動作確認
VMに接続してhttpbin.orgなどインターネット越しにリクエストして、応答が返ることを確認する。

### 5. 次回予告
AWSの時ほどではないですが、長くなってきているので、次回から段階的にリファクタしていきます。<br>
Terraformらしい書き方にする他、Terraformの仕組みにも触れたりしながら進めます。