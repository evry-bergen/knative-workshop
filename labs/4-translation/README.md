# Lab 4: Translation API

In the previous lab, our service simply logged out the received Pub/Sub event.
While this might be useful for debugging, it's not terribly exciting.

[Cloud Translation API][gcp-translate] is one of Machine Learning APIs of Google
Cloud. It can dynamically translate text between thousands of language pairs. In
this lab, we will use translation requests sent via Pub/Sub messages and use
Translation API to translate text between languages.

[gcp-translate]: https://cloud.google.com/translate/docs/

Since we're making calls to Google Cloud services, you need to make sure that
the outbound network access is enabled, as described in the previous lab.

You also want to make sure that the Translation API is enabled:

```bash
gcloud services enable translate.googleapis.com
```

## Define translation protocol

Let's first define the translation protocol we'll use in our sample. The body of
Pub/Sub messages will include text and the languages to translate from and to as
follows:

```text
{"text":"Hello World", "from":"en", "to":"es"} => English to Spanish
{"text":"Hello World", "from":"", "to":"es"} => Detected language to Spanish
{"text":"Hello World", "from":"", "to":""} => Error
```

## Deploy the Translation service

Create a [translation-kscv.yaml](./translation-kscv.yaml):

```yaml
apiVersion: serving.knative.dev/v1alpha1
kind: Service
metadata:
  name: translation
  namespace: default
spec:
  template:
    spec:
      containers:
        - image: docker.io/meteatamel/translation:v1
```

This defines a Knative Service to receive messages.

```bash
kubectl apply -f translation-kscv.yaml

service.serving.knative.dev/translation created
```

## Create PullSubscription

Last but not least, we need connect Translation service to Pub/Sub messages with
a PullSubscription.

Create a [translation-pullsub.yaml](./translation-pullsub.yaml):

```yaml
apiVersion: pubsub.cloud.run/v1alpha1
kind: PullSubscription
metadata:
  name: testing-source-translation
spec:
  topic: testing
  sink:
    apiVersion: serving.knative.dev/v1alpha1
    kind: Service
    name: translation
```

This connects the `testing` topic to `translation` Service.

Create the PullSubscription:

```bash
kubectl apply -f translation-pullsub.yaml

pullsubscription.pubsub.cloud.run/testing-source-translation created
```

## Test the service

We can now test our service by sending a translation request message to Pub/Sub
topic:

```bash
gcloud pubsub topics publish testing \
  --message='{"text":"Hello World", "from":"en", "to":"es"}'
```

Wait a little and check that a pod is created:

```bash
kubectl get pods
```

You can inspect the logs of the subscriber (replace `<podid>` with actual pod id):

```bash
kubectl logs --follow -c user-container -l serving.knative.dev/service=translation
```

You should see something similar to this:

```text
Received content: {"text":"Hello World", "from":"en", "to":"es"}

Translated text: Hola Mundo
```

## Clean Up

To clean up what we have done in this lab run the following commands:

```
kubectl delete \
  -f translation-kscv.yaml \
  -f translation-pullsub.yaml
```

---

<p align="right"><a href="../5-vision">Lab 5: Vision API →</a></p>
<p align="left"><a href="../3-events">← Lab 3: Knative Events</a></p>

Except as otherwise noted, the content of this page is licensed under the
[Creative Commons Attribution 4.0 License][cc-by], and code samples are licensed
under the [Apache 2.0 License][apache-2-0].

[cc-by]: https://creativecommons.org/licenses/by/4.0/
[apache-2-0]: https://www.apache.org/licenses/LICENSE-2.0
