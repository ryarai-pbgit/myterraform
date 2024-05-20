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
  project_id = var.project_id
  mysubnet_self_link = module.network.mysubnet_selflink
}

module "gke" {

  source = "./modules/gke"

  region = var.region
  zone = var.zone
  myvpc_self_link = module.network.myvpc_selflink
  project_id = var.project_id
  mysubnet_self_link = module.network.mysubnet_selflink
}

module "cicd" {

  source = "./modules/cicd"

  region = var.region
  project_id = var.project_id
}
