# Lab 3: Knative Events

As of v0.5, Knative Eventing defines Broker and Trigger to receive and filter
messages. This is explained in more detail on [Knative
Eventing][knative-eventing] page:

[knative-eventing]: https://www.knative.dev/docs/eventing/

![Broker and Trigger](https://www.knative.dev/docs/eventing/images/broker-trigger-overview.svg)

Knative Eventing has a few different types of [event
sources][knative-event-sources] (Kubernetes, GitHub, GCP Pub/Sub etc.) that it
can listen. In this tutorial, we will focus on listening Google Cloud related
event sources such as Google Cloud Pub/Sub.

[knative-event-sources]: https://knative.dev/docs/eventing/sources/

## Install Knative Eventing

You probably installed [Knative Eventing][knative-eventing] when you [installed
Knative][knative-install]. If not, follow the Knative installation instructions
and take a look at the installation section in [Knative
Eventing][knative-venting] page. In the end, you should have pods running in
`knative-eventing`. Double check that this is the case:

[knative-eventing]: https://www.knative.dev/docs/eventing/
[knative-install]: https://www.knative.dev/docs/install/

```bash
kubectl get pods -n knative-eventing
```

## Install Knative with GCP

[Knative with GCP][knative-gcp] builds on Kubernetes to enable easy
configuration and consumption of Google Cloud Platform events and services. From
Knative v0.9 onwards, this is the preferred method to receive Google Cloud
events into Knative.

[Installing Knative with GCP][knative-gcp-install] page has instructions but it
essentially involves pointing to `cloud-run-events.yaml`:

[knative-gcp]: https://github.com/google/knative-gcp
[knative-gcp-install]: https://github.com/google/knative-gcp/blob/master/docs/install

```bash
kubectl apply -f https://github.com/google/knative-gcp/releases/download/v0.9.0/cloud-run-events.yaml
```

You can double check that there's a `cloud-run-events` namespace created:

```bash
kubectl get ns

NAME                 STATUS
cloud-run-events     Active
```

And that it has set up all required resources within the namespaces:

```bash
kubectl get all -n cloud-run-events


NAME                              READY   STATUS    RESTARTS   AGE
pod/controller-5f5b8979dc-tjvnh   1/1     Running   0          28s
pod/webhook-68cf7498c9-jhbz8      1/1     Running   0          27s

NAME                 TYPE        CLUSTER-IP    EXTERNAL-IP   PORT(S)    AGE
service/controller   ClusterIP   10.0.12.199   <none>        9090/TCP   28s
service/webhook      ClusterIP   10.0.10.1     <none>        443/TCP    28s

NAME                         READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/controller   1/1     1            1           29s
deployment.apps/webhook      1/1     1            1           28s

NAME                                    DESIRED   CURRENT   READY   AGE
replicaset.apps/controller-5f5b8979dc   1         1         1       29s
replicaset.apps/webhook-68cf7498c9      1         1         1       28s
```

Knative with GCP implements a few difference sources (Storage, Scheduler,
Channel, PullSubscription, Topic). We're interested in
[PullSubscription][knative-gcp-sub] to listen for Pub/Sub messages directly from
GCP.

[knative-gpc-sub]: https://github.com/google/knative-gcp/blob/master/docs/pullsubscription/README.md

## (Optional) Updating your install to use cluster local gateway

If you want to use Kubernetes Services as event sinks in PullSubscription, you
don't have to do anything extra. However, to have Knative Services as event
sinks, you need to have them only visible within the cluster by adding Istio
cluster local gateway as detailed [here][istio-local-gw].

[istio-local-gw]: https://knative.dev/docs/install/installing-istio/#updating-your-install-to-use-cluster-local-gateway

Knative Serving comes with some yaml files to install cluster local gateway.

First, you'd need to find the version of your Istio via something like this:

```bash
kubectl get pod --selector app=istio-ingressgateway -o yaml | grep image

    image: gke.gcr.io/istio/proxyv2:1.1.13-gke.0
```

In this case, it's `1.1.13`. Then, you need to point to the Istio version close
enough to your version under [third_party][knative-third-party] folder of
Knative Serving. In this case, we'll use `1.2.7`:

[knative-third-party]: https://github.com/knative/serving/tree/master/third_party

```bash
kubectl apply --wait \
  -f https://raw.githubusercontent.com/knative/serving/master/third_party/istio-1.2.7/istio-knative-extras.yaml

serviceaccount/cluster-local-gateway-service-account created
serviceaccount/istio-multi configured
clusterrole.rbac.authorization.k8s.io/istio-reader configured
clusterrolebinding.rbac.authorization.k8s.io/istio-multi configured
service/cluster-local-gateway created
deployment.apps/cluster-local-gateway created
```

At this point, you can use Knative Services as event sinks in PullSubscription.

## Create a Service Account and a Pub/Sub Topic

In order to use [PullSubscription][gcp-knative-sub], we need a Pub/Sub enabled
Service Account and instructions on how to set that up on Google Cloud is
[here][gcp-knative-pubsub].

### Installing Pub/Sub Enabled Service Account

1.  Enable the `Cloud Pub/Sub API` on your project:

    ```bash
    gcloud services enable pubsub.googleapis.com
    ```

1.  Create a [Google Cloud Service Account][gcp-sa]. This sample creates one
    service account for both registration and receiving messages, but you can
    also create a separate service account for receiving messages if you want
    additional privilege separation.

[gcp-sa]: https://console.cloud.google.com/iam-admin/serviceaccounts/project

   1.  Create a new service account named `cloudrunevents-pullsub` with the
        following command:

        ```shell
        gcloud iam service-accounts create cloudrunevents-pullsub
        ```

   1.  Give that Service Account the `Pub/Sub Editor` role on your Google Cloud
        project:

        ```shell
        export PROJECT=$(gcloud config get-value project)
        gcloud projects add-iam-policy-binding $PROJECT \
          --member=serviceAccount:cloudrunevents-pullsub@$PROJECT.iam.gserviceaccount.com \
          --role roles/pubsub.editor
        ```

   1.  **Optional:** If you plan on using the StackDriver monitoring APIs, also
        give the Service Account the `Monitoring MetricWriter` role on your
        Google Cloud project:

        ```shell
        gcloud projects add-iam-policy-binding $PROJECT \
        --member=serviceAccount:cloudrunevents-pullsub@$PROJECT.iam.gserviceaccount.com \
        --role roles/monitoring.metricWriter
        ```

   1.  Download a new JSON private key for that Service Account. **Be sure not
        to check this key into source control!**

        ```shell
        gcloud iam service-accounts keys create cloudrunevents-pullsub.json \
        --iam-account=cloudrunevents-pullsub@$PROJECT.iam.gserviceaccount.com
        ```

   1.  Create a secret on the kubernetes cluster with the downloaded key:

        ```shell
        # The secret should not already exist, so just try to create it.
        kubectl --namespace default create secret generic google-cloud-key --from-file=key.json=cloudrunevents-pullsub.json
        ```

        `google-cloud-key` and `key.json` are default values expected by
        `Channel`, `Topic` and `PullSubscription`.

[gcp-knative-pubsub]: https://github.com/google/knative-gcp/tree/master/docs/pubsub

Once you have it setup, you should have a `google-cloud-key` secret in
Kubernetes:

```bash
kubectl get secret --namespace default

NAME                  TYPE                                  DATA   AGE
google-cloud-key      Opaque                                1      20h
```

You should also create a Pub/Sub Topic to send messages too:

```bash
export TOPIC_NAME=testing
gcloud pubsub topics create $TOPIC_NAME
```

We're finally ready to receive Pub/Sub messages into Knative!

## Create Event Display

You can have any kind of addressable as event sinks in Knative eventing. In this
part, we'll show you how to use a Knative Service as event sink.

### Create Knative Service

Create a [event-display-kscv.yaml](./event-display-kscv.yaml) file:

```yaml
apiVersion: serving.knative.dev/v1alpha1
kind: Service
metadata:
  name: event-display
  namespace: default
spec:
  template:
    spec:
      containers:
        - image: docker.io/meteatamel/eventdisplay:v1
```

This defines a Knative Service to receive messages.

Create the Event Display service:

```bash
kubectl apply -f event-display-kscv.yaml

service.serving.knative.dev/event-display created
```

## Create PullSubscription

Last but not least, we need connect Event Display service to Pub/Sub messages
with a PullSubscription.

Create a [event-display-pullsub.yaml](./pullsubscription.yaml):

```yaml
apiVersion: pubsub.cloud.run/v1alpha1
kind: PullSubscription
metadata:
  name: testing-source-event-display
spec:
  topic: testing
  sink:
    # apiVersion: v1
    apiVersion: serving.knative.dev/v1alpha1
    kind: Service
    name: event-display
```

This connects the `testing` topic to `event-display` Service. Make sure you use
the right `apiVersion` depending on whether you defined a Kubernetes or Knative
service. In this case, we're using a Knative Service.

Create the PullSubscription:

```bash
kubectl apply -f event-display-pullsub.yaml

pullsubscription.pubsub.cloud.run/testing-source-event-display created
```

## Test the service

We can now test our service by sending a message to Pub/Sub topic:

```bash
gcloud pubsub topics publish testing --message="Hello World"

messageIds:
- '198012587785403'
```

Wait a little and check that a pod is created:

```bash
kubectl get pods
```

You can inspect the logs of the pod (replace `<podid>` with actual pod id):

```bash
kubectl logs --follow -c user-container -l serving.knative.dev/service=event-display
```

You should see something similar to this:

```text
Event Display received message: Hello World
```

## Automatic Autoscaling

Run the following command and wait and see what happens when there are no events
for a period of time:

```
kubectl get pods --watch
```

You should be able to observe that the `event-display` pod terminates like this:

```
event-display-794gd-deployment-65b99cbf88-9sq5b                   2/2     Terminating         0          63s
event-display-794gd-deployment-65b99cbf88-9sq5b                   1/2     Terminating         0          84s
event-display-794gd-deployment-65b99cbf88-9sq5b                   0/2     Terminating         0          85s
event-display-794gd-deployment-65b99cbf88-9sq5b                   0/2     Terminating         0          86s
event-display-794gd-deployment-65b99cbf88-9sq5b                   0/2     Terminating         0          86s
```

In a new shell run the following comamnd and observe a new `event-display` pod
magically comes to life when you trigger a new event:

```
gcloud pubsub topics publish testing --message="Another event"
```

## Clean Up

To clean up what we have done in this lab run the following commands:

```
kubectl delete \
  -f event-display-deploy.yaml \
  -f event-display-kscv.yaml \
  -f event-display-pullsub.yaml
```

---

<p align="right"><a href="../4-translation">Lab 4: Translation API →</a></p>
<p align="left"><a href="../2-rest-api">← Lab 2: REST API</a></p>

Except as otherwise noted, the content of this page is licensed under the
[Creative Commons Attribution 4.0 License][cc-by], and code samples are licensed
under the [Apache 2.0 License][apache-2-0].

[cc-by]: https://creativecommons.org/licenses/by/4.0/
[apache-2-0]: https://www.apache.org/licenses/LICENSE-2.0
