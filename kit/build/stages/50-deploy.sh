#!/usr/bin/env bash
# 50-deploy.sh — invoke the environment-specific deploy command
#
# Generic by design. Delegates to environments/<env>/deploy.sh. Keep
# environment-specific logic in that file, not here.
#
# $1 = environment name

set -euo pipefail
ENV="${1:?missing environment}"

DEPLOY_SCRIPT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../environments/$ENV" && pwd)/deploy.sh"

if [[ ! -x "$DEPLOY_SCRIPT" ]]; then
  if [[ ! -f "$DEPLOY_SCRIPT" ]]; then
    echo "ERROR: deploy script not found: $DEPLOY_SCRIPT"
  else
    echo "ERROR: deploy script not executable: $DEPLOY_SCRIPT"
    echo "Run: chmod +x $DEPLOY_SCRIPT"
  fi
  exit 1
fi

exec "$DEPLOY_SCRIPT"
