# Lab 1: Knative Serve

This guide shows you how to deploy an app using Knative, then interact with it
using cURL requests.

## Sample application

This guide uses the [Hello World sample app in Go][helloworld-go] to demonstrate
the basic workflow for deploying an app, but these steps can be adapted for your
own application if you have an image of it available on [Docker
Hub][docker-hub], [Google Container Registry][google-gcr], or another container
image registry.

[helloworld-go]: https://github.com/knative/docs/tree/master/docs/serving/samples/hello-world/helloworld-go
[docker-hub]: https://docs.docker.com/docker-hub/repos/
[google-gcr]: https://cloud.google.com/container-registry/docs/pushing-and-pulling

The Hello World sample app reads in an `env` variable, `TARGET`, from the
configuration `.yaml` file, then prints "Hello World: \${TARGET}!". If `TARGET`
isn't defined, it will print "NOT SPECIFIED".

## Configuring your deployment

To deploy an app using Knative, you need a configuration `.yaml` file that
defines a Service. For more information about the Service object, see the
[Resource Types documentation][knative-service].

[knative-service]: https://github.com/knative/serving/blob/master/docs/spec/overview.md#service

This configuration file specifies metadata about the application, points to the
hosted image of the app for deployment, and allows the deployment to be
configured. For more information about what configuration options are available,
see the [Serving spec documentation][knative-serving].

[knative-serving]: https://github.com/knative/serving/blob/master/docs/spec/spec.md

Create a new file named `service.yaml`, then copy and paste the following
content into it:

```yaml
apiVersion: serving.knative.dev/v1alpha1
kind: Service
metadata:
  name: helloworld # the name of the app
  namespace: default # The namespace the app will use
spec:
  template:
    spec:
      containers:
        - image: evryace/knative-serving-hello-world-go:0.9.0 # The URL tp the image of the app
          env:
            - name: TARGET # The enviroment variable printed out by the sample app
              value: "Go Sample v1"
```



If you want to deploy the sample app, leave the config file as-is. If you're
deploying an image of your own app, update the name of the app and the URL of
the image accordingly.

## Deploying your app

From the directory where the new `service.yaml` file was created, apply the
configuration:

```shell
kubectl apply --filename service.yaml
```

Now that your service is created, Knative will perform the following steps:

- Create a new immutable revision for this version of the app.
- Perform network programming to create a route, ingress, service, and load
  balancer for your app.
- Automatically scale your pods up and down based on traffic, including to zero
  active pods.

You can check that pods are created and all Knative constructs (service, configuration, revision, route) have been deployed : 

```shell
kubectl get pod,ksvc,configuration,revision,route
NAME                                     URL                                            LATESTCREATED      LATESTREADY        READY   REASON
service.serving.knative.dev/helloworld   http://helloworld.default.35.228.69.5.xip.io   helloworld-qlzlj   helloworld-qlzlj   True
NAME                                           LATESTCREATED      LATESTREADY        READY   REASON
configuration.serving.knative.dev/helloworld   helloworld-qlzlj   helloworld-qlzlj   True
NAME                                            CONFIG NAME   K8S SERVICE NAME   GENERATION   READY   REASON
revision.serving.knative.dev/helloworld-qlzlj   helloworld    helloworld-qlzlj   1            True
NAME                                   URL                                            READY   REASON
route.serving.knative.dev/helloworld   http://helloworld.default.35.228.69.5.xip.io   True
```

### Interacting with your app

To test the service, we need to find the url of the service. 

```shell
kubectl get ksvc
NAME         URL                                            LATESTCREATED      LATESTREADY        READY   REASON
helloworld   http://helloworld.default.35.228.69.5.xip.io   helloworld-qlzlj   helloworld-qlzlj   True
```

URL consists of `http://{service}.{namespace}.{ip}.xip.no`

Make a request to your service: 

```shell
curl -H "Host: helloworld.default.35.228.69.5.xip.io" http://helloworld.default.35.228.69.5.xip.io
Hello v1!
```

You've successfully deployed your first application using Knative!

## Cleaning up

To remove the sample app from your cluster, delete the service record:

```shell
kubectl delete --filename service.yaml
```

---

<p align="right"><a href="../2-build">Lab 2: Knative Build →</a></p>
<p align="left"><a href="../0-setup">← Lab 0: Knative Setup</a></p>

Except as otherwise noted, the content of this page is licensed under the
[Creative Commons Attribution 4.0 License][cc-by], and code samples are licensed
under the [Apache 2.0 License][apache-2-0].

[cc-by]: https://creativecommons.org/licenses/by/4.0/
[apache-2-0]: https://www.apache.org/licenses/LICENSE-2.0
