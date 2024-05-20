# Modules

### 1. 前提条件
04_variablesが完了していること。

### 2. 今回の構成図
前回から変更なし

### 3. 今回のコード
main.tfの内容をネットワーク部品（network）とインスタンス部品（instance）に分割していきます。<br>
#### 3-1. フォルダ構成
フォルダ構成を下記のようにします。<br>
```
05_module/
  main.tf
  variables.tf
  provider.tf
    modules/
      network/
        main.tf
        variables.tf
        output.tf
      instance/
        main.tf
        variables.tf
        output.tf
```
#### 3-2. networkモジュール
modules/network/フォルダ配下に、下記の内容を記載します。<br>
元々main.tfに記載していたネットワーク関連のリソースの定義を抜粋していきます。<br>
また、後にVMを作成する際に、サブネットのセルフリンクが必要なのでoutput.tfで書き出しています。<br>
variables.tfで定義した変数でdefaultの値を記載していない変数は、モジュール呼び出し時に指定することができます。<br>
```
[main.tf]
resource "google_compute_network" "myvpc" {
  name                    = "myvpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "mysubnet" {
  name          = "mysubnet"
  ip_cidr_range = var.ip_cidr_range
  region        = var.region
  network       = google_compute_network.myvpc.id
  secondary_ip_range {
    range_name    = var.range_name
    ip_cidr_range = var.ip_cidr_range_secondary
  }
  depends_on = [ google_compute_network.myvpc ]
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
  target_tags = [var.vm_tags]

  depends_on = [ google_compute_network.myvpc ]
}

resource "google_compute_router" "myrouter" {
  name    = "myrouter"
  region  = var.region
  network = google_compute_network.myvpc.id

  bgp {
    asn = 64516
  }

  depends_on = [ google_compute_network.myvpc ]

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

  depends_on = [ google_compute_router.myrouter ]

}

[variables.tf]
variable "region" {
  type    = string
  description = "The region for the VPC."
}

variable "zone" {
  type    = string
  description = "The zone for the VM."
}

variable "vm_tags" {
  type    = string
  description = "The tags for the VM."
}

variable "ip_cidr_range" {
  type    = string
  description = "The IP CIDR range for the VPC."
  default = "10.1.0.0/16"
}

variable "ip_cidr_range_secondary" {
  type    = string
  description = "The IP CIDR range for the secondary IP range."
  default = "172.16.0.0/16"
}

variable "range_name" {
  type    = string
  description = "The name of the secondary IP range."
  default = "mysecondaryrange"
}

[output.tf]
output "mysubnet_selflink" {
    value = google_compute_subnetwork.mysubnet.self_link
    description = "value of mysubnet self link"
}
```
#### 3-3. instanceモジュール
modules/instance/フォルダ配下に、下記の内容を記載します。
```
[main.tf]
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

}

[variables.tf]
variable "region" {
  type    = string
  description = "The region for the VPC."
}

variable "zone" {
  type    = string
  description = "The zone for the VM."
}

variable "vm_tags" {
  type    = string
  description = "The tags for the VM."
}

variable "mysubnet_self_link" {
  type    = string
  description = "VM subnet SelfLink."
}

variable "machine_type" {
  type    = string
  description = "The machine type for the VM."
  default = "e2-medium"
}

variable "boot_disk_image" {
  type    = string
  description = "The image for the boot disk."
  default = "projects/debian-cloud/global/images/debian-12-bookworm-v20240312"
}

variable "boot_disk_size" {
  type    = number
  description = "The size of the boot disk."
  default = 10
}

variable "boot_disk_type" {
  type    = string
  description = "The type of the boot disk."
  default = "pd-balanced"
}
```
#### 3-4. ルートフォルダ
modules/フォルダ配下に、下記の内容を記載します。<br>
source句でモジュールフォルダのパスを指定して読み込みます。<br>
networkモジュールで出力した値は、module.network.xxxxxxの形で参照できます。
```
[main.tf]
module "network" {

  source = "./modules/network"

  region = var.region
  zone = var.zone
  vm_tags = var.vm_tags

}

module "instance" {

  source = "./modules/instance"

  region = var.region
  zone = var.zone
  vm_tags = var.vm_tags
  mysubnet_self_link = module.network.mysubnet_selflink

}

[variables.tf]
variable "region" {
  type    = string
  description = "The region for the VPC."
  default = "asia-northeast1"
}

variable "zone" {
  type    = string
  description = "The zone for the VM."
  default = "asia-northeast1-a"
}

variable "vm_tags" {
  type    = string
  description = "The tags for the VM."
  default = "operation"
}

```

### 4. 動作確認
エラーなく実行できればOK。

### 5. 次回予告
GKEクラスタ、CICDパイプライン、アプリケーションデプロイ、および、Terraform testについて、順に実施していきます。