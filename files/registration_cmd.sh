#!/bin/bash -e

TOKEN_PATH_RAW=$(cat "${CP_WAF_AGENT_TOKEN}")
export TOKEN_PATH="${TOKEN_PATH_RAW}"

/cloudguard-appsec-standalone --token ${TOKEN_PATH} --nginx-self-managed
