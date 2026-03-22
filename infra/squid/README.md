# Squid Proxy For Local Lab

This directory provides a local Squid proxy container for access to selected HTTPS endpoints in the local lab network.

## What It Does

- Runs Squid in Docker as container `squid-host`.
- Uses `squid.conf` from this directory.
- Binds Squid to `127.0.0.1:3128` in the runtime environment.
- Restricts outbound proxy traffic by ACL rules.

The proxy is started by:

- `infra/squid/start-squid.sh`

It is also invoked from:

- `infra/bootstrap-infra.sh`

## Current Access Policy

Current `squid.conf` behavior is intentionally restrictive:

- Outbound traffic allowed only to port `443`.
- Allowed destination domains are limited to hosts matching:
  - `*.192.168.128.*.sslip.io`

Requests outside those rules are denied.

## Start Or Restart Proxy

From repository root:

```bash
./infra/squid/start-squid.sh
```

This script removes any previous `squid-host` container and starts a fresh one.

## Client Usage

Use HTTP scheme for the proxy URL, including HTTPS targets:

```bash
export HTTPS_PROXY=http://127.0.0.1:3128
```

Example request expected to be allowed (if target service is up):

```bash
curl -vk --proxy http://127.0.0.1:3128 https://registry.192.168.128.11.sslip.io/
```

Example request expected to be denied by ACL:

```bash
curl -vk --proxy http://127.0.0.1:3128 https://ifconfig.me
```

## Common Pitfall

Do not set proxy URL to `https://...`.

Incorrect:

```bash
export HTTPS_PROXY=https://127.0.0.1:3128
```

Correct:

```bash
export HTTPS_PROXY=http://127.0.0.1:3128
```

## Helpful Commands

```bash
docker ps --filter name=squid-host
docker logs -f squid-host
docker rm -f squid-host
```
