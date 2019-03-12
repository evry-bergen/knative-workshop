# Lab 5: Knative AWS Buildpack

The point with FaaS is to focus on what your code is supposed to do, not how it
is executed. Source-to-URL can be seen as a different definition of the same
thing.

There are many such platforms, but Knative is designed as a standard that
platforms can implement. The promise is that your logic can be vendor neutral.

A prospective end user would use Knative through a frontend or CLI.
The `kubectl` commands in the example below would be hidden to the end user.
Source-to-URL means the end user need only to know how to:
 * Push source to a repo.
 * Associate this source with a build template.
 * Decide which revision(s) that should receive traffic.
 * Hit the public URL.

## Chosing a runtime

Given that your function is a piece of code, possibly importing other pieces and
libraries, you need to select a _runtime_. Your organization will likely want to
standarize on a couple of runtimes, or [buildpacks][buildpacks], matched with
established code conventions.

[buildpacks]: https://buildpacks.io/

With Knative your code will run as an HTTP/gRPC server. Your function is a
handler for incoming requests or events, and the wrapping of that handler can be
seen as boilerplate. Ultimately, in year 2019, that wrapping is a container
image.

## The Knative Lambda Runtime

For this lab assignment we have chosen to use the
[Knative Lambda Runtime][knative-labda-runtime] by [Triggermesh][triggermesh]
a comercial Serverless offering build on top of Knative.

[knative-labda-runtime]: https://github.com/triggermesh/knative-lambda-runtime
[triggermesh]: https://triggermesh.com/

The Knative Lambda Runtimes (e.g KLR, pronounced clear) are Knative [build
templates][knative-build-templates] that can be used to run an AWS Lambda
function in a Kubernetes cluster installed with Knative.

[knative-build-templates]: https://github.com/knative/build-templates

The execution environment where the AWS Lambda function runs is a clone of the
AWS Lambda cloud environment thanks to a custom [AWS runtime
interface][aws-custom-runtime] and some inspiration from the [LambCI][labdci]
project.

[aws-custom-runtime]: https://github.com/triggermesh/aws-custom-runtime
[labdci]: https://github.com/lambci/docker-lambda

With these templates, you can run your AWS Lambda functions as is in a Knative
powered Kubernetes cluster.

## The `knative-build` service account

This lab uses the `knative-build` service account from Lab 2 in order to push
animage to the Docker Registry.

## Push source to a repo

Keep in mind that even though the code may be locally on your machine,
Knative needs to somewhere to access it from. During this workshop it will fetch
the code from the workshop's [public GitHub repository][workshop-git].

[workshop-git]: https://github.com/evry-bergen/knative-workshop

## Source-to-URL workflow using kubectl

This lab assignment contains a basic handler [`handler.js`](./handler.js) that
contians a basic handler function written in Node.JS:

```js
async function justWait() {
  return new Promise((resolve, reject) => setTimeout(resolve, 100));
}

module.exports.sayHelloAsync = async (event) => {
  console.log(event);

  await justWait();
  return {hello: event.name};
};
```

First apply the Knative Lambda Runtimes for Node.JS:

```bash
kubectl apply -f knative-node10-runtime.yaml
```

Then start the service which builds itself:

```bash
kubectl apply -f service.yaml
```

You can now wait for the build and the subsequent deployment using `kubectl get
pods -w`.

When the deployment is 3/3 ready, use the DOMAIN shown by `kubectl get ksvc
nodejs-runtime-hello` to access the service. This runtime requires POST, for
example `curl -d 'Knative' nodejs-runtime-hello.default.example.com`.

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
