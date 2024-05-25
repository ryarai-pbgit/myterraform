# VPNゲートウェイを作成します。
# HA VPN Gateway 1
resource "google_compute_ha_vpn_gateway" "ha_gateway1" {
  name    = "ha-vpn-1"
  region  = var.region
  network = var.vpc1_network_id
}
# HA VPN Gateway 2
resource "google_compute_ha_vpn_gateway" "ha_gateway2" {
  name    = "ha-vpn-2"
  region  = var.region
  network = var.vpc2_network_id
}

# ルーターを作成します。
# Router 1
resource "google_compute_router" "router1" {
  name    = "ha-vpn-router1"
  region  = var.region
  network = var.vpc1_network_name
  bgp {
    asn = 64514
    advertise_mode    = "CUSTOM"
    advertised_ip_ranges {
      range = var.vpc1_network_cidr
    }
  }
}
# Router 2
resource "google_compute_router" "router2" {
  name    = "ha-vpn-router2"
  region  = var.region
  network = var.vpc2_network_name
  bgp {
    asn = 64515
    advertise_mode    = "CUSTOM"
    advertised_ip_ranges {
      range = var.vpc3_network_cidr
    }
    advertised_ip_ranges {
      range = var.vpc2_network_cidr
    }
  }
}

# VPNトンネルを作成します。
# HAなので、2つのインターフェースに、それぞれ双方向のトンネルを作成します。（なので合計4つ作る）
# VPN Tunnel 12 interface 0
resource "google_compute_vpn_tunnel" "tunnel_120" {
  name                  = "ha-vpn-tunnel-120"
  region                = var.region
  vpn_gateway           = google_compute_ha_vpn_gateway.ha_gateway1.id
  peer_gcp_gateway      = google_compute_ha_vpn_gateway.ha_gateway2.id
  shared_secret         = "a secret message"
  router                = google_compute_router.router1.id
  vpn_gateway_interface = 0
}

# VPN Tunnel 12 interface 1
resource "google_compute_vpn_tunnel" "tunnel_121" {
  name                  = "ha-vpn-tunnel-121"
  region                = var.region
  vpn_gateway           = google_compute_ha_vpn_gateway.ha_gateway1.id
  peer_gcp_gateway      = google_compute_ha_vpn_gateway.ha_gateway2.id
  shared_secret         = "a secret message"
  router                = google_compute_router.router1.id
  vpn_gateway_interface = 1
}

# VPN Tunnel 21 interface 0
resource "google_compute_vpn_tunnel" "tunnel_210" {
  name                  = "ha-vpn-tunnel-210"
  region                = var.region
  vpn_gateway           = google_compute_ha_vpn_gateway.ha_gateway2.id
  peer_gcp_gateway      = google_compute_ha_vpn_gateway.ha_gateway1.id
  shared_secret         = "a secret message"
  router                = google_compute_router.router2.id
  vpn_gateway_interface = 0
}

# VPN Tunnel 21 interface 1
resource "google_compute_vpn_tunnel" "tunnel_211" {
  name                  = "ha-vpn-tunnel-211"
  region                = var.region
  vpn_gateway           = google_compute_ha_vpn_gateway.ha_gateway2.id
  peer_gcp_gateway      = google_compute_ha_vpn_gateway.ha_gateway1.id
  shared_secret         = "a secret message"
  router                = google_compute_router.router2.id
  vpn_gateway_interface = 1
}

# ここからはルータの設定を行います。ルータも自分と対抗の2つがあり、それぞれのインターフェースが2つあります。
#（なので4つ設定を定義します）
# また、それぞれInterface（接続する端子）の設定とPeer（BGP接続するための情報）の設定を行います。

# Router 1 : VPC1側のルータの設定
# Router 1 Interface 1
resource "google_compute_router_interface" "router1_interface1" {
  name       = "router1-interface1"
  router     = google_compute_router.router1.name
  region     = var.region
  ip_range   = "169.254.0.1/30"
  vpn_tunnel = google_compute_vpn_tunnel.tunnel_120.name
}

# Router 1 Peer 1
resource "google_compute_router_peer" "router1_peer1" {
  name                      = "router1-peer1"
  router                    = google_compute_router.router1.name
  region                    = var.region
  peer_ip_address           = "169.254.0.2"
  peer_asn                  = 64515
  advertised_route_priority = 100
  interface                 = google_compute_router_interface.router1_interface1.name
}

# Router 1 Interface 2
resource "google_compute_router_interface" "router1_interface2" {
  name       = "router1-interface2"
  router     = google_compute_router.router1.name
  region     = var.region
  ip_range   = "169.254.1.2/30"
  vpn_tunnel = google_compute_vpn_tunnel.tunnel_121.name
}

# Router 1 Peer 2
resource "google_compute_router_peer" "router1_peer2" {
  name                      = "router1-peer2"
  router                    = google_compute_router.router1.name
  region                    = var.region
  peer_ip_address           = "169.254.1.1"
  peer_asn                  = 64515
  advertised_route_priority = 100
  interface                 = google_compute_router_interface.router1_interface2.name
}

# Router 2 : VPC2側のルータの設定
# Router 2 Interface 1
resource "google_compute_router_interface" "router2_interface1" {
  name       = "router2-interface1"
  router     = google_compute_router.router2.name
  region     = var.region
  ip_range   = "169.254.0.2/30"
  vpn_tunnel = google_compute_vpn_tunnel.tunnel_210.name
}

# Router 2 Peer 1
resource "google_compute_router_peer" "router2_peer1" {
  name                      = "router2-peer1"
  router                    = google_compute_router.router2.name
  region                    = var.region
  peer_ip_address           = "169.254.0.1"
  peer_asn                  = 64514
  advertised_route_priority = 100
  interface                 = google_compute_router_interface.router2_interface1.name
}

# Router 2 : VPC2側のルータの設定
# Router 2 Interface 2
resource "google_compute_router_interface" "router2_interface2" {
  name       = "router2-interface2"
  router     = google_compute_router.router2.name
  region     = var.region
  ip_range   = "169.254.1.1/30"
  vpn_tunnel = google_compute_vpn_tunnel.tunnel_211.name
}
# Router 2 Peer 2
resource "google_compute_router_peer" "router2_peer2" {
  name                      = "router2-peer2"
  router                    = google_compute_router.router2.name
  region                    = var.region
  peer_ip_address           = "169.254.1.2"
  peer_asn                  = 64514
  advertised_route_priority = 100
  interface                 = google_compute_router_interface.router2_interface2.name
}