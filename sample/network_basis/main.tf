module "network" {

  source = "./modules/network"

  region = var.region
  zone = var.zone
  vm_tags = var.vm_tags

}

module "instance1" {

  source = "./modules/instance"

  region = var.region
  zone = var.zone
  vm_tags = var.vm_tags
  project_id = var.project_id
  account_id = "myvmsa1"
  vmname = "myvm1"
  mysubnet_self_link = module.network.mysubnet1_selflink
}

module "instance2" {

  source = "./modules/instance"

  region = var.region
  zone = var.zone
  vm_tags = "vm2tag"
  project_id = var.project_id
  account_id = "myvmsa2"
  vmname = "myvm2"
  mysubnet_self_link = module.network.mysubnet2_selflink
}

module "instance3" {

  source = "./modules/instance"

  region = var.region
  zone = var.zone
  vm_tags = "vm3tag"
  project_id = var.project_id
  account_id = "myvmsa3"
  vmname = "myvm3"
  mysubnet_self_link = module.network.mysubnet3_selflink
}

module "ha-vpn" {

  source = "./modules/ha-vpn"

  region = var.region
  vpc1_network_id = module.network.myvpc1_selflink
  vpc2_network_id = module.network.myvpc2_selflink
  vpc1_network_name = module.network.myvpc1_name
  vpc2_network_name = module.network.myvpc2_name
  vpc1_network_cidr = module.network.mysubnet1_cidr
  vpc2_network_cidr = module.network.mysubnet2_cidr
  vpc3_network_cidr = module.network.mysubnet3_cidr
}