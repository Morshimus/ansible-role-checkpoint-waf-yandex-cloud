#!/bin/bash -e

TOKEN_PATH_RAW=$(cat "${CP_WAF_AGENT_TOKEN}")
export TOKEN_PATH="${TOKEN_PATH_RAW}"

if [ "${CP_WAF_AGENT_TYPE}" == "cloudguard-waf" ]; then
  EXEC_PATH="/cloudguard-appsec-standalone"
  MODE_FLAG="--nginx-self-managed"
else
  EXEC_PATH="/cp-nano-agent-unified"
  MODE_FLAG="--standalone"
fi
export EXEC_PATH

"${EXEC_PATH}" --token "${TOKEN_PATH}" "${MODE_FLAG}"
