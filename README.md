# Knative & Istio Workshop

Knative &amp; Istio Workshop on Google Cloud for Booster 2019.

## Labs

1. [Hello World](./labs/1-hello-world)

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

4. Delete the existing Istio authentication policy:

```
kubectl delete meshpolicies.authentication.istio.io default
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

## Known Bugs

**Pod Init:CrashLoopBackOff**

```
$ kubectl get pods -n knative-moitoring

NAME                                  READY     STATUS                  RESTARTS   AGE       IP
grafana-754bc795bb-jvtlk              0/2       Init:CrashLoopBackOff   6          11m       10.2.2.6
kube-state-metrics-689bcd6589-wfsgd   0/5       Init:Error              7          11m       10.2.2.5
```

Due to limitations with istio-init and pod security policies not all pods will
be able to start correctly when Istio is enabled. A common error from the
`istio-init` contianer is the following:

```
$ kubectl get logs grafana-754bc795bb-jvtlk -n knative-monitoring -c istio-init -f

iptables v1.6.0: can't initialize iptables table `nat': Permission denied (you must be root)
```

The solution is to patch the `grafana` (and other failing deployments),
commenting out the security-context like this:

```
$ kubectl edit deploy kube-state-metrics -n knative-monitoring

securityContext: {}
```

Source:
* https://groups.google.com/forum/#!topic/istio-users/MPek-mO-JXM
* https://github.com/istio/istio/issues/10358
* https://github.com/istio/old_issues_repo/issues/172
