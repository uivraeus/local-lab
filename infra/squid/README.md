# What

Setup of [Squid proxy](https://hub.docker.com/r/ubuntu/squid)

## Commands

### Install

```shell
kubectl --context lkk8s-linux-prod-01 -n canaries create configmap squid-config --from-file=squid=squid.conf
kubectl --context lkk8s-linux-prod-01 -n canaries apply -f squid-deployment.yaml
```

To remove, run:

```shell
kubectl --context lkk8s-linux-prod-01 -n canaries delete -f squid-deployment.yaml
```

### Use

#### Port-forward to proxy

```shell
kubectl --context lkk8s-linux-prod-01 -n canaries port-forward svc/squid-service 3128
```

#### Inspect logs from proxy

```shell
kubectl --context lkk8s-linux-prod-01 -n canaries logs -f -l app=squid
```

#### Verify with `curl`

```shell
curl -k -x http://localhost:3128 https://ifconfig.co
```

#### Run Terraform

```shell
export HTTPS_PROXY=http://localhost:3128
terraform apply
```

### Tear-down

```shell
kubectl --context lkk8s-linux-prod-01 -n canaries delete -f squid-deployment.yaml
kubectl --context lkk8s-linux-prod-01 -n canaries delete configmap squid-config
```
