#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

CLUSTER_NAME="${CLUSTER_NAME:-infra-1}"
RELEASE_NAME="${RELEASE_NAME:-squid}"
SQUID_NAMESPACE="${SQUID_NAMESPACE:-default}"
SQUID_PORT="${SQUID_PORT:-3128}"
RETRY_DELAY="${RETRY_DELAY:-3}"
CHART_DIR="$SCRIPT_DIR/port-forward-proxy"
PID_FILE="/tmp/squid-port-forward-${CLUSTER_NAME}.pid"
LOG_FILE="/tmp/squid-port-forward-${CLUSTER_NAME}.log"

SVC_NAME="${RELEASE_NAME}-port-forward-proxy"
POD_LABEL_SELECTOR="app.kubernetes.io/instance=${RELEASE_NAME},app.kubernetes.io/name=port-forward-proxy"

echo "Installing squid proxy helm chart (release: ${RELEASE_NAME}, namespace: ${SQUID_NAMESPACE})..."
helm --kube-context "$CLUSTER_NAME" upgrade --install "$RELEASE_NAME" \
  --namespace "$SQUID_NAMESPACE" \
  --wait \
  "$CHART_DIR"

# If a previous watcher loop is already running, skip starting a new one.
if [[ -f "$PID_FILE" ]]; then
  existing_pid=$(cat "$PID_FILE")
  if kill -0 "$existing_pid" 2>/dev/null; then
    echo "Port-forward watcher already running (PID: ${existing_pid}). Skipping."
    exit 0
  fi
  rm -f "$PID_FILE"
fi

echo "Starting background port-forward watcher (log: ${LOG_FILE})..."

(
  echo $$ > "$PID_FILE"
  trap 'rm -f "$PID_FILE"' EXIT

  while true; do
    running_pods=$(kubectl --context "$CLUSTER_NAME" -n "$SQUID_NAMESPACE" \
      get pod -l "$POD_LABEL_SELECTOR" \
      --field-selector=status.phase=Running \
      --no-headers 2>/dev/null | wc -l)

    if [[ "$running_pods" -eq 0 ]]; then
      echo "[squid port-forward] No running proxy pod found. Stopping watcher."
      break
    fi

    echo "[squid port-forward] Starting port-forward localhost:${SQUID_PORT} -> svc/${SVC_NAME}..."
    kubectl --context "$CLUSTER_NAME" -n "$SQUID_NAMESPACE" \
      port-forward "svc/${SVC_NAME}" "${SQUID_PORT}" || true

    running_pods=$(kubectl --context "$CLUSTER_NAME" -n "$SQUID_NAMESPACE" \
      get pod -l "$POD_LABEL_SELECTOR" \
      --field-selector=status.phase=Running \
      --no-headers 2>/dev/null | wc -l)

    if [[ "$running_pods" -eq 0 ]]; then
      echo "[squid port-forward] Proxy pod stopped. Not restarting."
      break
    fi

    echo "[squid port-forward] Port-forward exited. Retrying in ${RETRY_DELAY}s..."
    sleep "$RETRY_DELAY"
  done
) >> "$LOG_FILE" 2>&1 &

# disown removes the background job from the shell's job table so it is not
# sent SIGHUP when the parent shell (e.g. bootstrap-infra.sh) exits. Without
# this the watcher process would be terminated as soon as the calling script
# finishes, defeating the point of running it in the background.
disown $!
echo "Port-forward watcher started (PID: $!, log: ${LOG_FILE})"
