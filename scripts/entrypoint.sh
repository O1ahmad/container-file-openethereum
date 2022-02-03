#!/bin/bash
set -eo pipefail

# Print all commands executed if DEBUG mode enabled
[ -n "${DEBUG:-""}" ] && set -x


DIR=/docker-entrypoint.d
if [[ -d "$DIR" ]] ; then
  echo "Executing entrypoint scripts in $DIR"
  /bin/run-parts --exit-on-error "$DIR"
fi

conf="${OPENETHEREUM_CONFIG_DIR:-/etc/openethereum}/config.yml"
if [[ -z "${NOLOAD_CONFIG}" && -f "${conf}" ]]; then
  echo "Loading config at ${conf}..."
  run_args="--config=${conf} ${EXTRA_ARGS:-}"
else
  run_args=${EXTRA_ARGS:-""}
fi

exec /usr/bin/tini -g -- $@ ${run_args}
