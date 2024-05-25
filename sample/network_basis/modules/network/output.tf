output "myvpc1_selflink" {
    value = google_compute_network.myvpc1.self_link
    description = "value of myvpc1 self link"
}

output "myvpc2_selflink" {
    value = google_compute_network.myvpc2.self_link
    description = "value of myvpc2 self link"
}

output "myvpc3_selflink" {
    value = google_compute_network.myvpc3.self_link
    description = "value of myvpc3 self link"
}

output "myvpc1_name" {
    value = google_compute_network.myvpc1.name
    description = "value of vpc1 name"
}

output "myvpc2_name" {
    value = google_compute_network.myvpc2.name
    description = "value of vpc2 name"
}
output "myvpc3_name" {
    value = google_compute_network.myvpc3.name
    description = "value of vpc3 name"
}

output "mysubnet1_selflink" {
    value = google_compute_subnetwork.mysubnet1.self_link
    description = "value of mysubnet1 self link"
}

output "mysubnet2_selflink" {
    value = google_compute_subnetwork.mysubnet2.self_link
    description = "value of mysubnet2 self link"
}

output "mysubnet3_selflink" {
    value = google_compute_subnetwork.mysubnet3.self_link
    description = "value of mysubnet3 self link"
}

output "mysubnet1_cidr" {
    value = google_compute_subnetwork.mysubnet1.ip_cidr_range
    description = "value of mysubnet1 cidr"
}

output "mysubnet2_cidr" {
    value = google_compute_subnetwork.mysubnet2.ip_cidr_range
    description = "value of mysubnet3 cidr"
}

output "mysubnet3_cidr" {
    value = google_compute_subnetwork.mysubnet3.ip_cidr_range
    description = "value of mysubnet3 cidr"
}
