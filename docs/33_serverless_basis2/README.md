# serverless basis 2

### 1. 前提条件
32_serverless_basis1が完了していること。

### 2. 今回の構成図
Cloud Functionsを起動します。（構成図はありません）

### 3. 今回のコード
ファンクションのコードを準備します。<br>
```
$ git clone https://github.com/GoogleCloudPlatform/nodejs-docs-samples.git
$ cd nodejs-docs-samples/functions/helloworld/helloworldHttp
$ zip -r function-source.zip .
```
このZipをアップロードするので、以降のTerraformコードで指定している場所へ移動させます。<br>
例では、modules/function/function-source.zipとしています。<br>
大元のmain.tfからの相対パスで指定できるので、dataフォルダなど作成して配置してもらえればと思います。<br>
簡単なコードですが、形だけモジュール化しておきます。<br>
```
resource "random_id" "default" {
  byte_length = 8
}

resource "google_storage_bucket" "default" {
  name                        = "${random_id.default.hex}-gcf-source" # Every bucket name must be globally unique
  location                    = "asia-northeast1"
  uniform_bucket_level_access = true
}

# data "archive_file" "default" {
#   type        = "zip"
#   output_path = "/tmp/function-source.zip"
#   source_dir  = "functions/hello-world/"
# }

resource "google_storage_bucket_object" "object" {
  name   = "function-source.zip"
  bucket = google_storage_bucket.default.name
  source = "modules/function/function-source.zip"
}

resource "google_cloudfunctions2_function" "default" {
  name        = "function-v2"
  location    = "asia-northeast1"
  description = "a new function"

  build_config {
    runtime     = "nodejs16"
    entry_point = "helloHttp" # Set the entry point
    source {
      storage_source {
        bucket = google_storage_bucket.default.name
        object = google_storage_bucket_object.object.name
      }
    }
  }

  service_config {
    max_instance_count = 1
    available_memory   = "256M"
    timeout_seconds    = 60
  }
}

resource "google_cloud_run_service_iam_member" "member" {
  location = google_cloudfunctions2_function.default.location
  service  = google_cloudfunctions2_function.default.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

```
主要な変更点は上記の通りになりますので、行間は埋めて実行してみてください。エラーなく実行できることを確認してください。

### 4. 実行後の確認
実行後は下記の確認を行なってください。<br>
・Cloud Functionsにサービスが1つ作成されていること。<br>

### 5. 動作確認
Cloud Functionsのサービスを選択すると、URLが表示されているのでアクセスしてみてください。<br>
Hello Worldが表示されればOKです。<br>

### 6. 次回予告
ここまでで実践編#1で検討している基本的なWebシステムの登場人物が一通り登場しました。<br>
実践編#1に向けて、残りはGKEクラスタのプライベート化、デモ用のアプリケーションの作成を進めていきたいと思います。<br>
