### Traffic Splitting

So far we have configured autoscaling of our service, but we haven't looked at how we can roll out a new revision of our service. This assignment we are rolling out a new version of the service we looked at in the autoscaling assignment.

We can look at the revsion of our service so far : 

```shell
kubectl get revision
NAME                    CONFIG NAME       K8S SERVICE NAME        GENERATION   READY   REASON
sleepingservice-jfmkx   sleepingservice   sleepingservice-jfmkx   1            True
```

For traffic splitting, it's usefull to have meaningfull revision names so that we can pin traffic to a spesfic revision. 

Create a `service-v1.yaml`

```yaml
apiVersion: serving.knative.dev/v1alpha1
kind: Service
metadata:
  name: helloworld
  namespace: default
spec:
  template:
    metadata:
      name: helloworld-v1
    spec:
      containers:
        - image: evryace/knative-serving-hello-world-go:0.9.0
          env:
            - name: TARGET
              value: "v1"
  traffic:
  - tag: current
    revisionName: helloworld-v1
    percent: 100
  - tag: latest
    latestRevision: true
    percent: 0 
```

We can see from this file that there are two important things happening. The revision now has a spesific name: `helloworld-v1` and the traffic is pinned 100% to the named revision.

Apply the change:

```shell
kubectl apply --filename service-v1.yaml
```

Lets see that we are getting traffic on the `V1`revision.

```shell
kubectl get ksvc
NAME         URL                                            LATESTCREATED   LATESTREADY     READY   REASON
helloworld   http://helloworld.default.35.228.69.5.xip.io   helloworld-v1   helloworld-v1   True

curl http://helloworld.default.35.228.69.5.xip.io
Hello v1!

```

## Deploy a new version

Create `service-v2.yaml` where we change `TARGET` to `v2`:

```yaml

apiVersion: serving.knative.dev/v1alpha1
kind: Service
metadata:
  name: helloworld
  namespace: default
spec:
  template:
    metadata:
      name: helloworld-v2
    spec:
      containers:
        - image: evryace/knative-serving-hello-world-go:0.9.0
          env:
            - name: TARGET
              value: "v2"
  traffic:
  - tag: current
    revisionName: helloworld-v1
    percent: 100
  - tag: latest
    latestRevision: true
    percent: 0        

```

```shell
kubectl apply --filename service-v2.yaml
```

If we now look at the revisions we should find both versions

```shell
kubectl get revision
NAME            CONFIG NAME   K8S SERVICE NAME   GENERATION   READY   REASON
helloworld-v1   helloworld    helloworld-v1      1            True
helloworld-v2   helloworld    helloworld-v2      2            True
```

If we now try to curl we can see that the traffic still goes to the `v1`revision

```shell
curl http://helloworld.default.35.228.69.5.xip.io
Hello v1!
```


## Split the traffic between the revisions

Let's split the traffic 50-50 between `v1`and `v2`


Create a `service-v1v2.yaml`

```yaml
apiVersion: serving.knative.dev/v1alpha1
kind: Service
metadata:
  name: helloworld
  namespace: default
spec:
  template:
    metadata:
      name: helloworld-v2
    spec:
      containers:
        
        - image: evryace/knative-serving-hello-world-go:0.9.0
          env:
            - name: TARGET
              value: "v2"
  traffic:
  - tag: current
    revisionName: helloworld-v1
    percent: 50
  - tag: candidate
    revisionName: helloworld-v2
    percent: 50
  - tag: latest
    latestRevision: true
    percent: 0
```

Apply the change: 

```shell
kubectl apply --filename service-v1v2.yaml
```

Lets send some traffic and see if the split is about 50-50:

```shell
for i in {1..10}; do curl http://helloworld.default.35.228.69.5.xip.io; sleep 1; done
Hello v2!
Hello v2!
Hello v1!
Hello v2!
Hello v1!
```




