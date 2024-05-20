provider "google" {
  project     = "YOUR_PROJECT_ID"
  region      = "asia-northeast1"
}

variables {
    region = "asia-northeast1"
    zone = "asia-northeast1-a"
    vm_tags = "operation"
    ip_cidr_range = "10.1.0.0/16"
    ip_cidr_range_secondary = "172.16.0.0/16"
    range_name = "mysecondaryrange"
}

run "network_module_test" {

  command = plan

  module {
    source = "./modules/network"
  }

  # VPC
  assert {
    condition     = google_compute_network.myvpc.name == "myvpc"
    error_message = "vpc name did not match expected" 
  }

  assert {
    condition     = google_compute_network.myvpc.auto_create_subnetworks == false
    error_message = "vpc auto_create_subnetworks did not match expected" 
  }

  # Subnet
  assert {
    condition     = google_compute_subnetwork.mysubnet.name == "mysubnet"
    error_message = "subnet name did not match expected" 
  }

  assert {
    condition     = google_compute_subnetwork.mysubnet.ip_cidr_range == var.ip_cidr_range
    error_message = "subnet ip_cidr_range did not match expected" 
  }

  assert {
    condition     = google_compute_subnetwork.mysubnet.region == var.region
    error_message = "subnet region did not match expected" 
  }

  # Firewall
  assert {
    condition     = google_compute_firewall.myvmfirewall.name == "myvmfirewall"
    error_message = "firewall name did not match expected" 
  }
  
  
  assert {
    condition     = anytrue([for rule in google_compute_firewall.myvmfirewall.allow : rule.protocol == "tcp"])
    error_message = "firewall rule allow protocol did not match expected" 
  }

  assert {
    condition     = anytrue([for rule in google_compute_firewall.myvmfirewall.allow : tolist(rule.ports)[0] == "22"])
    error_message = "firewall rule allow ports did not match expected" 
  }

  assert {
    condition     = tolist(google_compute_firewall.myvmfirewall.source_ranges)[0] == "35.235.240.0/20"
    error_message = "firewall rule source_ranges did not match expected" 
  }

  assert {
    condition     = tolist(google_compute_firewall.myvmfirewall.target_tags)[0] == var.vm_tags
    error_message = "firewall rule target_tags did not match expected" 
  }

  # Router
  assert {
    condition     = google_compute_router.myrouter.name == "myrouter"
    error_message = "router name did not match expected" 
  }

  assert {
    condition     = google_compute_router.myrouter.region == var.region
    error_message = "router region did not match expected" 
  }

  assert {
    condition     = anytrue([for rule in tolist(google_compute_router.myrouter.bgp) : rule.asn == 64516])
    error_message = "router asn did not match expected" 
  }

  # NAT
  assert {
    condition     = google_compute_router_nat.mynat.name == "mynat"
    error_message = "nat name did not match expected" 
  }

  assert {
    condition     = google_compute_router_nat.mynat.router == "myrouter"
    error_message = "nat router name did not match expected" 
  }

  assert {
    condition     = google_compute_router_nat.mynat.region == var.region
    error_message = "nat router name did not match expected" 
  }

  assert {
    condition     = google_compute_router_nat.mynat.nat_ip_allocate_option == "AUTO_ONLY"
    error_message = "nat nat_ip_allocate_option did not match expected" 
  }

  assert {
    condition     = google_compute_router_nat.mynat.source_subnetwork_ip_ranges_to_nat == "ALL_SUBNETWORKS_ALL_IP_RANGES"
    error_message = "nat source_subnetwork_ip_ranges_to_nat did not match expected" 
  }

  assert {
    condition     = anytrue([for rule in google_compute_router_nat.mynat.log_config : rule.enable == true])
    error_message = "nat log_config enable did not match expected" 
  }

  assert {
    condition     = anytrue([for rule in google_compute_router_nat.mynat.log_config : rule.filter == "ERRORS_ONLY"])
    error_message = "nat log_config filter did not match expected" 
  }

}