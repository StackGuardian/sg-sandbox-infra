# k3s-helm-release

Deploys [podinfo](https://github.com/stefanprodan/podinfo), a small public demo app, to a k3s cluster created by the `aws-k3s` template. It runs on StackGuardian's kubernetes workflow step with Helm, not on OpenTofu.

This directory is a wrapper chart: `Chart.yaml` pulls in the public `podinfo` chart (pinned version) as a dependency, and `values.yaml` sets one replica, small resource requests and a `ClusterIP` service. The step runs helm with `--dependency-update`, so the dependency is downloaded at run time.

## Inputs

The step reads the cluster's kubeconfig from the `KUBECONFIG_DATA` environment variable, base64-encoded. Set it to the `kubeconfig_b64` output of your `aws-k3s` workflow:

```
KUBECONFIG_DATA = ${workflow::<workflow group>.<aws-k3s workflow>.outputs.kubeconfig_b64.value}
```

The release goes to the `podinfo` namespace, which the step creates if it doesn't exist.

## Try it locally

With the kubeconfig from the `aws-k3s` outputs:

```sh
tofu output -raw kubeconfig > k3s.yaml
helm upgrade --install podinfo . --dependency-update \
  --kubeconfig k3s.yaml --namespace podinfo --create-namespace --atomic
kubectl --kubeconfig k3s.yaml -n podinfo port-forward svc/podinfo 9898:9898
```

Then open http://localhost:9898.
