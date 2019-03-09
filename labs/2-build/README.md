# Lab 2: Knative Build

A Go sample that shows how to use Knative to go from source code in a git
repository to a running application with a URL.

This lab assignment uses the [Build][knative-build] and
[Serving][knative-serving] components of Knative to orchestrate an end-to-end
deployment.

[knative-build]: https://www.knative.dev/docs/build/
[knative-serving]: https://www.knative.dev/docs/serving/

### Register secrets for Contianer Registry

In order to push the container that is built from source to Docker Hub, register
a secret in Kubernetes for authentication with Docker Hub.

There are [detailed instructions][knative-build-auth] available, but these are
the key steps:

[knative-build-auth]: https://github.com/knative/docs/blob/master/build/auth.md#basic-authentication-docker

1. Create a new Service Account on your Google Cloud that will be used
   authenticating with and pushing images to the Google Contianer Registry:

   ```bash
   export PROJECT=$(gcloud config get-value project)
   export ACCOUNT_NAME=knative-build
   gcloud iam service-accounts create ${ACCOUNT_NAME} --display-name="Knative build account"
   ```

1. Grant the new Service Account the `roles/storage.admin` IAM role in order to
   be able to push new images to the registry:

   ```bash
   export ACCOUNT_EMAIL=$(gcloud iam service-accounts list | grep "${ACCOUNT_NAME}" | awk '{ print $NF }')
   gcloud projects add-iam-policy-binding ${PROJECT} \
    --member=serviceAccount:${ACCOUNT_EMAIL} \
    --role=roles/storage.admin
   ```

1. Download service account JSON key:

   ```bash
   gcloud iam service-accounts keys create account.json --iam-account=${ACCOUNT_EMAIL}
   ```

1. Create a new `Secret` manifest, which is used to store your Docker Hub
   credentials. Save this file as `docker-secret.yaml`:

   ```yaml
   apiVersion: v1
   kind: Secret
   metadata:
     name: gcr-auth
     annotations:
       build.knative.dev/docker-0: https://eu.gcr.io
   type: kubernetes.io/basic-auth
   data:
     # This should just be _json_key
     username: _json_key
     # Use 'cat account.json | base64' to generate this string
     password: BASE64_ENCODED_KEY
   ```

1. On macOS or Linux computers, use the following command to generate the
   base64-encoded value required for the manifest:

   ```shell
   $ cat account.json | base64 -w 0
   ```

   > **Note:** If you receive the "invalid option -w" error on macOS, try using
   > the `base64 -b 0` command.

1. Create a new `Service Account` manifest which is used to link the build
   process to the secret. Save this file as `service-account.yaml`:

   ```yaml
   apiVersion: v1
   kind: ServiceAccount
   metadata:
     name: build-bot
   secrets:
     - name: gcr-auth
   ```

1. After you have created the manifest files, apply them to your cluster with `kubectl`:

   ```shell
   $ kubectl apply --filename docker-secret.yaml
   secret "basic-user-pass" created
   $ kubectl apply --filename service-account.yaml
   serviceaccount "build-bot" created
   ```

## Deploying the sample

Now that you've configured your cluster accordingly, you are ready to deploy the
sample service into your cluster.

This sample uses `github.com/mchmarny/simple-app` as a basic Go application, but
you could replace this GitHub repo with your own. The only requirements are that
the repo must contain a `Dockerfile` with the instructions for how to build a
container for the application.

1. You need to create a service manifest which defines the service to deploy,
   including where the source code is and which build-template to use. Create a
   file named `service.yaml` and copy the following definition. Make sure to
   replace `{PROJECT}` with your Google Cloud project name:

   ```yaml
   apiVersion: serving.knative.dev/v1alpha1
   kind: Service
   metadata:
     name: app-from-source
     namespace: default
   spec:
     runLatest:
       configuration:
         build:
           apiVersion: build.knative.dev/v1alpha1
           kind: Build
           spec:
             serviceAccountName: build-bot
             source:
               git:
                 url: https://github.com/mchmarny/simple-app.git
                 revision: master
             template:
               name: kaniko
               arguments:
                 - name: IMAGE
                   value: docker.io/{PROJECT}/app-from-source:latest
             timeout: 10m
         revisionTemplate:
           spec:
             container:
               image: docker.io/{PROJECT}/app-from-source:latest
               imagePullPolicy: Always
               env:
                 - name: SIMPLE_MSG
                   value: "Hello Booster Conference 2019!"
   ```

1. Apply this manifest using `kubectl`, and watch the results:

   ```shell
   # Apply the manifest
   $ kubectl apply --filename service.yaml
   service "app-from-source" created

   # Watch the pods for build and serving
   $ kubectl get pods --watch
   NAME                          READY     STATUS       RESTARTS   AGE
   app-from-source-00001-zhddx   0/1       Init:2/3     0          7s
   app-from-source-00001-zhddx   0/1       PodInitializing   0         37s
   app-from-source-00001-zhddx   0/1       Completed   0         38s
   app-from-source-00001-deployment-6d6ff665f9-xfhm5   0/3       Pending   0         0s
   app-from-source-00001-deployment-6d6ff665f9-xfhm5   0/3       Pending   0         0s
   app-from-source-00001-deployment-6d6ff665f9-xfhm5   0/3       Init:0/1   0         0s
   app-from-source-00001-deployment-6d6ff665f9-xfhm5   0/3       Init:0/1   0         2s
   app-from-source-00001-deployment-6d6ff665f9-xfhm5   0/3       PodInitializing   0         3s
   app-from-source-00001-deployment-6d6ff665f9-xfhm5   2/3       Running   0         6s
   app-from-source-00001-deployment-6d6ff665f9-xfhm5   3/3       Running   0         11s
   ```

  > **Note:** If the build pod never reaches Completed status and terminates
  > after 10 minutes, Kaniko probably didn't finish pulling the build image
  > within the default timeout period. Try increasing the `timeout` value in
  > `service.yaml`.

1. Once you see the deployment pod switch to the running state, press Ctrl+C to
   escape the watch. Your container is now built and deployed!

1. To check on the state of the service, get the service object and examine the
   status block:

   ```shell
   $ kubectl get ksvc app-from-source --output yaml

   [...]
   status:
     conditions:
     - lastTransitionTime: 2019-03-11T20:50:18Z
       status: "True"
       type: ConfigurationsReady
     - lastTransitionTime: 2019-03-11T20:50:56Z
       status: "True"
       type: RoutesReady
     - lastTransitionTime: 2019-03-11T20:50:56Z
       status: "True"
       type: Ready
     domain: app-from-source.default.{PROJECT}.knative.club
     latestCreatedRevisionName: app-from-source-00007
     latestReadyRevisionName: app-from-source-00007
     observedGeneration: 10
     traffic:
     - configurationName: app-from-source
      percent: 100
       revisionName: app-from-source-00007
   ```

1. Now that your service is created, Knative will perform the following steps:

   - Fetch the revision specified from GitHub and build it into a container
   - Push the container to Docker Hub
   - Create a new immutable revision for this version of the app.
   - Network programming to create a route, ingress, service, and load balance
     for your app.
   - Automatically scale your pods up and down (including to zero active pods).

1. To get the ingress IP for your cluster, use the following command. If your
   cluster is new, it can take some time for the service to get an external IP
   address:

   ```shell
   kubectl get svc istio-ingressgateway --namespace istio-system

   NAME                   TYPE           CLUSTER-IP     EXTERNAL-IP      PORT(S)                                      AGE
   istio-ingressgateway   LoadBalancer   10.23.247.74   35.203.155.229   80:32380/TCP,443:32390/TCP,32400:32400/TCP   2d
   ```

1. To find the URL for your service, type:

   ```shell
   $ kubectl get ksvc app-from-source  --output=custom-columns=NAME:.metadata.name,DOMAIN:.status.domain
   NAME                DOMAIN
   app-from-source     app-from-source.default.{PROJECT}.knative.club
   ```

1. Now you can make a request to your app to see the result. Replace
   `{IP_ADDRESS}` with the address that you got in the previous step:

   ```shell
   curl -H "Host: app-from-source.default.{PROJECT}.knative.club" http://{IP_ADDRESS}
   Hello from the sample app!"
   ```

## Removing the sample app deployment

To remove the sample app from your cluster, delete the service record:

```shell
kubectl delete --filename service.yaml
```

---

<p align="left"><a href="../1-serve">← Lab 1: Knative Serve</a></p>
<p align="right"><a href="../3-events">Lab 3: Knative Events →</a></p>

Except as otherwise noted, the content of this page is licensed under the
[Creative Commons Attribution 4.0 License][cc-by], and code samples are licensed
under the [Apache 2.0 License][apache-2-0].

[cc-by]: https://creativecommons.org/licenses/by/4.0/
[apache-2-0]: https://www.apache.org/licenses/LICENSE-2.0
