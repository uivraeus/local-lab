# Local Lab

## Local image registry

The [docker-registry] installation in the `infra-1` cluster can be accessed via <https://registry.192.168.128.11.sslip.io>.

No authentication is required for pushing or pulling (or deleting).

The HTTPS traffic is served with a TLS certificate signed by the local [dev CA](.devcontainer/ca-cert.pem) which removes the need for tweaking insecure connections in (e.g.) `docker` or creating special image pull secrets in the minikube clusters.

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