# Lab 5: Vision API

[Cloud Vision API][gcp-vision] is another Machine
Learning API of Google Cloud. You can use it to derive insight from your images
with powerful pre-trained API models or easily train custom vision models with
AutoML Vision.

[gcp-vision]: https://cloud.google.com/vision/docs

In this lab, we will use a [Cloud Storage][gcp-storage] bucket to store our
images. We will also enable [Pub/Sub notifications][gcp-pubsub] on our bucket.
This way, every time we add an image to the bucket, it will trigger a Pub/Sub
message. This in turn will trigger our service where we will use Vision API to
analyze the image.

[gcp-storage]: https://cloud.google.com/storage/docs/
[gcp-pubsub]: https://cloud.google.com/storage/docs/pubsub-notifications

You want to make sure that the Vision API is enabled:

```bash
gcloud services enable vision.googleapis.com
```

## Create Vision Service

Create a [vision-ksvc.yaml](./vision-ksvc.yaml) file.

```yaml
apiVersion: serving.knative.dev/v1alpha1
kind: Service
metadata:
  name: vision
  namespace: default
spec:
  template:
    spec:
      containers:
        - image: docker.io/meteatamel/vision:v1
```

This defines a Knative Service to receive messages.

Create the Vision service:

```bash
kubectl apply -f vision-ksvc.yaml

service.serving.knative.dev/vision created
```

## Create PullSubscription

We need connect Vision service to Pub/Sub messages with a PullSubscription.

Create a [vision-pullsub.yaml](./vision-pullsub.yaml):

```yaml
apiVersion: pubsub.cloud.run/v1alpha1
kind: PullSubscription
metadata:
  name: testing-source-vision
spec:
  topic: testing
  sink:
    apiVersion: serving.knative.dev/v1alpha1
    kind: Service
    name: vision
```

This connects the `testing` topic to `vision` service.

Create the PullSubscription:

```bash
kubectl apply -f vision-pullsub.yaml

pullsubscription.pubsub.cloud.run/testing-source-vision created
```

## Create bucket and enable notifications

Before we can test the service, let's first create a Cloud Storage bucket. You
can do this [in many ways][gcp-storage-create]. We'll use `gsutil` as follows:

[gcp-storage-create]: https://cloud.google.com/storage/docs/creating-buckets

```bash
# Unique bucket name
export VISION_BUCKET="$(gcloud config get-value core/project)-vision"

gsutil mb gs://$VISION_BUCKET

Creating gs://VISION_BUCKET/...
```

Once the bucket is created, enable Pub/Sub notifications on it for object
updates and link to our `testing` topic we created in earlier labs:

```bash
gsutil notification create -t testing -f json -e OBJECT_FINALIZE gs://$VISION_BUCKET

Created notification config projects/_/buckets/VISION_BUCKET/notificationConfigs/1
```

Check that the notification is created:

```bash
gsutil notification list gs://$VISION_BUCKET

projects/_/buckets/VISION_BUCKET/notificationConfigs/1
        Cloud Pub/Sub topic: projects/PROJECT_ID/topics/testing
```

## Test the service

We can finally test our Knative service by uploading an image to the bucket.

First, let's watch the logs of the service. Wait a little and check that a pod
is created:

```bash
kubectl get pods
```

You can inspect the logs of the subscriber (replace `<podid>` with actual pod id):

```bash
kubectl logs --follow -c user-container -l serving.knative.dev/service=vision
```

Drop the image to the bucket in Google Cloud Console or use `gsutil` to copy the
file as follows:

```bash
gsutil cp path/to/picture.jpg gs://$VISION_BUCKET
```

This triggers a Pub/Sub message to our service.

You should see something similar to this:

```text
This picture is labelled: Sky,Body of water,Sea,Nature,Coast,Water,Sunset,Horizon,Cloud,Shore
```

## Clean Up

To clean up what we have done in this lab run the following commands:

```
kubectl delete \
  -f vision-kscv.yaml \
  -f vision-pullsub.yaml
```

---

<p align="left"><a href="../4-translation">← Lab 4: Translation API</a></p>

Except as otherwise noted, the content of this page is licensed under the
[Creative Commons Attribution 4.0 License][cc-by], and code samples are licensed
under the [Apache 2.0 License][apache-2-0].

[cc-by]: https://creativecommons.org/licenses/by/4.0/
[apache-2-0]: https://www.apache.org/licenses/LICENSE-2.0
