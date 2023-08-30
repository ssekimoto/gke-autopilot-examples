<walkthrough-metadata>
  <meta name="title" content="GKE Dojo" />
  <meta name="description" content="Hands-on GKE" />
  <meta name="component_id" content="103" />
</walkthrough-metadata>

<walkthrough-disable-features toc></walkthrough-disable-features>

# GKE 道場 入門編

## Google Cloud プロジェクトの設定、確認

### **1. 対象の Google Cloud プロジェクトを設定**

ハンズオンを行う Google Cloud プロジェクトのプロジェクト ID を環境変数に設定し、以降の手順で利用できるようにします。 (右辺の [PROJECT_ID] を手動で置き換えてコマンドを実行します)

```bash
export PROJECT_ID=[PROJECT_ID]
```

`プロジェクト ID` は [ダッシュボード](https://console.cloud.google.com/home/dashboard) に進み、左上の **プロジェクト情報** から確認します。

### **2. プロジェクトの課金が有効化されていることを確認する**

```bash
gcloud beta billing projects describe ${PROJECT_ID} | grep billingEnabled
```

**Cloud Shell の承認** という確認メッセージが出た場合は **承認** をクリックします。

出力結果の `billingEnabled` が **true** になっていることを確認してください。**false** の場合は、こちらのプロジェクトではハンズオンが進められません。別途、課金を有効化したプロジェクトを用意し、本ページの #1 の手順からやり直してください。

## **環境準備**

<walkthrough-tutorial-duration duration=10></walkthrough-tutorial-duration>

最初に、ハンズオンを進めるための環境準備を行います。

下記の設定を進めていきます。

- gcloud コマンドラインツール設定
- Google Cloud 機能（API）有効化設定

## **gcloud コマンドラインツール**

Google Cloud は、コマンドライン（CLI）、GUI から操作が可能です。ハンズオンでは主に CLI を使い作業を行いますが、GUI で確認する URL も合わせて掲載します。

### **1. gcloud コマンドラインツールとは?**

gcloud コマンドライン インターフェースは、Google Cloud でメインとなる CLI ツールです。このツールを使用すると、コマンドラインから、またはスクリプトや他の自動化により、多くの一般的なプラットフォーム タスクを実行できます。

たとえば、gcloud CLI を使用して、以下のようなものを作成、管理できます。

- Google Compute Engine 仮想マシン
- Google Kubernetes Engine クラスタ
- Google Cloud SQL インスタンス

**ヒント**: gcloud コマンドラインツールについての詳細は[こちら](https://cloud.google.com/sdk/gcloud?hl=ja)をご参照ください。

### **2. gcloud から利用する Google Cloud のデフォルトプロジェクトを設定**

gcloud コマンドでは操作の対象とするプロジェクトの設定が必要です。操作対象のプロジェクトを設定します。

```bash
gcloud config set project ${PROJECT_ID}
```

承認するかどうかを聞かれるメッセージがでた場合は、`承認` ボタンをクリックします。

### **3. ハンズオンで利用する GCP の API を有効化する**

Google Cloud では利用したい機能ごとに、有効化を行う必要があります。
ここでは、以降のハンズオンで利用する機能を事前に有効化しておきます。


```bash
gcloud services enable cloudbuild.googleapis.com container.googleapis.com artifactregistry.googleapis.com
```

**GUI**: [API ライブラリ](https://console.cloud.google.com/apis/library?project={{project-id}})

## **4. gcloud コマンドラインツール設定 - リージョン、ゾーン

コンピュートリソースを作成するデフォルトのリージョン、ゾーンとして、東京 (asia-northeast1/asia-northeast1-c）を指定します。

```bash
gcloud config set compute/region asia-northeast1 && gcloud config set compute/zone asia-northeast1-c
```

## **参考: Cloud Shell の接続が途切れてしまったときは?**

一定時間非アクティブ状態になる、またはブラウザが固まってしまったなどで `Cloud Shell` が切れてしまう、またはブラウザのリロードが必要になる場合があります。その場合は以下の対応を行い、チュートリアルを再開してください。

### **1. チュートリアル資材があるディレクトリに移動する**

```bash
cd ~/gke-autopilot-examples
```

### **2. チュートリアルを開く**

```bash
teachme tutorial.md
```

### **3. プロジェクト ID を設定する**

```bash
export PROJECT_ID=[PROJECT_ID]
```

### **4. gcloud のデフォルト設定**

```bash
gcloud config set project ${PROJECT_ID} && gcloud config set compute/region asia-northeast1 && gcloud config set compute/zone asia-northeast1-c
```


## GKE Autopilot クラスタの作成

GKE 以下のコマンドを実行し、GKE Autopilot クラスタを作成します。
```bash
. ./bootstrap/init.sh
```

クラスタの作成には10分〜20分程度の時間がかかります。

## サンプル
Now that your cluster is up and running, the first step is deploying the sample app, the [Online Boutique microservices demo](https://github.com/GoogleCloudPlatform/microservices-demo). This is a microservices demo with several services, spanning various language platforms. Check out the  manifests in `demo-01-deploy-sample-app`.

### Deploy the app services:
```bash
kubectl apply -f demo-01-deploy-sample-app/
```
Note that we have not yet provisioned node pools or nodes, as Autopilot will do that for you.

Monitor the rollout progress of both pods and nodes:
```bash
watch -d kubectl get pods,nodes
```

(Use Ctrl-C to exit the watch command)

### Inspect the nodes

Inspect the nodes Autopilot provisioned under the hood. Get the machine type provisioned by default:
```bash
kubectl get nodes -o json|jq -Cjr '.items[] | .metadata.name," ",.metadata.labels."beta.kubernetes.io/instance-type"," ",.metadata.labels."beta.kubernetes.io/arch", "\n"'|sort -k3 -r
```

Note that Autopilot defaults to the e2 series machine for each node by default with Autopilot.

### Test the demo app website via ingress
After a few minutes the ingress IP will get assigned. Confirm everything is up in a different browser tab.

Get the ingress URL:
```bash
echo http://$(kubectl get svc frontend-external -o=jsonpath={.status.loadBalancer.ingress[0].ip})
```

## Demo 02 - Compute classes

Now let's tune our application by specifying [compute classes](https://cloud.google.com/kubernetes-engine/docs/concepts/autopilot-compute-classes) for our workloads. [Compute classes](https://cloud.google.com/kubernetes-engine/docs/concepts/autopilot-compute-classes#when-to-use) allow us to customize hardware requirements and over a curated subset of Compute Engine machine series.

*Note: This is a fictional example with arbitrary compute classes so do not read into specific class choices. The point is show you *how* to select compute classes.*

### Configuration
In this demo, the `adservice` workload uses the Balanced compute class (currently N2/N2D machine types):

Open the file: <walkthrough-editor-select-regex filePath="demo-02-compute-classes/adservice.yaml" regex="compute-class">demo-02-compute-classes/adservice.yaml</walkthrough-editor-select-regex> and locate the compute class line.

And the `checkoutservice` workload use the Scale-Out compute class (currently T2/T2D machine types):

Open the file: <walkthrough-editor-select-regex filePath="demo-02-compute-classes/checkoutservice.yaml" regex="compute-class">demo-02-compute-classes/checkoutservice.yaml</walkthrough-editor-select-regex> and locate the compute class line.


### Deploy machine type manifests
```bash
kubectl apply -f demo-02-compute-classes/
```

Watch new nodes spin up (may take a few minutes):
```bash
watch -n 1 kubectl get pod -o=custom-columns=NAME:.metadata.name,STATUS:.status.phase,NODE:.spec.nodeName
```

List node machine types and architectures:
```bash
kubectl get nodes -o json|jq -Cjr '.items[] | .metadata.name," ",.metadata.labels."beta.kubernetes.io/instance-type"," ",.metadata.labels."beta.kubernetes.io/arch", "\n"'|sort -k2 -r
```

### Spot pods
The `cartservice` workload has now been configured to use Spot Pod resources:

Open the file: <walkthrough-editor-select-regex filePath="demo-02-compute-classes/cartservice.yaml" regex="spot">demo-02-compute-classes/cartservice.yaml</walkthrough-editor-select-regex>

List nodes looking for spot
```bash
kubectl get nodes -o json|jq -Cjr '.items[] | .metadata.name," ",.metadata.labels."cloud.google.com/gke-spot"," ",.metadata.labels."beta.kubernetes.io/arch", "\n"'|sort -k2 -r
``` 

## Demo 03 - GPU for AI/ML (TensorFlow)

Our store has some AI/ML models as well. GKE Autopilot supports the provisioning of hardware accelerators like A100 and T4 GPUs to make machine learning tasks much faster. 

Open the config file: <walkthrough-editor-select-regex filePath="demo-03-GPU/tensorflow.yaml" regex="gpu|accelerator">demo-03-GPU/tensorflow.yaml</walkthrough-editor-select-regex> and note the GPU configurations.

### Deploy the GPU workload

This demo creates a Tensorflow environment with a Jupyter notebook. 
```bash
kubectl apply -f demo-03-GPU/
```

Watch the Tensorflow pod and GPU node spin up:
```bash
watch -n 1 kubectl get pods,nodes
```

Confirm we're using GPU (and spot, if selected)
```bash
kubectl get nodes -o json|jq -Cjr '.items[] | .metadata.name," ",.metadata.labels."cloud.google.com/gke-spot"," ",.metadata.labels."cloud.google.com/gke-accelerator",  "\n"'|sort -k3 -r
```

### Jupyter AI/ML tutorial

After a few minutes, ingress should be aligned for your Jupyter notebook. Get the ingress IP:
```bash
kubectl get svc tensorflow-jupyter -o=jsonpath={.status.loadBalancer.ingress[0].ip}
```

Refer to William Denniss's [blog post](https://wdenniss.com/tensorflow-on-gke-autopilot-with-gpu-acceleration) detailing the TensorFlow demo.

### Tear down GPU workload

The GPU workload we just created will not be used in the rest of the demos and so you can tear it down now to save costs:
```bash
kubectl delete -f demo-03-GPU/
```

## Demo 04 - Provisioning spare capacity
One common Kubernetes pattern is overprovision node resources for spare capacity. Scaling up manually or via HPA will provision new pods, but if there is no spare capacity this may result in a delay as new hardware gets provisioned. In GKE Standard, you can simply spin extra nodes to act as spare capacity. 

Remember that with Autopilot though, Google manages the nodes. So how do you spin up spare capacity for scaling up quickly with Autopilot mode? The answer is [balloon pods](https://wdenniss.com/gke-autopilot-spare-capacity) (see William Denniss's blog post on this topic details this strategy). 

### Create spare capacity via balloon pods 

Open the priority class file: <walkthrough-editor-select-regex filePath="demo-04-spare-capacity-balloon/balloon-priority.yaml" regex="priority">demo-04-spare-capacity-balloon/balloon-priority.yaml</walkthrough-editor-select-regex>.

Create balloon priority class
```bash 
kubectl apply -f demo-04-spare-capacity-balloon/balloon-priority.yaml 
```

Open the balloon deployment file: <walkthrough-editor-select-regex filePath="demo-04-spare-capacity-balloon/balloon-deploy.yaml " regex="priority">demo-04-spare-capacity-balloon/balloon-deploy.yaml </walkthrough-editor-select-regex>.

Create balloon pods
```bash 
kubectl apply -f demo-04-spare-capacity-balloon/balloon-deploy.yaml 
```

Watch scale up of balloon pods
```bash
watch -d kubectl get pods,nodes
```
### Scale up by displaying balloon pods

Now let's simulate a scaling event where the `frontend` service goes from 1 to 8 replicas. Then watch as the balloon pods yield to the `frontend` pods for rapid scale up.

Scale up frontend:
```bash
kubectl scale --replicas=8 deployment frontend
```

Watch scale up of frontend, displacing the balloon pods. Recreation of low priority balloon pods.
```bash
watch -n 1 kubectl get pods,nodes
```

You should see three things happening:
* The original balloon pods will start terminating immediately because they are low priority, making way for...
* Frontend scaling up quickly, with most pods up and running in ~30s
* There are also new balloon pods spinning up on newly provisioned infrastructure

If we were to scale up again, the latest balloon pods would get displaced and we'd continue buffering headroom this way.

## Demo 05 Workload Separation with Autopilot

Another common Kubernetes use case is workload separation: running specific services on separate nodes. [Workload separation](https://cloud.google.com/kubernetes-engine/docs/how-to/workload-separation#separate-workloads-autopilot) is achieved on GKE Autopilot using node labels and tolerations.

In this demo, we want to ensure that both `frontend` and `paymentservice.yaml` workloads run on their own nodes, with no other workloads co-mingled. We'll achieve this by setting node labels using nodeSelector and a corresponding toleration. 

### Inspect the configuration and scale services
Open the file: <walkthrough-editor-select-regex filePath="demo-05-workload-separation/frontend.yaml" regex="toleration">demo-05-workload-separation/frontend.yaml</walkthrough-editor-select-regex> and look for the toleration and nodeSelector. In this case, the node label is "frontend-servers".

Scale frontend service to 8 replicas
```bash
kubectl scale --replicas=8 deployment frontend
```

Open the file: <walkthrough-editor-select-regex filePath="demo-05-workload-separation/paymentservice.yaml" regex="toleration">demo-05-workload-separation/paymentservice.yaml</walkthrough-editor-select-regex> and look for the toleration and nodeSelector. In this case, the node label is "PCI" (say we're trying to isolate these workloads for PCI reasons).

Scale up paymentservice to 2 replicas
```bash
kubectl scale --replicas=2 deployment paymentservice
```

### Create workload separation
Notice the current "co-mingled" distribution of workloads on nodes:
```bash
kubectl get pod -o=custom-columns=NAME:.metadata.name,STATUS:.status.phase,NODE:.spec.nodeName
```

Redeploy the workloads with workload separation
```bash
kubectl apply -f demo-05-workload-separation
```

Watch the separation happen, which may take several minutes:
```bash
watch -n 1 kubectl get pod -o=custom-columns=NAME:.metadata.name,STATUS:.status.phase,NODE:.spec.nodeName
```

## Demo 06 Single zone

Sometimes you want to run a service in a specific availability zone. Perhaps we have persistent data there and we want close proximity. 

Open the file: <walkthrough-editor-select-regex filePath="demo-06-single-zone/productcatalogservice.yaml" regex="topology">demo-06-single-zone/productcatalogservice.yaml</walkthrough-editor-select-regex> and look for the nodeSelector section. In this case, us-west1-b is preset as the zone but you can change this if desired.

```bash
kubectl get nodes --label-columns topology.kubernetes.io/zone
```

You'll see a mix of zones a, b, and possibly others.

Find `productcatalogservice` and make note of the zone this pod is in by referencing the previous command's output.
```bash
kubectl get pod -o=custom-columns=NAME:.metadata.name,STATUS:.status.phase,NODE:.spec.nodeName
```

Redeploy with the selected zone.
```bash
kubectl apply -f demo-06-single-zone/
```

Watch the pod move to another node (make note of the node name):
```bash
watch -n 1 kubectl get pod -o=custom-columns=NAME:.metadata.name,STATUS:.status.phase,NODE:.spec.nodeName
```

Confirm the pod landed on a pod in zone b:
```bash
kubectl get nodes --label-columns kubectl get nodes --label-columns topology.kubernetes.io/zone
```

For a more thorough discussion, see William Denniss's [blog post](https://wdenniss.com/autopilot-specific-zones) on this topic.

## Teardown
That's it! You've made it through all the demos. You can now remove the GKE Autopilot cluster used in this demo as follows:

```bash
. ./bootstrap/teardown.sh
```