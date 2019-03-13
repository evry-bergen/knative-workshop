# Lab 3: Knative Events

This labs shows how to configure the GCP PubSub event source for Knative. This
event source is most useful as a bridge from other GCP services, such as [Cloud
Storage][gcp-storage], [IoT Core][gcp-iot] and [Cloud Scheduler][gcp-scheduler].

[gcp-storage]: https://cloud.google.com/storage/docs/pubsub-notifications
[gcp-iot]: https://cloud.google.com/iot/docs/how-tos/devices
[gcp-scheduler]: https://cloud.google.com/scheduler/docs/creating

## Prerequisites

1. Enable the `Cloud Pub/Sub API` on your project:

   ```shell
   gcloud services enable pubsub.googleapis.com
   ```

1. Create a [GCP Service Account][gcp-sa].  This sample creates one service
   account for both registration and receiving messages, but you can also create
   a separate service account for receiving messages if you want additional
   privilege separation.

   [gcp-sa]: https://console.cloud.google.com/iam-admin/serviceaccounts/project

   1. Create a new service account named `knative-pubsub` with the following
      command:

      ```shell
      gcloud iam service-accounts create knative-event
      ```

   1. Give that Service Account the `Pub/Sub Editor` role on your GCP project:

      ```shell
      gcloud projects add-iam-policy-binding $PROJECT \
        --member=serviceAccount:knative-event@$PROJECT.iam.gserviceaccount.com \
        --role roles/pubsub.editor
      ```

   1. Download a new JSON private key for that Service Account. **Be sure not to
      check this key into source control!**

      ```shell
      gcloud iam service-accounts keys create knative-pubsub.json \
        --iam-account=knative-event@$PROJECT.iam.gserviceaccount.com
      ```

   1. Create two secrets on the kubernetes cluster with the downloaded key:

      ```shell
      # Note that the first secret may already have been created when installing
      # Knative Eventing. The following command will overwrite it. If you don't
      # want to overwrite it, then skip this command.
      kubectl --namespace knative-sources create secret generic gcppubsub-source-key --from-file=key.json=knative-pubsub.json --dry-run --output yaml | kubectl apply --filename -

      # The second secret should not already exist, so just try to create it.
      kubectl --namespace default create secret generic gcp-pubsub-key --from-file=key.json=knative-pubsub.json
      ```

      `gcppubsub-source-key` and `key.json` are pre-configured values in the
      `controller-manager` StatefulSet which manages your Eventing sources.

      `gcp-pubsub-key` and `key.json` are pre-configured values in
      [`gcp-pubsub-source.yaml`](./gcp-pubsub-source.yaml).

## Deployment

1. Create a Channel. This example creates a Channel called `pubsub-test` which
   uses the in-memory provisioner, with the following definition:

   ```yaml
   apiVersion: eventing.knative.dev/v1alpha1
   kind: Channel
   metadata:
     name: pubsub-test
   spec:
     provisioner:
       apiVersion: eventing.knative.dev/v1alpha1
       kind: ClusterChannelProvisioner
       name: in-memory-channel
   ```

   If you're in the samples directory, you can apply the `channel.yaml` file:

   ```shell
   kubectl apply --filename channel.yaml
   ```

1. Create a GCP PubSub Topic. If you change its name (`testing`), you also need
   to update the `topic` in the
   [`gcp-pubsub-source.yaml`](./gcp-pubsub-source.yaml) file:

   ```shell
   gcloud pubsub topics create testing
   ```

1. Replace the
   [`PROJECT` placeholder](https://cloud.google.com/resource-manager/docs/creating-managing-projects)
   in [`gcp-pubsub-source.yaml`](./gcp-pubsub-source.yaml) and apply it.

   If you're in the samples directory, you can replace `PROJECT` and
   apply in one command:

   ```shell
    sed "s/PROJECT/$(gcloud config get-value project)/g" gcp-pubsub-source.yaml | \
        kubectl apply --filename -
   ```

   If you are replacing `PROJECT` manually, then make sure you apply the
   resulting YAML:

   ```shell
   kubectl apply --filename gcp-pubsub-source.yaml
   ```

1. Create a function and subscribe it to the `pubsub-test` channel:

   ```shell
   kubectl apply --filename subscriber.yaml
   ```

## Publish

Publish messages to your GCP PubSub Topic:

```shell
gcloud pubsub topics publish testing --message="Hello world"
```

## Verify

We will verify that the published message was sent into the Knative eventing
system by looking at what is downstream of the `GcpPubSubSource`. If you
deployed the [Subscriber](#subscriber), then continue using this section. If
not, then you will need to look downstream yourself.

1. We need to wait for the downstream pods to get started and receive our event,
   wait 60 seconds.

   - You can check the status of the downstream pods with:

     ```shell
     kubectl get pods --selector serving.knative.dev/service=message-dumper
     ```

     You should see at least one.

1. Inspect the logs of the subscriber:

   ```shell
   kubectl logs --selector serving.knative.dev/service=message-dumper -c user-container
   ```

You should see log lines similar to:

```json
{
  "ID": "284375451531353",
  "Data": "SGVsbG8sIHdvcmxk",
  "Attributes": null,
  "PublishTime": "2018-10-31T00:00:00.00Z"
}
```

The log message is a dump of the message sent by `GCP PubSub`. In particular, if
you [base-64 decode](https://www.base64decode.org/) the `Data` field, you should
see the sent message:

```shell
echo "SGVsbG8sIHdvcmxk" | base64 --decode
```

Results in: "Hello world"

For more information about the format of the message, see the
[PubsubMessage documentation](https://cloud.google.com/pubsub/docs/reference/rest/v1/PubsubMessage).

---

<p align="right"><a href="../4-guestbook">Lab 4: Knative Guestbook →</a></p>
<p align="left"><a href="../2-build">← Lab 2: Knative Build</a></p>

Except as otherwise noted, the content of this page is licensed under the
[Creative Commons Attribution 4.0 License][cc-by], and code samples are licensed
under the [Apache 2.0 License][apache-2-0].

[cc-by]: https://creativecommons.org/licenses/by/4.0/
[apache-2-0]: https://www.apache.org/licenses/LICENSE-2.0
