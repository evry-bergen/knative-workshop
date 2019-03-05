# Knative & Istio Workshop

Knative &amp; Istio Workshop on Google Cloud for Booster 2019.

## Relevant Links

* Knative @ Google: https://cloud.google.com/knative/
* GitHub: https://github.com/knative/
* Docs: https://github.com/knative/docs
* Install: https://github.com/knative/docs/tree/master/install
  * Google Cloud: https://github.com/knative/docs/blob/master/install/Knative-with-GKE.md
* Samples: https://github.com/knative/docs/tree/master/serving/samples
* Build: https://github.com/knative/build
* Build Templates: https://github.com/knative/build-templates
* Eventing: https://github.com/knative/eventing

## Setup

1. Run `terraform apply`
2. Get Kubernetes Credentials:

```
gcloud auth login
gcloud config set project <project>
gcloud container clusters get-credentials knative-workshop --zone europe-north1-a
```

3. Grant cluster-admin permissions to the current user:

```
kubectl create clusterrolebinding cluster-admin-binding \
--clusterrole=cluster-admin \
--user=$(gcloud config get-value core/account)
```

4. Label the default namespace with `istio-injection=enabled`:

```
kubectl label namespace default istio-injection=enabled
```

5. Monitor the Istio components until all of the components show a `STATUS` of `Running` or `Completed`:

```
kubectl get pods --namespace istio-system -w
```

6. Run the `kubectl apply` command to install Knative and its dependencies:

```
kubectl apply --filename https://github.com/knative/serving/releases/download/v0.4.0/serving.yaml \
--filename https://github.com/knative/build/releases/download/v0.4.0/build.yaml \
--filename https://github.com/knative/eventing/releases/download/v0.4.0/in-memory-channel.yaml \
--filename https://github.com/knative/eventing/releases/download/v0.4.0/release.yaml \
--filename https://github.com/knative/eventing-sources/releases/download/v0.4.0/release.yaml \
--filename https://github.com/knative/serving/releases/download/v0.4.0/monitoring.yaml \
--filename https://raw.githubusercontent.com/knative/serving/v0.4.0/third_party/config/build/clusterrole.yaml
```
