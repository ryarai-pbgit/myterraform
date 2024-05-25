# VPCを3つ作る（1つのVPCにサブネットが3つではない、VPCが3つでそれぞれにサブネット１つ）
resource "google_compute_network" "myvpc1" {
  name                    = "myvpc1"
  auto_create_subnetworks = false
}

resource "google_compute_network" "myvpc2" {
  name                    = "myvpc2"
  auto_create_subnetworks = false
}

resource "google_compute_network" "myvpc3" {
  name                    = "myvpc3"
  auto_create_subnetworks = false
}

# それぞれのVPCにサブネットを1つずつ作る
# アドレスとかもわかりやすい感じにしておく
resource "google_compute_subnetwork" "mysubnet1" {
  name          = "mysubnet1"
  ip_cidr_range = "10.0.1.0/24"
  region        = var.region
  network       = google_compute_network.myvpc1.id
}

resource "google_compute_subnetwork" "mysubnet2" {
  name          = "mysubnet2"
  ip_cidr_range = "10.0.2.0/24"
  region        = var.region
  network       = google_compute_network.myvpc2.id
}

resource "google_compute_subnetwork" "mysubnet3" {
  name          = "mysubnet3"
  ip_cidr_range = "10.0.3.0/24"
  region        = var.region
  network       = google_compute_network.myvpc3.id
}

# VM1はIAP経由で接続できる状態にする
# IAP用のファイアウォールルールを作成する
# ソースIPアドレスは、GoogleのIAPのIPアドレス範囲を指定する。
# ターゲットは、VMに付与するタグを指定する。
resource "google_compute_firewall" "myvmfirewall" {
  name    = "myvmfirewall"
  network = google_compute_network.myvpc1.self_link

  allow {
    protocol = "tcp"
    ports    = ["22"]

  }
  # source ranges for Identity-Aware Proxy
  source_ranges = ["35.235.240.0/20"]
  target_tags = [var.vm_tags]

  depends_on = [ google_compute_network.myvpc1 ]
}

# VPC1からVPC2への間の通信を許可するファイアウォールルールを作成する
# （VPC2のインバウンドルール）
resource "google_compute_firewall" "fromvpc1tovpc2" {
  name    = "fromvpc1tovpc2"
  network = google_compute_network.myvpc2.self_link

  allow {
    protocol = "icmp"

  }
  # from var.vm_tags to vm2tag
  source_ranges = ["10.0.1.0/24"]
  target_tags = ["vm2tag"]

  depends_on = [ google_compute_network.myvpc2 ]
}

# VPC1からVPC3への間の通信を許可するファイアウォールルールを作成する
# （VPC3のインバウンドルール）
resource "google_compute_firewall" "fromvpc1tovpc3" {
  name    = "fromvpc1tovpc3"
  network = google_compute_network.myvpc3.self_link

  allow {
    protocol = "icmp"

  }
  # from var.vm_tags to vm3tag
  source_ranges = ["10.0.1.0/24"]
  target_tags = ["vm3tag"]

  depends_on = [ google_compute_network.myvpc3 ]
}

# VPC2からVPC3への間の通信を許可するファイアウォールルールを作成する
# （VPC3のインバウンドルール）
resource "google_compute_firewall" "fromvpc2tovpc3" {
  name    = "fromvpc2tovpc3"
  network = google_compute_network.myvpc3.self_link

  allow {
    protocol = "icmp"

  }

  # from vm2tag to vm3tag
  source_ranges = ["10.0.2.0/24"]
  target_tags = ["vm3tag"]

  depends_on = [ google_compute_network.myvpc3 ]
}
/* 23_network_basis2では消す。
# VPCのピアリング（1と2)
resource "google_compute_network_peering" "peering12" {
  name         = "peering12"
  network      = google_compute_network.myvpc1.self_link
  peer_network = google_compute_network.myvpc2.self_link
  export_custom_routes = false
  import_custom_routes = false
}

# VPCのピアリング（2と1)
resource "google_compute_network_peering" "peering21" {
  name         = "peering21"
  network      = google_compute_network.myvpc2.self_link
  peer_network = google_compute_network.myvpc1.self_link
  export_custom_routes = false
  import_custom_routes = false
}
*/

# VPCのピアリング（2と3)
resource "google_compute_network_peering" "peering23" {
  name         = "peering23"
  network      = google_compute_network.myvpc2.self_link
  peer_network = google_compute_network.myvpc3.self_link
/* 23_network_basis2ではtrueにする
  export_custom_routes = false
  import_custom_routes = false
*/
  export_custom_routes = true
  import_custom_routes = true

}

# VPCのピアリング（3と2)
resource "google_compute_network_peering" "peering32" {
  name         = "peering32"
  network      = google_compute_network.myvpc3.self_link
  peer_network = google_compute_network.myvpc2.self_link
/* 23_network_basis2ではtrueにする
  export_custom_routes = false
  import_custom_routes = false
*/
  export_custom_routes = true
  import_custom_routes = true

}

# Routerを作成する

