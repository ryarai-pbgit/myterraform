# Terraform Test 4

### 1. 前提条件
11_test_3が完了していること。<br>
HashiCorp HCLというエクステンションをインストールしてください。

### 2. 今回の構成図
前回から変更なし。

### 3. 今回のコード
今回は、CICDのテストコードを実施していきます。

#### 3-1. ファイル作成
tests/フォルダに、cicd_module_test.tftest.hclというファイルを作成します。<br>
```
  09_test/
    tests/
      network_module_test.tftest.hcl
      instance_module_test.tftest.hcl
      gke_module_test.tftest.hcl 
      cicd_module_test.tftest.hcl <-- add this file
    ・・・
```
cicd_module_test.tftest.hclには、下記のような内容を記載します。<br>
今回は、network_setupは不要です。
```
[cicd_module_test.tftest.hcl]
provider "google" {
  project     = "[your project id]"
  region      = "asia-northeast1"
}

run "cicd_module_test" {

    variables {
        region = "asia-northeast1"
        project_id = "YOUR_PROJECT_ID"
        mybuildsaroles = [
            "roles/cloudbuild.builds.builder",
            "roles/container.developer",
            "roles/secretmanager.secretAccessor",
        ]
    }

    command = plan

    module {
        source = "./modules/cicd"
    }

    # Service Account
    assert {
        condition     = google_service_account.mybuildsa.account_id == "mybuildsa"
        error_message = "google_service_account account_id did not match expected" 
    }

    assert {
        condition     = google_service_account.mybuildsa.display_name == "CloudBuild service account"
        error_message = "google_service_account display_name did not match expected" 
    }

    # IAM
    assert {
        condition     = google_project_iam_member.mybuildsauser[0].role == "roles/cloudbuild.builds.builder"
        error_message = "role did not match expected" 
    }
    assert {
        condition     = google_project_iam_member.mybuildsauser[1].role == "roles/container.developer"
        error_message = "role did not match expected" 
    }
    assert {
        condition     = google_project_iam_member.mybuildsauser[2].role == "roles/secretmanager.secretAccessor"
        error_message = "role did not match expected" 
    }

    # Source Repository
    assert {
        condition     = google_sourcerepo_repository.myrepo.name == "myrepo"
        error_message = "google_sourcerepo_repository name did not match expected" 
    }

    # Artifact Registry
    assert {
        condition     =  google_artifact_registry_repository.myreg.location == var.region
        error_message = "google_artifact_registry_repository region did not match expected" 
    }

    assert {
        condition     =  google_artifact_registry_repository.myreg.repository_id == "myreg"
        error_message = "google_artifact_registry_repository repository_id did not match expected" 
    }

    assert {
        condition     =  google_artifact_registry_repository.myreg.description == "my docker repository"
        error_message = "google_artifact_registry_repository description did not match expected" 
    }

    assert {
        condition     =  google_artifact_registry_repository.myreg.format == "DOCKER"
        error_message = "google_artifact_registry_repository format did not match expected" 
    }

    # Storage Bucket
    assert {
        condition     =  google_storage_bucket.cloudbuild_log_bucket.location == "ASIA-NORTHEAST1"
        error_message = "google_storage_bucket location did not match expected" 
    }

    assert {
        condition     =  google_storage_bucket.cloudbuild_log_bucket.force_destroy == true
        error_message = "google_storage_bucket force_destroy did not match expected" 
    }

    assert {
        condition     =  google_storage_bucket.cloudbuild_log_bucket.public_access_prevention == "enforced"
        error_message = "google_storage_bucket public_access_prevention did not match expected" 
    }

    # Cloud Build Trigger
    assert {
        condition     =  google_cloudbuild_trigger.filename-trigger.location == var.region
        error_message = "google_cloudbuild_trigger filename-trigger location did not match expected" 
    }

    // assert {
    //     condition     =  google_cloudbuild_trigger.filename-trigger.service_account == "mybuildsa"
    //     error_message = "google_cloudbuild_trigger filename-trigger service_account did not match expected" 
    // }

    assert {
        condition     =  google_cloudbuild_trigger.filename-trigger.trigger_template[0].branch_name == "master"
        error_message = "google_cloudbuild_trigger filename-trigger trigger_template branch_name did not match expected" 
    }

    assert {
        condition     =  google_cloudbuild_trigger.filename-trigger.trigger_template[0].repo_name == "myrepo"
        error_message = "google_cloudbuild_trigger filename-trigger trigger_template repo_name did not match expected" 
    }

    assert {
        condition     =  google_cloudbuild_trigger.filename-trigger.filename == "cloudbuild.yaml"
        error_message = "google_cloudbuild_trigger filename-trigger filename did not match expected" 
    }

    # Cloud Build Worker Pool
    assert {
        condition     =  google_cloudbuild_worker_pool.mybuildpool.name == "mybuildpool"
        error_message = "Cloud Build Worker Pool Name did not match expected" 
    }

    assert {
        condition     =  google_cloudbuild_worker_pool.mybuildpool.location == var.region
        error_message = "Cloud Build Worker Pool location did not match expected" 
    }

    assert {
        condition     =  google_cloudbuild_worker_pool.mybuildpool.worker_config[0].disk_size_gb == 100
        error_message = "Cloud Build Worker Pool worker_config disk_size_gb did not match expected" 
    }

    assert {
        condition     =  google_cloudbuild_worker_pool.mybuildpool.worker_config[0].machine_type == "e2-medium"
        error_message = "Cloud Build Worker Pool worker_config machine_type did not match expected" 
    }

    assert {
        condition     =  google_cloudbuild_worker_pool.mybuildpool.worker_config[0].no_external_ip == false
        error_message = "Cloud Build Worker Pool worker_config no_external_ip did not match expected" 
    }

}
```

#### 3-2. テストの実行
テストを実行します。terraform test -verpose コマンドを実行します。<br>
特に新しい事項はないので、全てのテストがPassすることを確認しておいてください。

### 4. 次回予告
次回は、terraformの内部仕様について、いくつか見ていきます。

