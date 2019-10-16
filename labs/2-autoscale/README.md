### Configure Autoscaling

You might have realized that the autoscaler in Knative scales down pods to zero after some time. This is actually configurable through annotations. The type of autoscaler itself is also configurable. [Autoscale Sample][autoscale-sample] in Knative docs explains the details of the autoscaler but let's recap the main points.

There are two autoscaler classes built into Knative:

    1. The default concurrency-based autoscaler which is based on the average number of in-flight requests per pod.
    2. Kubernetes CPU-based autoscaler which autoscales on CPU usage.

The autoscaling can be bounded with `minScale`and `maxScale` annotations.

[autoscale-sample]: https://knative.dev/docs/serving/samples/autoscale-go/index.html 


## Configure autoscale 

Take a look at the `service-v1.yaml` file:

```yaml
apiVersion: serving.knative.dev/v1alpha1
kind: Service
metadata:
  name: sleepingservice
  namespace: default
spec:
  template:
    metadata:
      annotations:
        # Default: Knative concurrency-based autoscaling with
        # 100 requests in-flight per pod.
        autoscaling.knative.dev/class:  kpa.autoscaling.knative.dev
        autoscaling.knative.dev/metric: concurrency
        # Changed target to 1 to showcase autoscaling
        autoscaling.knative.dev/target: "1"

        # Alternative: Kubernetes CPU-based autoscaling.
        # autoscaling.knative.dev/class:  hpa.autoscaling.knative.dev
        # autoscaling.knative.dev/metric: cpu

        # Disable scale to zero with a minScale of 1.
        autoscaling.knative.dev/minScale: "1"
        # Limit max scaling to 5 pods.
        autoscaling.knative.dev/maxScale: "5"
    spec:
      containers:
        # Replace {username} with your actual DockerHub
        - image: docker.io/randax/sleepingservice:v1
```

Start it with:
```shell
kubectl apply --filename service-v1.yaml
```

## Test autoscaling
Let's send some traffic to our service to see that is scales up. For that we will use [Fortio][fortio-url].

# Cloud Console

```shell
 go get fortio.org/fortio
```

# MacOS

```shell
 brew install fortio
```

Next we need the url of the service

```shell
kubectl get ksvc
NAME              URL                                                 LATESTCREATED           LATESTREADY             READY   REASON
sleepingservice   http://sleepingservice.default.35.228.69.5.xip.io   sleepingservice-jfmkx   sleepingservice-jfmkx   True
```

let start the load test with fortio you need to load more then one request per pod to trigger the upscaling

```shell
 fortio load -t 0 http://fib-knative.default.35.228.69.5.xip.io/1000
```

After a while you should see pods scaling up to 5: 

```shell
kubectl get pods -w
NAME                                                READY   STATUS    RESTARTS   AGE
sleepingservice-jfmkx-deployment-7d9b967b95-gm7m2   2/2     Running   0          5m2s
sleepingservice-jfmkx-deployment-7d9b967b95-x9r2m   0/2     Pending   0          0s
sleepingservice-jfmkx-deployment-7d9b967b95-x9r2m   0/2     Pending   0          0s
sleepingservice-jfmkx-deployment-7d9b967b95-x9r2m   0/2     ContainerCreating   0          1s
sleepingservice-jfmkx-deployment-7d9b967b95-f5j4v   0/2     Pending             0          0s
sleepingservice-jfmkx-deployment-7d9b967b95-f5j4v   0/2     Pending             0          0s
sleepingservice-jfmkx-deployment-7d9b967b95-f5j4v   0/2     ContainerCreating   0          0s
sleepingservice-jfmkx-deployment-7d9b967b95-8blhb   0/2     Pending             0          0s
sleepingservice-jfmkx-deployment-7d9b967b95-8blhb   0/2     Pending             0          0s
sleepingservice-jfmkx-deployment-7d9b967b95-nl4k4   0/2     Pending             0          0s
sleepingservice-jfmkx-deployment-7d9b967b95-nl4k4   0/2     Pending             0          0s
sleepingservice-jfmkx-deployment-7d9b967b95-nl4k4   0/2     ContainerCreating   0          1s
sleepingservice-jfmkx-deployment-7d9b967b95-8blhb   0/2     ContainerCreating   0          1s
sleepingservice-jfmkx-deployment-7d9b967b95-x9r2m   1/2     Running             0          10s
sleepingservice-jfmkx-deployment-7d9b967b95-x9r2m   2/2     Running             0          10s
sleepingservice-jfmkx-deployment-7d9b967b95-nl4k4   1/2     Running             0          3s
sleepingservice-jfmkx-deployment-7d9b967b95-8blhb   1/2     Running             0          3s
sleepingservice-jfmkx-deployment-7d9b967b95-8blhb   2/2     Running             0          3s
```

#Clean up

After you're done remember to clean up. 
```shell
kubectl delete --filename service-v1.yaml
```

# Extra assignment (Optional)
Try change the autoscaling to CPU-based autoscaling. 


[fortio-url]: https://github.com/fortio/fortio
