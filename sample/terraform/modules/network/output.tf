output "myvpc_selflink" {
    value = google_compute_network.myvpc.self_link
    description = "value of myvpc self link"
}

output "mysubnet_selflink" {
    value = google_compute_subnetwork.mysubnet.self_link
    description = "value of mysubnet self link"
}
