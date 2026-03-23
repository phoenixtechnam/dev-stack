#!/bin/bash
set -e

! export LC_ALL=C.UTF-8 LANG=C.UTF-8 

# ── Wait for Docker-in-Docker daemon ────────────────────────────────
echo "Waiting for Docker daemon at ${DOCKER_HOST:-tcp://dind:2375}..."
timeout 30 sh -c 'until docker info > /dev/null 2>&1; do sleep 1; done' \
    && echo "Docker daemon is ready." \
    || echo "Warning: Docker daemon not reachable (will retry when you use docker commands)."

# ── Start code-server ────────────────────────────────────────────────
exec code-server \
    --bind-addr 0.0.0.0:8080 \
    --auth password \
    --disable-telemetry \
    /workspace
