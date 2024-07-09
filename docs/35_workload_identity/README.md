# workload identity

### 1. 前提条件
34_gke_privateが完了していること。

### 2. 今回の構成図
前回作成したプライベートクラスタにWorkload Identityを実装していきます。<br>
![35](asset/35.png "35")<br>

### 3. Workload Identityの実装前の状態を確認する
今回はまず前回のコードを実行したところから、現状の動作確認から始めます。<br>
なので、まず前回のコード実行と動作確認の手順の再実施をお願いします。<br>
完了後は、手動でも良いので、Cloud Storageのバケットを作成し、空ファイルで良いので数件そのバケットにデータのアップロードをお願いします。<br>
<br>
次に踏み台VMで下記のファイルを作成します。<br>
ファイル名は、test.yamlとしてください。<br>
```
apiVersion: v1
kind: Pod
metadata:
  name: test-pod
spec:
  containers:
  - name: test-pod
    image: google/cloud-sdk:slim
    command: ["sleep","infinity"]
    resources:
      requests:
        cpu: 500m
        memory: 512Mi
        ephemeral-storage: 10Mi
```
このPodの定義はgcloudコマンドを実行できるコンテナを生成するものになります。<br>
ファイルを作成したらこのPodを作成します。<br>
```
$ kubectl apply -f test.yaml
```

1分ほどでPodが立ち上がると思いますので、確認します。<br>
```
$ kubectl get pod
```
下記のようにRunningのSTATUSになっていればOKです。
```
NAME       READY   STATUS    RESTARTS   AGE
test-pod   1/1     Running   0          85m
```
Pod内に侵入します。<br>
```
kubectl exec -it test-pod -- /bin/bash
```
プロンプトが#（シャープ）に変わっていればOKです。<br>
その状態で下記のコマンドを実行し、冒頭で作成したCloud Storageに接続を試みます。<br>
[YOUR BUCKET NAME]の箇所を冒頭で作成したバケット名に修正して実行ください。<br>
```
curl -X GET -H "Authorization: Bearer $(gcloud auth print-access-token)" \
    "https://storage.googleapis.com/storage/v1/b/[YOUR BUCKET NAME]/o"
```
403エラーが応答されればOKです。<br>
Workload Identityの設定が無い状態では認証エラーになることが確認できます。<br>
確認後は、exitで抜けておいてください。<br>

### 4. Workload Identityを実装する
参考）https://cloud.google.com/kubernetes-engine/docs/how-to/workload-identity?hl=ja<br>
まずkubernetesの名前空間を作成します。<br>
下記のコマンドは踏み台VMから実行します。<br>
```
kubectl create namespace myns
```
次にkubernetes service account（以下、KSA）を作成します。<br>
```
kubectl create serviceaccount myksa --namespace myns
```
Workload IdentityにIAMロールを割り当てます。今回はroles/storage.objectViewerを割り当てます。<br>
```
gcloud storage buckets add-iam-policy-binding gs://[YOUR BUCKET NAME] ¥
  --role=roles/storage.objectViewer ¥
  --member=principal://iam.googleapis.com/projects/[YOUR PROJECT NUMBER]/locations/global/workloadIdentityPools/[YOUR PROJECT ID].svc.id.goog/subject/ns/myns/sa/myksa ¥
  --condition=None
```
この状態で先ほど作成したtest.yamlを下記のように変更します。<br>
```
apiVersion: v1
kind: Pod
metadata:
  name: test-pod
  namespace: myns
spec:
  serviceAccountName: myksa
  containers:
  - name: test-pod
    image: google/cloud-sdk:slim
    command: ["sleep","infinity"]
    resources:
      requests:
        cpu: 500m
        memory: 512Mi
        ephemeral-storage: 10Mi
```
このYAMLを適用してPodが立ち上がることを確認します。<br>
また、先ほどと同じコマンドをPod内で実行してCloud Storageからオブジェクトが応答されることを確認してください。<br>
（練習のためコマンドは割愛します。名前空間の違いなどに気をつけながら確認してみくてだくさい。）<br>
このようにPodから接続するサービスに対するロールだけを設定して権限を制御することができます。<br>
今回は簡単な例ですが、実務上はAWSなどと同じように条件指定で、特定のリソースだけ、特定のnamespaceだけというように制御してくことになると思います。<br>
ただ、IdentityプールにプロジェクトIDが入っているので、条件が複雑になる場合は、プロジェクトを分けてクラスタを作る、などの対応が必要になるかもしれません。<br>

### 5. 次回予告
次回は実践編１でGKE上に乗っけるアプリの試作を行います。
