# Lab 0: Knative Setup

This guide walks you through the installation of the latest version of all
Knative components using pre-built images.

## Before you begin

Knative requires a Kubernetes cluster v1.11 or newer. `kubectl` v1.10 is also
required. This guide walks you through creating a cluster with the correct
specifications for Knative on Google Cloud Platform (GCP).

This guide assumes you are using `bash` in a Mac or Linux environment; some
commands will need to be adjusted for use in a Windows environment.

> We recommend using the [Google Cloud Shell][gcp-shell] since it has the Google
> Cloud SDK and `kubectl` already installed!

[gcp-shell]: https://cloud.google.com/shell/

### Installing the Google Cloud SDK and `kubectl`

1. If you already have `gcloud` installed with `kubectl` version 1.10 or newer,
   you can skip these steps.

> Tip: To check which version of `kubectl` you have installed, enter:

   ```
   kubectl version
   ```

1. Download and install the `gcloud` command line tool:
   https://cloud.google.com/sdk/install

1. Install the `kubectl` component:

   ```
   gcloud components install kubectl
   ```

   if you are running an old version of `kubectl`:

   ```
   gcloud components update
   ```

1. Authorize `gcloud`:

   ```
   gcloud auth login
   ```

### Setting environment variables

To simplify the command lines for this walkthrough, we need to define a few
environment variables.

Set `CLUSTER_NAME` and `CLUSTER_ZONE` variables, you can replace `knative` and
`us-west1-c` with cluster name and zone of your choosing.

The `CLUSTER_NAME` needs to be lowercase and unique among any other Kubernetes
clusters in your GCP project. The zone can be [any compute zone available on
GCP][gce-zones]. These variables are used later to create a Kubernetes cluster.

[gce-zones]: https://cloud.google.com/compute/docs/regions-zones/#available

```bash
export CLUSTER_NAME=knative-workshop
export CLUSTER_ZONE=europe-north1-a
```

### Setting up a Google Cloud Platform project

You need a Google Cloud Platform (GCP) project to create a Google Kubernetes
Engine cluster.

1. Set `PROJECT` environment variable, you can replace `my-knative-project` with
   the desired name of your GCP project. If you don't have one, we'll create one
   in the next step.

   ```bash
   export PROJECT=my-knative-project
   ```

1. If you don't have a GCP project, create and set it as your `gcloud` default:

   ```bash
   gcloud projects create $PROJECT --set-as-default
   ```

   You also need to [enable billing][gce-billing] for your new project.

[gce-billing]: https://cloud.google.com/billing/docs/how-to/manage-billing-account

1. If you already have a GCP project, make sure your project is set as your
   `gcloud` default:

   ```bash
   gcloud config set core/project $PROJECT
   ```

   > Tip: Enter `gcloud config get-value project` to view the ID of your default
   > GCP project.

1. Enable the necessary APIs:

   ```bash
   gcloud services enable \
     cloudapis.googleapis.com \
     container.googleapis.com \
     containerregistry.googleapis.com \
     pubsub.googleapis.com
   ```

## Creating a Kubernetes cluster

To make sure the cluster is large enough to host all the Knative and Istio
components, the recommended configuration for a cluster is:

- Kubernetes version 1.14 or later
- 4 vCPU nodes (`n1-standard-4`)
- Node autoscaling, up to 10 nodes
- Istio addon for GKE enabled

1. Create a Kubernetes cluster on GKE with the required specifications:

   ```bash
   gcloud beta container clusters create $CLUSTER_NAME \
     --addons=HorizontalPodAutoscaling,HttpLoadBalancing,Istio \
     --machine-type=n1-standard-4 \
     --cluster-version=latest --zone=$CLUSTER_ZONE \
     --enable-stackdriver-kubernetes --enable-ip-alias \
     --enable-autoscaling --min-nodes=1 --max-nodes=10 \
     --enable-autorepair \
     --scopes cloud-platform
   ```

1. Grant cluster-admin permissions to the current user:

   ```bash
   kubectl create clusterrolebinding cluster-admin-binding \
   --clusterrole=cluster-admin \
   --user=$(gcloud config get-value core/account)
   ```

Admin permissions are required to create the necessary [RBAC rules for
Istio][istio-rbac].

[istio-rbac]: https://istio.io/docs/concepts/security/rbac/

## Installing Knative

The following commands install all available Knative components as well as the
standard set of observability plugins. To customize your Knative installation,
see [Installing Knative Docs][knative-install].

[knative-install]: https://knative.dev/docs/install/

1. Run the `kubectl apply` command to install Knative and its dependencies:

   ```bash
   kubectl apply --wait --selector knative.dev/crd-install=true \
   --filename https://github.com/knative/serving/releases/download/v0.9.0/serving.yaml \
   --filename https://github.com/knative/eventing/releases/download/v0.9.0/release.yaml \
   --filename https://github.com/knative/serving/releases/download/v0.9.0/monitoring.yaml

   kubectl apply --wait \
   --filename https://github.com/knative/serving/releases/download/v0.9.0/serving.yaml \
   --filename https://github.com/knative/eventing/releases/download/v0.9.0/release.yaml \
   --filename https://github.com/knative/serving/releases/download/v0.9.0/monitoring.yaml
   ```

   > Note: the two commands are not complely identical, the first one installs
   > the Custom Resource Definitions required for Knative using the `--selector`
   > flag, the second one installs the Knative components itself.

1. Monitor the Knative components until all of the components show a `STATUS` of
   `Running`:

   > Note: the pod `gcppubsub-controller-manager-0` depends on a secret that we
   > will create in a later lab, until then it the pod status will be
   > `ContainerCreating`

   ```bash
   kubectl get pods --namespace knative-serving
   kubectl get pods --namespace knative-eventing
   kubectl get pods --namespace knative-monitoring
   ```

1. Setting up domain name for Knative routes:

  ```bash
  export INGRESSGATEWAY_IP=$(kubectl get svc -n istio-system | grep istio-ingressgateway | awk '{ print $4 }')
  sed "s/INGRESSGATEWAY_IP/"$INGRESSGATEWAY_IP"/g" knative-domain.yaml | kubectl apply -f -
  ```

  > This makes it easier to access the exposed services in your browser.
  
  If you are running in Google Cloud Shell you will need to clone the repository before you proceede:
  
  ```bash
  git clone https://github.com/evry-bergen/knative-workshop.git
  ```

---

<p align="right"><a href="../1-serve">Lab 1: Knative Serve →</a></p>

Except as otherwise noted, the content of this page is licensed under the
[Creative Commons Attribution 4.0 License][cc-by], and code samples are licensed
under the [Apache 2.0 License][apache-2-0].

[cc-by]: https://creativecommons.org/licenses/by/4.0/
[apache-2-0]: https://www.apache.org/licenses/LICENSE-2.0
