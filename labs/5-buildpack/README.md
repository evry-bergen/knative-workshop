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

When the deployment is 4/4 ready, use the DOMAIN shown by `kubectl get ksvc
lab-5-nodejs` to access the service. This runtime requires POST, for
example `curl -d '{"name": "Knative"}' http://lab-5-nodejs.default.${PROJECT}.knative.club`.

## Cleaning Up

To remove the the Service run the following command:

```shell
kubectl delete -f service.yaml
```

---

<p align="left"><a href="../2-build">← Lab 4: Knative Guestbook</a></p>

Except as otherwise noted, the content of this page is licensed under the
[Creative Commons Attribution 4.0 License][cc-by], and code samples are licensed
under the [Apache 2.0 License][apache-2-0].

[cc-by]: https://creativecommons.org/licenses/by/4.0/
[apache-2-0]: https://www.apache.org/licenses/LICENSE-2.0
