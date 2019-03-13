# Lab 4: Guestbook with Knative

A simple web app written in Go that demonstrates how to deploy Redis (using
vanilla Kubernetes components) alongside a Knative Service that relies on
it. The guestbook application shows a page with a form that allows users to
leave a message under a name of their choosing. Names and messages map to keys
and values in Redis, so only one message per user is saved at a time.

## Deploy Redis

Although the configuration in this sample is intentionally very simple, Redis
can require relatively complex configuration that Knative does not support.
Luckily, Knative allows you to mix and match Knative components with vanilla
Kubernetes components.

The Redis configuration consists of two parts:

* `Deployment`: contains a minimal configuration for a single Redis instance,
  named `redis-master`.

* `Service`: contains a Kubernetes `Service` that finds `redis-master` by its
  name and role labels and routes requests to it. The `REDIS_HOST` environment
  variable in `guestbook.yaml` refers to the name of the `Service`, also named
  `redis-master`, not the name of the `Deployment`.

> Note: Don't confuse a Kubernetes `Service` with a Knative `Service`. A Knative
> `Service` handles the deployment, scaling, and routing for a workload. A
> Kubernetes `Service` routes requests to an existing deployment.

Deploy this to you Kubernetes cluster using `kubectl`:

```shell
kubectl apply -f redis.yaml
```

## Deploy the Guestbook Application

As with the previous lab assignments this too uses the Knative
[Build][knative-build] and [Serve][knative-serve] components in order to build
the Guestbook application from soure and running it in one go.

[knative-build]: https://www.knative.dev/docs/build
[knative-serving]: https://www.knative.dev/docs/serving/

Simply deploy the Guestbook application by running the following command:

```shell
kubectl apply -f guestbook.yaml
```

## Exploring

Note: the following example uses `curl` to make requests to the application. You
can also use your browser by following the steps in the [routing
sample](/serving/samples/knative-routing-go) to route requests to `/` to the
guestbook `Service`.

To access this service, you need to determine its ingress address:

```shell
kubectl get svc knative-ingressgateway -n istio-system
```

When the service is ready, you'll see an IP address in the `EXTERNAL-IP` field:

```
NAME                     TYPE           CLUSTER-IP     EXTERNAL-IP      PORT(S)                                      AGE
knative-ingressgateway   LoadBalancer   10.23.247.74   35.203.155.229   80:32380/TCP,443:32390/TCP,32400:32400/TCP   2d
```

Once the `EXTERNAL-IP` gets assigned to the cluster, you can run:

```shell
# Put the host name into an environment variable.
export SERVICE_HOST=`kubectl get route guestbook -o jsonpath="{.status.domain}"`
# Put the ingress IP into an environment variable.
export SERVICE_IP=`kubectl get svc knative-ingressgateway -n istio-system -o jsonpath="{.status.loadBalancer.ingress[*].ip}"`
```

Now use curl with the service IP as if DNS were properly configured:

```shell
curl --header "Host:$SERVICE_HOST" http://${SERVICE_IP}
# [...]
# <form action="/" method="post">
#  <div>Name: <input name="name"></div>
#  <div>Message: <input name="message"></div>
#  <input type="submit">
# </form>
# <ul>
#
# </ul>
# [...]
```

Note that the inputs are named `name` and `message`. You can use `curl` to POST
data to the form as shown below:

```shell
curl -X POST -F "name=someone" -F "message=Hello, Knative!" --header "Host:$SERVICE_HOST" http://${SERVICE_IP}
# [...]
# <ul>
#   <li><strong>someone</strong>: Hello, Knative!</li>
# </ul>
# [...]
```

```shell
curl -X POST -F "name=knative_user" -F "message=I love Knative!" --header "Host:$SERVICE_HOST" http://${SERVICE_IP}
# [...]
# <ul>
#   <li><strong>knative_user</strong>: I love Knative!</li>
#   <li><strong>someone</strong>: Hello, Knative!</li>
# </ul>
# [...]
```

## Cleaning up

When you're done, clean up the sample resources:

```shell
kubectl delete -f serving/samples/guestbook-redis-go/redis-deployment.yaml
kubectl delete -f serving/samples/guestbook-redis-go/redis-service.yaml
kubectl delete -f serving/samples/guestbook-redis-go/guestbook.yaml
```

## Next Steps

For simplicity, this sample showed a configuration for Redis with a single
server. In practice, that wouldn't scale very well for a real application. See
the [Kubernetes example repository](https://github.com/kubernetes/examples/tree/master/staging/storage/redis)
for a more scalable deployment configuration for Redis on Kubernetes. That
example does not include a service that allows other applications to connect to
Redis, but you can use `redis-service.yaml` since it selects on the same name
and role labels.

Alternatively, you may prefer to use a managed solution from your cloud provider
(e.g. [Cloud Memorystore](https://cloud.google.com/memorystore/)). To access
services outside of the cluster, you'll have to
[configure outbound network access](/serving/outbound-network-access.md).

Whichever way you go, you can use the guestbook container to test your Redis
deployment. Just change the `REDIS_HOST` environment variable in
`guestbook.yaml` to the correct host name.
