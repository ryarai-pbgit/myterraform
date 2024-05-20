# Terraform Test 2

### 1. 前提条件
09_testが完了していること。<br>
HashiCorp HCLというエクステンションをインストールしてください。

### 2. 今回の構成図
前回から変更なし。

### 3. 今回のコード
今回は、ネットワークなどベースになるインフラを立ち上げた上で実行するようなモジュールについてテストを実装します。<br>
VPCとサブネットをインフラチームから提供された後で、VMやGKEを立ち上げるようなケースを想定します。

#### 3-1. ファイル作成
tests/フォルダに、instance_module_test.tftest.hclというファイルを作成します。<br>
```
  09_test/
    tests/
      network_module_test.tftest.hcl
      instance_module_test.tftest.hcl <-- add this file
    ・・・
```
instance_module_test.tftest.hclには、下記のような内容を記載します。<br>
プロバイダ指定とnetwork_setupというrunブロックで、テスト用にネットワークをapplyします。<br>
runブロックの中に、variablesブロックを定義することで、
```
[instance_module_test.tftest.hcl]
provider "google" {
  project     = "[your project id]"
  region      = "asia-northeast1"
}

run "network_setup" {

    variables {
        region = "asia-northeast1"
        zone = "asia-northeast1-a"
        vm_tags = "operation"
        ip_cidr_range = "10.1.0.0/16"
        ip_cidr_range_secondary = "172.16.0.0/16"
        range_name = "mysecondaryrange"
    }

    command = apply

    module {
      source = "./modules/network"
    }

}
```
ちなみに、command = plan で実行すると、下記のように、only known after apply というエラーになります。<br>
```╷
│ Error: Reference to unknown value
│ 
│   on tests/instance_module_test.tftest.hcl line 32, in run "instance_module_test":
│   32:         mysubnet_self_link = run.network_setup.mysubnet_selflink
│ 
│ The value for run.network_setup.mysubnet_selflink is unknown. Run block "network_setup" is executing a "plan" operation, and the specified output value is only known after apply.
```
インスタンスモジュールのテストを記載していきます。<br>
セットアップしたネットワークのアウトプットを参照するには、run.network_setup.mysubnet_selflink のような形で参照します。<br>
なお、今回は簡単のためVMに関してはplanで確認できる範囲のみでのテストとしています。
```
[instance_module_test.tftest.hcl]
run "instance_module_test" {

    variables {
        region = "asia-northeast1"
        zone = "asia-northeast1-a"
        vm_tags = "operation"
        project_id = "YOUR_PROJECT_ID"
        mysubnet_self_link = run.network_setup.mysubnet_selflink
    }

    command = plan

    module {
        source = "./modules/instance"
    }

    # Service Account
    assert {
        condition     = google_service_account.myvmsa.account_id == "myvmsa"
        error_message = "google_service_account account_id did not match expected" 
    }

    assert {
        condition     = google_service_account.myvmsa.display_name == "Custom SA for VM Instance"
        error_message = "google_service_account display_name did not match expected" 
    }

    # IAM
    assert {
        condition     = google_project_iam_member.myvmsa_roles[0].project == "YOUR_PROJECT_ID"
        error_message = "project id did not match expected" 
    }

    assert {
        condition     = google_project_iam_member.myvmsa_roles[0].role == "roles/container.admin"
        error_message = "role did not match expected" 
    }

    # VM
    assert {
        condition     = google_compute_instance.myvm.name == "myvm"
        error_message = "vm name did not match expected" 
    }

    assert {
        condition     = google_compute_instance.myvm.machine_type == "e2-medium"
        error_message = "vm machine_type did not match expected" 
    }

    assert {
        condition     = google_compute_instance.myvm.zone == var.zone
        error_message = "vm zone did not match expected" 
    }

    assert {
        condition     = tolist(google_compute_instance.myvm.tags)[0] == var.vm_tags
        error_message = "vm vm_tags did not match expected" 
    }
    
    assert {
        condition     = google_compute_instance.myvm.boot_disk[0].mode == "READ_WRITE"
        error_message = "vm subnetwork did not match expected" 
    }

    assert {
        condition     = google_compute_instance.myvm.boot_disk[0].initialize_params[0].image == "projects/debian-cloud/global/images/debian-12-bookworm-v20240312"
        error_message = "boot disk image did not match expected" 
    }

    assert {
        condition     = google_compute_instance.myvm.boot_disk[0].initialize_params[0].size == 10
        error_message = "boot disk size did not match expected" 
    }

    assert {
        condition     = google_compute_instance.myvm.boot_disk[0].initialize_params[0].type == "pd-balanced"
        error_message = "boot disk type did not match expected" 
    }

    assert {
        condition     = google_compute_instance.myvm.network_interface[0].subnetwork == run.network_setup.mysubnet_selflink
        error_message = "vm subnetwork did not match expected" 
    }

    # VMのapplyが必要なため今回は対象外にしている。
    // assert {
    //     condition     = google_compute_instance.myvm.service_account[0].email == "myvmsa@YOUR_PROJECT_ID.iam.gserviceaccount.com"
    //     error_message = "vm service_account email did not match expected" 
    // }

    assert {
        condition     = tolist(google_compute_instance.myvm.service_account[0].scopes)[0] == "https://www.googleapis.com/auth/cloud-platform"
        error_message = "vm service_account email did not match expected" 
    }

}
```

#### 3-2. テストの実行
テストを実行します。terraform test -verpose コマンドを実行します。<br>
networkモジュールをapplyしているため、planだけの場合と比較すると時間がかかります。<br>
抜粋して実行している結果を記載します。<br>
実行中にGCPの画面を見ているとVPCが出来上がって、テストが完了すると削除されるのが見て取れます。
```
09_test % terraform test -verbose
tests/instance_module_test.tftest.hcl... in progress
  run "network_setup"... pass

# google_compute_firewall.myvmfirewall:
resource "google_compute_firewall" "myvmfirewall" {
    creation_timestamp = "2024-05-19T07:42:56.038-07:00"
・・・

  run "instance_module_test"... pass

Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # google_compute_instance.myvm will be created
  + resource "google_compute_instance" "myvm" {
      + can_ip_forward       = false
・・・

Plan: 3 to add, 0 to change, 0 to destroy.

tests/instance_module_test.tftest.hcl... tearing down
tests/instance_module_test.tftest.hcl... pass
tests/network_module_test.tftest.hcl... in progress
  run "network_module_test"... pass
・・・

tests/network_module_test.tftest.hcl... tearing down
tests/network_module_test.tftest.hcl... pass

Success! 3 passed, 0 failed.
```

### 4. 次回予告
次回は、gke, cicdモジュールのテストを実行します。

