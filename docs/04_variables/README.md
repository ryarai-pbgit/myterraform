# Variables

### 1. 前提条件
03_first_natが完了していること。

### 2. 今回の構成図
前回から変更なし

### 3. 今回のコード
ローカル変数を外部ファイルに定義する。<br>
クラウドの構造をmain.tfで定義して、そのパラメータを外部で定義することで、パラメータ違いの環境を増やすときはmain.tfを再利用することができる。<br>
なお、main.tf内でローカル変数が必要な場合は、これまで通りローカル変数として定義すれば良い。<br>
main.tf内の下記のローカル変数を対象とする。
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
```
下記のようにvariables.tfというファイルを作成する。
```
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

variable "range_name" {
  type    = string
  description = "The name of the secondary IP range."
  default = "mysecondaryrange"
}

variable "vm_tags" {
  type    = string
  description = "The tags for the VM."
  default = "operation"
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
これに伴い、main.tfの方はlocal.xxxxxと記載してローカル変数を参照していたところを、var.xxxxxに変更する。
```
[変更前の例]
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

[変更後の例]
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
```

### 4. 動作確認
エラーなく実行できればOK。

### 5. 次回予告
モジュール化（再利用できる部品化）を行います。