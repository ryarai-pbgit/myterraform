# Terraform Test 1

### 1. 前提条件
08_cicd_appが完了していること。<br>
HashiCorp HCLというエクステンションをインストールしてください。

### 2. 今回の構成図
前回から変更なし。

### 3. 今回のコード
今回から2回に分けてTerraform testを実装します。<br>
2023年以降に実装された比較的新しい機能です。<br>
https://developer.hashicorp.com/terraform/language/tests<br>
今回は一番単純な複数モジュールを組み合わせずに単一モジュールで実行できるテストを実装していきます。

#### 3-1. ファイル作成
tests/というフォルダと、network_module_test.tftest.hclというファイルを作成します。<br>
このtests/というフォルダ名と.tftest.hclという拡張子は、terraform testの仕様で定められたものなので変更はしないでください。
```
  09_test/
    tests/
      network_module_test.tftest.hcl
    ・・・
```
network_module_test.tftest.hclには、下記のような内容を記載します。<br>
まず、プロバイダを指定します。
```
[network_module_test.tftest.hcl]
provider "google" {
  project     = "[your project id]"
  region      = "asia-northeast1"
}
```
次にモジュールを呼び出す際に必要な変数を記載します。<br>
```
variables {
    region = "asia-northeast1"
    zone = "asia-northeast1-a"
    vm_tags = "operation"
    ip_cidr_range = "10.1.0.0/16"
    ip_cidr_range_secondary = "172.16.0.0/16"
    range_name = "mysecondaryrange"
}
```
次にrunブロックを記載します。ここがテストの本体になります。<br>
commandには、planとapplyを指定することができます。applyにすると実際にリソースを立ち上げて、テスト完了後に削除してくれるという動きになります。<br>
moduleブロックでは、読み込むモジュールを指定します。<br>
assertブロックには、テストコードを記載します。<br>
conditionでチェック内容を記載して、error_messageにエラー時に発生するメッセージを記載します。<br>
今回はnetworkモジュールで、こちらが指定したパラメータを確認するような形で作成しています。<br>
実際に、どこまでテストをするか、という部分は、プロジェクトごとに変わってくる、まだ確固たるルールなどもない状態かと思います。（2024/05時点）<br>
github copilotをチャット機能などを使いながら進めると、かなり楽に書けるかと思います。エラーが出ても、こんなエラーが出ました、と伝えてあげる事で精度が増していきます。
```
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
```
#### 3-2. テストの実行
テストを実行します。terraform testというコマンドを実行します。<br>
```
09_test % terraform test         
tests/network_module_test.tftest.hcl... in progress
  run "network_module_test"... pass
tests/network_module_test.tftest.hcl... tearing down
tests/network_module_test.tftest.hcl... pass

Success! 1 passed, 0 failed.
```
このコマンドだけだと情報量が少なすぎますので、-verboseオプションをつけます。<br>
```
09_test % terraform test -verbose
tests/network_module_test.tftest.hcl... in progress
  run "network_module_test"... pass

Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # google_compute_firewall.myvmfirewall will be created
  + resource "google_compute_firewall" "myvmfirewall" {
      + creation_timestamp = (known after apply)
      + destination_ranges = (known after apply)
      + direction          = (known after apply)
      + enable_logging     = (known after apply)
      + id                 = (known after apply)
      + name               = "myvmfirewall"
      + network            = (known after apply)
      + priority           = 1000
      + project            = "[projectid]"
      + self_link          = (known after apply)
      + source_ranges      = [
          + "35.235.240.0/20",
        ]
      + target_tags        = [
          + "operation",
        ]

      + allow {
          + ports    = [
              + "22",
            ]
          + protocol = "tcp"
        }
    }

  # google_compute_network.myvpc will be created
  + resource "google_compute_network" "myvpc" {
      + auto_create_subnetworks                   = false
      + delete_default_routes_on_create           = false
      + gateway_ipv4                              = (known after apply)
      + id                                        = (known after apply)
      + internal_ipv6_range                       = (known after apply)
      + mtu                                       = (known after apply)
      + name                                      = "myvpc"
      + network_firewall_policy_enforcement_order = "AFTER_CLASSIC_FIREWALL"
      + numeric_id                                = (known after apply)
      + project                                   = "[projectid]"
      + routing_mode                              = (known after apply)
      + self_link                                 = (known after apply)
    }

  # google_compute_router.myrouter will be created
  + resource "google_compute_router" "myrouter" {
      + creation_timestamp = (known after apply)
      + id                 = (known after apply)
      + name               = "myrouter"
      + network            = (known after apply)
      + project            = "[projectid]"
      + region             = "asia-northeast1"
      + self_link          = (known after apply)

      + bgp {
          + advertise_mode     = "DEFAULT"
          + asn                = 64516
          + keepalive_interval = 20
        }
    }

  # google_compute_router_nat.mynat will be created
  + resource "google_compute_router_nat" "mynat" {
      + enable_dynamic_port_allocation      = (known after apply)
      + enable_endpoint_independent_mapping = (known after apply)
      + endpoint_types                      = (known after apply)
      + icmp_idle_timeout_sec               = 30
      + id                                  = (known after apply)
      + min_ports_per_vm                    = (known after apply)
      + name                                = "mynat"
      + nat_ip_allocate_option              = "AUTO_ONLY"
      + project                             = "[projectid]"
      + region                              = "asia-northeast1"
      + router                              = "myrouter"
      + source_subnetwork_ip_ranges_to_nat  = "ALL_SUBNETWORKS_ALL_IP_RANGES"
      + tcp_established_idle_timeout_sec    = 1200
      + tcp_time_wait_timeout_sec           = 120
      + tcp_transitory_idle_timeout_sec     = 30
      + udp_idle_timeout_sec                = 30

      + log_config {
          + enable = true
          + filter = "ERRORS_ONLY"
        }
    }

  # google_compute_subnetwork.mysubnet will be created
  + resource "google_compute_subnetwork" "mysubnet" {
      + creation_timestamp         = (known after apply)
      + external_ipv6_prefix       = (known after apply)
      + fingerprint                = (known after apply)
      + gateway_address            = (known after apply)
      + id                         = (known after apply)
      + internal_ipv6_prefix       = (known after apply)
      + ip_cidr_range              = "10.1.0.0/16"
      + ipv6_cidr_range            = (known after apply)
      + name                       = "mysubnet"
      + network                    = (known after apply)
      + private_ip_google_access   = (known after apply)
      + private_ipv6_google_access = (known after apply)
      + project                    = "[projectid]"
      + purpose                    = (known after apply)
      + region                     = "asia-northeast1"
      + secondary_ip_range         = [
          + {
              + ip_cidr_range = "172.16.0.0/16"
              + range_name    = "mysecondaryrange"
            },
        ]
      + self_link                  = (known after apply)
      + stack_type                 = (known after apply)
    }

Plan: 5 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  + mysubnet_selflink = (known after apply)
  + myvpc_selflink    = (known after apply)

tests/network_module_test.tftest.hcl... tearing down
tests/network_module_test.tftest.hcl... pass

Success! 1 passed, 0 failed.
```
エラーが発生する場合は、下記のようになります。
```
╷
│ Error: Test assertion failed
│ 
│   on tests/network_module_test.tftest.hcl line 68, in run "network_module_test":
│   68:     condition     = tolist(google_compute_firewall.myvmfirewall.source_ranges)[0] == "35.235.240.0/21"
│     ├────────────────
│     │ google_compute_firewall.myvmfirewall.source_ranges is set of string with 1 element
│ 
│ firewall rule source_ranges did not match expected
╵
╷
│ Error: Test assertion failed
│ 
│   on tests/network_module_test.tftest.hcl line 89, in run "network_module_test":
│   89:     condition     = anytrue([for rule in tolist(google_compute_router.myrouter.bgp) : rule.asn == 64515])
│     ├────────────────
│     │ google_compute_router.myrouter.bgp is list of object with 1 element
│ 
│ router asn did not match expected
╵
tests/network_module_test.tftest.hcl... tearing down
tests/network_module_test.tftest.hcl... fail

Failure! 0 passed, 1 failed.
```

### 4. 次回予告
次回は、networkモジュールを立ち上げてから、instanceモジュールのテストに取り組みます。

