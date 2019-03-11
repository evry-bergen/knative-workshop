# Example Knative function

The point with FaaS is to focus on what your code is supposed to do, not how it is executed.
Source-to-URL can be seen as a different definition of the same thing.

There are many such platforms, but Knative is designed as a standard that platforms can implement.
The promise is that your logic can be vendor neutral.

A prospective end user would use Knative through a frontend or CLI.
The `kubectl` commands in the example below would be hidden to the end user.
Source-to-URL means the end user need only to know how to:
 * Push source to a repo.
 * Associate this source with a build template.
 * Decide which revision(s) that should receive traffic.
 * Hit the public URL.

## Chosing a runtime

Given that your function is a piece of code, possibly importing other pieces and libraries,
you need to select a _runtime_.
Your organization will likely want to standarize on a couple of runtimes,
matched with coding conventions.

With Knative your code will run as an HTTP/gRPC server.
Your function is a handler for incoming requests or events,
and the wrapping of that handler can be seen as boilerplate.
Ultimately, in year 2018, that wrapping is a container image.

## Push source to a repo

Our repository contains one or more "example-" folders with source that should be supported.
That's how we scope and test the build template.

First, clone or fork this repository.
Being vendor neutral as promised, to `kubectl apply` the example you need a [Knative cluster](https://github.com/knative/docs/blob/master/install/README.md).

However, two aspects are not vendor neutral:

 * The domain of the URLs that point to your cluster.
   - The example value is _`example.com`_.
 * The image URLs, your registry for runtime container images.
   - The example value is _`knative-local-registry:5000`_.

Treat these example values as placeholders and replace them with the values from your cluster.

### The `knative-build` service account

As authenticated container registries is the norm,
the build manifests here include `serviceAccountName: knative-build` in order to support authentication.
Use a [stub](https://github.com/triggermesh/knative-local-registry#use-a-service-account-for-build) if you don't need authentication,
or simply remove the property.

## Using Riff's invoker as Node.js runtime

We evaluated [Kubeless](https://kubeless.io/),
[Buildpack](https://docs.cloudfoundry.org/buildpacks/),
and [Riff](https://projectriff.io/invokers/) for this example.
Our conclusions in essence:

 * Kubeless has quite a bit of legacy.
 * While supporting multiple languages, Buildpack does the build but doesn't actually provide an invoker for your function.
 * Riff's nodejs invoker supports both standalone functions and full Node.js modules.

Hence we settled for riff now, but the lock-in is minimal.
Riff's function model is simple, as in this square example:

```nodejs
module.exports = x => x * x;
```

Our example function will depend on an additional source file and a 3rd party library.
For production builds we adhere to new-ish [npm](https://blog.npmjs.org/post/171556855892/introducing-npm-ci-for-faster-more-reliable) conventions,
using `package-lock.json` with [npm ci](https://docs.npmjs.com/cli/ci).

## Source-to-URL workflow using kubectl

The [hello-world](./hello-world/) folder contains a basic handler,
with some understanding of how the runtime handles argument types.

First create the build template:

```bash
kubectl apply -f knative-build-template.yaml
```

The start the service which builds itself:

```bash
kubectl apply -f ./hello-world/
```

You can now wait for the build and the subsequent deployment using `kubectl get pods -w`.

When the deployment is 3/3 ready, use the DOMAIN shown by `kubectl get ksvc nodejs-runtime-hello` to access the service. This runtime requires POST, for example `curl -d 'Knative' nodejs-runtime-hello.default.example.com`.

If your cluster lacks an external domain see next example for how to curl from inside the cluster.

## Example of routes and builds

The [example-module](./example-module/) contains an example of a Node.js module with a dependency.
It also, instead of a Service, has individual build yaml files and routes that you can edit.

```bash
cd ./example-module
kubectl apply -f build-r00001.yaml
```

List configurations and their age:

```bash
kubectl get configuration.serving.knative.dev
```

Optionally use `kubectl describe configuration.serving.knative.dev/[name from list]` to see status.

List the builds that have been generated:

```bash
kubectl get build.build.knative.dev
```

Builds sometimes fail, so let's hope your Knative vendor provides easy [access to logs](https://github.com/knative/docs/blob/master/serving/accessing-logs.md) indexed for your build.
In the meantime let's use `kubectl` and the step names from the build template
(assuming the generated steps "creds-initializer" and "git-source" succeed).

```
SELECTOR="build-name=nodejs-runtime-example-module-00001"
kubectl logs -l $SELECTOR -c build-step-dockerfile
kubectl logs -l $SELECTOR -c build-step-export
```

Now Knative should look up the image digest and produce an exact revision spec:

```bash
kubectl get revision.serving.knative.dev
```

... and the generated deployment should have the image digest (which Serving looks up) set:

```bash
kubectl get deploy/nodejs-runtime-example-module-00001-deployment -o=jsonpath='{.spec.template.spec.containers[0].image}{"\n"}'
```

... and it will bing up a pod. Logs for that are found using:

```bash
kubectl logs -l serving.knative.dev/configuration=nodejs-runtime-example-module -c user-container
```

If no pod is brought up you might want to look for error messages in `kubectl get configuration.serving.knative.dev/nodejs-runtime-example-module -o yaml`.
You might also want to look for pull errors etc in the generated deployment `kubectl describe deploy/nodejs-runtime-example-module-00001-deployment`.

If a pod is running, create a route and use `describe` to see your public and local URL.

```bash
kubectl apply -f route-r00001.yaml
kubectl describe route.serving.knative.dev/nodejs-runtime-example-module
```

To test the route through the cluster's internal name.

```
kubectl run -i -t knative-test-client --image=gcr.io/cloud-builders/curl --restart=Never --rm -- \
  -H 'Host: nodejs-runtime-example-module.default.example.com' \
  -H 'Content-Type: text/plain' \
  -d 'Aguid this!' \
  --connect-timeout 3 --retry 10 -vSL -w '\n' \
  http://knative-ingressgateway.istio-system.svc.cluster.local/
```

If the function call worked your response from curl is the deterministic UUID.

### Build your next revision and route traffic

The function source is fixed in this example,
but its output can be altered using the SALT env.
To Knative a new image digest and a new env value
are both valid causes for generating a new Revison.
Hence we trigger an almost identical build.

```
kubectl apply -f build-r00002.yaml
```

There's an example route which directs 50% of the traffic to each of the two revisions.

```
kubectl apply -f route-r00002.yaml
```

Now we can test repeated calls:

```
kubectl run -i -t knative-test-client --image=gcr.io/cloud-builders/curl --restart=Never --rm -- \
  -H 'Host: nodejs-runtime-example-module.default.example.com' \
  -H 'Content-Type: text/plain' \
  -d 'Aguid this!' \
  -s -w '\n' \
  http://knative-ingressgateway.istio-system.svc.cluster.local/?test=[1-20]
```

## Support

We would love your feedback on this project so don't hesitate to let us know what is wrong and how we could improve it, just file an [issue](https://github.com/triggermesh/nodejs-runtime/issues/new)

## Code of Conduct

This work is by no means part of [CNCF](https://www.cncf.io/) but we abide by its [code of conduct](https://github.com/cncf/foundation/blob/master/code-of-conduct.md)
