# CICD APP

### 1. 前提条件
07_cicdが完了していること。

### 2. 今回の構成図
前回から変更なし。

### 3. 今回のコード
今回はTerraformは使わずに、07_cicdのリソースが立ち上がっている前提で、アプリケーションデプロイを実施します。

#### 3-1. ファイル作成
07_cicdで作成したmyrepoリポジトリをクローンして、下記のようにファイルを3つ作成する。
```
  myrepo/
   deployment.yaml
   cloudbuild.yaml
   Dockerfile
```
cloudbuild.yamlは、CloudBuildで実行するCICDの処理を記載します。<br>
logsBucketには、07_cicdで作成したcloudbuild_log_bucketを指定します。<br>
```
[cloudbuild.yaml]
steps:

  # Docker Build
  - name: 'gcr.io/cloud-builders/docker'
    args: ['build', '-t',
           'asia-northeast1-docker.pkg.dev/[projectid]/myreg/demoapp:$SHORT_SHA',
           '.']

  # Docker Push
  - name: 'gcr.io/cloud-builders/docker'
    args: ['push',
           'asia-northeast1-docker.pkg.dev/[projectid]/myreg/demoapp:$SHORT_SHA']

  # set :version to :$SHORT_SHA in deployment.yaml
  - name: 'bash'
    script: |
      #!/usr/bin/env bash
      sed -i s/:version/:$SHORT_SHA/g deployment.yaml

  # check deployment.yaml
  - name: 'bash'
    script: |
      #!/usr/bin/env bash
      cat deployment.yaml

  # deploy container image to GKE
  - name: "gcr.io/cloud-builders/gke-deploy"
    args:
    - run
    - --filename=deployment.yaml
    - --location=asia-northeast1
    - --cluster=mygkecluster

logsBucket: 'gs://cloudbuildlogcr1x96ttqptpnfuh'

options:
  logging: GCS_ONLY
  automapSubstitutions: true
  pool:
    name: 'projects/[projectid]/locations/asia-northeast1/workerPools/mybuildpool'
```
Dockerfileには、サンプルとしてnginxのイメージだけ記載してあります。
```
[Dockerfile]
FROM nginx:latest
```
deployment.yamlは、k8s名前空間、k8sサービスアカウント、サービス、デプロイメントを記載しています。
```
apiVersion: v1
kind: Namespace
metadata:
  name: app
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: mypodsa
  namespace: app
---
apiVersion: v1
kind: Service
metadata:
  name: myservice
  namespace: app
spec:
  type: NodePort
  selector:
    app: demoapp
  ports:
  - protocol: TCP
    port: 80
    targetPort: 80
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: demoapp
  namespace: app
  labels:
    app: demoapp
spec:
  replicas: 1
  selector:
    matchLabels:
      app: demoapp
  template:
    metadata:
      labels:
        app: demoapp
    spec:
      serviceAccountName: mypodsa
      containers:
      - name: demoapp
        image: asia-northeast1-docker.pkg.dev/[projectid]/myreg/demoapp:version
        ports:
        - containerPort: 80
```
ファイルが作成できたらgitにpushします。

#### 3-2. push後の確認
CloudBuildが発火し正常に動作することを確認します。<br>
CloudBuild > 履歴から辿ることができます。<br>
![cloudbuildlog](asset/cloudbuildlog.png "cloudbuildlog")

GKEにアプリケーションがデプロイされていることを確認します。<br>
まずは、GKEの画面から確認します。<br>
![gkekakunin](asset/gkekakunin.png "gkekakunin")

次に、踏み台VM内からサービス経由でnginxアプリケーションへの疎通を確認します。<br>
手順は06_gkeで実施した内容と同じですが、１通りもう一度書いておきます。<br>
まず、クラスタとの認証を行います。。ここではコマンドだけ書いておきます。<br>
```
$ grep -rhE ^deb /etc/apt/sources.list* | grep "cloud-sdk"
$ sudo apt-get update
$ sudo apt-get install -y kubectl
$ sudo apt-get install google-cloud-sdk-gke-gcloud-auth-plugin
$ gke-gcloud-auth-plugin --version
$ gcloud container clusters get-credentials mygkecluster --region=asia-northeast1
```
次にエンドポイントを探ります。Ingressなどを立ち上げていれば一目瞭然ですが、今回は簡易版でNodePortで立ち上げているので、探す必要があります。<br>
endpointはIPアドレスとポート番号で構成されますが、IPアドレスはNodePortの仕様により、ワーカNodeのIPアドレスのいずれか、になります。<br>
kubectl get nodesコマンドのwideオプションで参照することができます。VMの画面から拾ってもらっても良いです。<br>
```
$ kubectl get nodes -o wide
NAME                                           STATUS   ROLES    AGE   VERSION                INTERNAL-IP   EXTERNAL-IP      OS-IMAGE                             KERNEL-VERSION   CONTAINER-RUNTIME
gke-mygkecluster-mygkenodepool-54205a1e-prd7   Ready    <none>   45m   v1.27.11-gke.1062003   10.1.0.9      35.243.72.108    Container-Optimized OS from Google   5.15.146+        containerd://1.7.10
gke-mygkecluster-mygkenodepool-57e7421e-0nh9   Ready    <none>   45m   v1.27.11-gke.1062003   10.1.0.7      104.198.122.97   Container-Optimized OS from Google   5.15.146+        containerd://1.7.10
gke-mygkecluster-mygkenodepool-5d0ac5be-dd2x   Ready    <none>   45m   v1.27.11-gke.1062003   10.1.0.8      34.84.205.130    Container-Optimized OS from Google   5.15.146+        containerd://1.7.10
```
今回は、NATGW経由でインターネット経由するようなことはせずに、プライベート接続しますので、INTERNAL-IPの列を参照します。<br>
3つのうちいずれか、なので、10.1.0.9 としておきます。<br>
次にポート番号を探ります。これは、NodePort作成時に自動的に割り振られます。（Serviceを定義しているYAML内で値を指定することも可能です。）<br>
GKEの画面か下記のコマンドで値を確認することができます。<br>
```
$ kubectl get svc -n app
NAME        TYPE       CLUSTER-IP     EXTERNAL-IP   PORT(S)        AGE
myservice   NodePort   10.80.127.57   <none>        80:31643/TCP   34m
```
ポート番号は、31643のようです。<br>
curl文で疎通を確認します。nginxのトップ画面のHTMLが応答されればOKです。<br>
```
$ curl http://10.1.0.9:31643/
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
html { color-scheme: light dark; }
body { width: 35em; margin: 0 auto;
font-family: Tahoma, Verdana, Arial, sans-serif; }
</style>
</head>
<body>
<h1>Welcome to nginx!</h1>
<p>If you see this page, the nginx web server is successfully installed and
working. Further configuration is required.</p>

<p>For online documentation and support please refer to
<a href="http://nginx.org/">nginx.org</a>.<br/>
Commercial support is available at
<a href="http://nginx.com/">nginx.com</a>.</p>

<p><em>Thank you for using nginx.</em></p>
</body>
</html>
```

お疲れ様でした。

### 5. 次回予告
ここまでで超基本的なコンテナ基盤とCICDパイプラインが完成しましたが、立ち上げることに注力しておりテストが行われていません。<br>
次回は、ここまでのソースコードを元にTerraform testを実装していきます。


