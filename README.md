# Local Lab

VsCode dev-container sandbox for experiments in a local Kubernetes (Minikube) environment, which includes a local [dev CA](.devcontainer/ca-cert.pem). The convention is to use "sslip.io"-based domain names to avoid having a lab-local DNS server. To make integration with Windows easier (when running dev-container within WSL2), there is also a [proxy server](./infra/squid/README.md) running along with pre-configured port-forwarding in VsCode.

The sandbox consists of at least one "infra" cluster, where "platform" services are supposed to run, although a very limited amount of those are pre-configured in this repo. See [bootstrap-infra.sh](./infra/bootstrap-infra.sh) for details.

You can then create additional repos for (dummy) "workloads" if you want to test something that is "intra-cluster" or just requires several of them. There is a [create-cluster.sh](./infra/create-cluster.sh) script you can use for that. Pay attention to env-variables and IPv4 addresses (you can use `bootstrap-infra.sh` as a reference).

## Intended usage

There is a directory "lab" which is not tracked by this repository (gitignored). You will typically create sub-directories there e.g. "lab/vault" for specific experiments (which may be completely separate repos).

## Local image registry

The [docker-registry] installation in the `infra-1` cluster can be accessed via <https://registry.192.168.128.11.sslip.io>.

No authentication is required for pushing or pulling (or deleting).

The HTTPS traffic is served with a TLS certificate signed by the local dev CA which removes the need for tweaking insecure connections in (e.g.) `docker` or creating special image pull secrets in the minikube clusters.

## Cheat sheet (by example)

```shell
docker push registry.192.168.128.11.sslip.io/hello-world:latest
```

```shell
docker pull registry.192.168.128.11.sslip.io/hello-world:latest
```

```shell
oras repo ls registry.192.168.128.11.sslip.io
```

```shell
oras repo tags registry.192.168.128.11.sslip.io/hello-world
```

```shell
oras discover registry.192.168.128.11.sslip.io/hello-world:latest
```

```shell
oras manifest delete registry.192.168.128.11.sslip.io/hello-world:latest
```