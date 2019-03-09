# Lab 0: Knative Setup

This guide walks you through the installation of the latest version of all
Knative components using pre-built images.

## Before you begin

Knative requires a Kubernetes cluster v1.11 or newer. `kubectl` v1.10 is also
required. This guide walks you through creating a cluster with the correct
specifications for Knative on Google Cloud Platform (GCP).

This guide assumes you are using `bash` in a Mac or Linux environment; some
commands will need to be adjusted for use in a Windows environment.

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
export CLUSTER_ZONE=eu-north1-a
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

- Kubernetes version 1.11 or later
- 4 vCPU nodes (`n1-standard-4`)
- Node autoscaling, up to 4 nodes
- API scopes for `cloud-platform`, `logging-write`, `monitoring-write`, and
  `pubsub` (if those features will be used)

1. Create a Kubernetes cluster on GKE with the required specifications:

   ```bash
   gcloud container clusters create $CLUSTER_NAME \
     --zone=$CLUSTER_ZONE \
     --cluster-version=latest \
     --machine-type=n1-standard-4 \
     --enable-autoscaling --min-nodes=1 --max-nodes=4 \
     --enable-autorepair \
     --scopes=service-control,service-management,compute-rw,storage-ro,cloud-platform,logging-write,monitoring-write,pubsub,datastore \
     --num-nodes=2
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

## Installing Istio

Knative depends on Istio.

1. Install Istio:

   ```bash
   kubectl create namespace istio-system
   kubectl apply --filename https://github.com/knative/serving/releases/download/v0.4.0/istio-crds.yaml && \
   kubectl apply --filename https://github.com/knative/serving/releases/download/v0.4.0/istio.yaml
   ```

   Note: the resources (CRDs) defined in the `istio-crds.yaml`file are also
   included in the `istio.yaml` file, but they are pulled out so that the CRD
   definitions are created first. If you see an error when creating resources
   about an unknown type, run the second `kubectl apply` command again.

1. Label the default namespace with `istio-injection=enabled`:

   ```bash
   kubectl label namespace default istio-injection=enabled --overwrite
   ```

1. Monitor the Istio components until all of the components show a `STATUS` of
   `Running` or `Completed`:

   ```bash
   kubectl get pods --namespace istio-system
   ```

It will take a few minutes for all the components to be up and running; you can
rerun the command to see the current status.

> Note: Instead of rerunning the command, you can add `--watch` to the above
> command to view the component's status updates in real time. Use CTRL + C to
> exit watch mode.

## Installing Knative

The following commands install all available Knative components as well as the
standard set of observability plugins. To customize your Knative installation,
see [Performing a Custom Knative Installation](Knative-custom-install.md).

1. Create the required namespaces for Knative and its dependencies:

   ```bash
   kubectl create namespace knative-serving
   kubectl create namespace knative-build
   kubectl create namespace knative-eventing
   kubectl create namespace knative-sources
   kubectl create namespace knative-monitoring
   ```

1. Run the `kubectl apply` command to install Knative and its dependencies:

   ```bash
   kubectl apply --wait \
     --filename https://github.com/knative/serving/releases/download/v0.4.0/serving.yaml \
     --filename https://github.com/knative/serving/releases/download/v0.4.0/monitoring-metrics-prometheus.yaml \
     --filename https://github.com/knative/build/releases/download/v0.4.0/build.yaml \
     --filename https://github.com/knative/eventing/releases/download/v0.4.0/release.yaml \
     --filename https://github.com/knative/eventing/releases/download/v0.4.0/gcp-pubsub.yaml \
     --filename https://github.com/knative/eventing/releases/download/v0.4.0/natss.yaml \
     --filename https://github.com/knative/eventing-sources/releases/download/v0.4.1/release.yaml \
     --filename https://github.com/knative/eventing-sources/releases/download/v0.4.1/gcppubsub.yaml \
     --filename https://github.com/knative/eventing-sources/releases/download/v0.4.1/message-dumper.yaml \
     --filename https://raw.githubusercontent.com/knative/serving/v0.4.0/third_party/config/build/clusterrole.yaml \
     --filename https://raw.githubusercontent.com/knative/build-templates/master/kaniko/kaniko.yaml
   ```

1. Monitor the Knative components until all of the components show a `STATUS` of
   `Running`:

   ```bash
   kubectl get pods --namespace knative-serving
   kubectl get pods --namespace knative-build
   kubectl get pods --namespace knative-eventing
   kubectl get pods --namespace knative-sources
   kubectl get pods --namespace knative-monitoring
   ```

---

<p align="right"><a href="../1-serve">Lab 1: Knative Serve →</a></p>

Except as otherwise noted, the content of this page is licensed under the
[Creative Commons Attribution 4.0 License][cc-by], and code samples are licensed
under the [Apache 2.0 License][apache-2-0].

[cc-by]: https://creativecommons.org/licenses/by/4.0/
[apache-2-0]: https://www.apache.org/licenses/LICENSE-2.0
