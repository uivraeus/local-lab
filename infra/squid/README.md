# Squid Proxy

A [Squid](https://hub.docker.com/r/ubuntu/squid) HTTP/HTTPS forward proxy running inside the `infra-1` cluster, exposed to the local machine via `kubectl port-forward`. Its primary purpose is to let tools running on the dev host (browsers, `curl`, Terraform, etc.) reach cluster-internal services that are published under `sslip.io` hostnames, without requiring any changes to the host's routing table.

## Components

| File / Directory | Purpose |
|---|---|
| `port-forward-proxy/` | Helm chart that deploys the Squid pod and its ClusterIP service |
| `setup-squid-proxy.sh` | Install the chart and manage the background port-forward watcher |
| `proxy.pac` | Proxy Auto-Config script used to selectively route traffic |
| `proxy.pac.url` | `data:` URL encoding of `proxy.pac` — paste directly into OS/browser proxy settings |

## How It Works

1. `setup-squid-proxy.sh` is called from `bootstrap-infra.sh` during cluster setup.
2. It runs `helm upgrade --install` (idempotent) and waits until the pod is ready.
3. It then spawns a background port-forward watcher (`kubectl port-forward svc/squid-port-forward-proxy 3128`).
4. The watcher loop restarts the port-forward automatically if it exits, as long as the proxy pod is still running. When the pod stops, the watcher exits cleanly.

The watcher process is detached from the calling shell with `disown` so it survives after `bootstrap-infra.sh` finishes.

### Logs and PID

```
/tmp/squid-port-forward-infra-1.log   # watcher output
/tmp/squid-port-forward-infra-1.pid   # PID of the watcher loop (removed on exit)
```

## Usage

### Start / restart

```bash
# Normally invoked automatically by bootstrap-infra.sh:
./setup-squid-proxy.sh

# Override defaults:
CLUSTER_NAME=infra-1 SQUID_PORT=3128 RETRY_DELAY=3 ./setup-squid-proxy.sh
```

### Verify the proxy is reachable

```bash
curl -x http://localhost:3128 https://ifconfig.me
```

### Use with specific tools

```bash
# curl
curl -x http://localhost:3128 https://vault.192.168.128.11.sslip.io

# Terraform / OpenTofu
export HTTPS_PROXY=http://localhost:3128
terraform apply
```

### Inspect Squid logs

```bash
kubectl --context infra-1 logs -f -l app.kubernetes.io/instance=squid
```

## Proxy Auto-Config (PAC)

The PAC file (`proxy.pac`) contains a single routing rule: traffic whose hostname matches
`*.192.168.128.*.sslip.io` is sent through the local Squid proxy; everything else goes
directly.

```javascript
function FindProxyForURL(u, h) {
  if (shExpMatch(h, "*.192.168.128.*.sslip.io")) return "PROXY 127.0.0.1:3128";
  return "DIRECT";
}
```

This means only requests targeting cluster-published endpoints are proxied. General
internet traffic is unaffected.

### Configuring a browser or OS with the PAC file

Any client that supports Proxy Auto-Config can be pointed at the file. The normal approach
is to serve `proxy.pac` from an HTTP server and supply the URL. When that is inconvenient
(no local web server, air-gapped environment, quick one-off configuration), the file can
instead be embedded in a `data:` URL. That pre-encoded URL is in `proxy.pac.url`.

#### Windows — System-wide (via Settings)

1. **Settings → Network & Internet → Proxy → Use setup script**.
2. Paste the contents of `proxy.pac.url` into the *Script address* field and save.
3. No web server required; Windows reads the PAC file directly from the encoded URL.

#### Windows — System-wide (via Registry / Group Policy)

```powershell
$url = Get-Content "$env:USERPROFILE\proxy.pac.url" -Raw
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings" `
  -Name AutoConfigURL -Value $url.Trim()
```

#### macOS — System Preferences

1. **System Settings → Network → (interface) → Proxies → Automatic Proxy Configuration**.
2. Supply the `data:` URL from `proxy.pac.url` as the URL.

#### Firefox

1. **about:preferences → Network Settings → Automatic proxy configuration URL**.
2. Paste the `data:` URL from `proxy.pac.url`.

#### curl / libcurl (one-off)

```bash
curl --proxy-pinnedpubkey "" -x "pac+$(cat proxy.pac.url)" https://vault.192.168.128.11.sslip.io
```
