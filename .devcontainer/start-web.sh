#!/usr/bin/env bash
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

if curl -fsS http://127.0.0.1:8080 >/dev/null 2>&1; then
  echo "Movera Rider web preview is already running on port 8080."
  exit 0
fi

if [ -z "${MAPS1:-}" ] && [ -z "${MAPS_WEB_API_KEY:-}" ]; then
  echo "WARNING: No MAPS1/MAPS_WEB_API_KEY Codespaces secret is available."
  echo "Flutter will still start, but the Google Map can be blank until the Maps browser key is added to Codespaces."
fi

nohup flutter run \
  -d web-server \
  --web-hostname 0.0.0.0 \
  --web-port 8080 \
  > /tmp/movera-rider-flutter.log 2>&1 &

echo $! > /tmp/movera-rider-flutter.pid
echo "Starting Movera Rider web preview on port 8080."
echo "Flutter log: /tmp/movera-rider-flutter.log"
