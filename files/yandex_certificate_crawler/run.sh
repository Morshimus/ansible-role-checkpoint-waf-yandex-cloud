#!/bin/bash -e

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)

# shellcheck source=/dev/null
source "${SCRIPT_DIR}/yandex_certificate_crawler.sh"

declare -a CERTIFICATE_IDS
TARGET_FOLDER=${NULL:-}
IAM_TOKEN=${NULL:-}
IAM_LINK=${NULL:-"http://169.254.169.254/computeMetadata/v1/instance/service-accounts/default/token"}

while getopts 'a:c:i:t:h' flag; do
  case "${flag}" in
  c)
    CERTIFICATE_IDS+=("${OPTARG}")
    ;;
  t)
    TARGET_FOLDER=${OPTARG}
    ;;
  i)
    IAM_LINK=${OPTARG}
    ;;
  a)
    IAM_TOKEN=${OPTARG}
    ;;
  \? | h)
    echo "Usage: [-c ] [-t] [-i] [-a]:
          -c is certificates ids;
          -t is target folder where crtificated required to be updated.
          -i is iam link, if it's not required omit it.
          -a is iam token, if not required omit it."
    exit 1
    ;;
  esac
done
shift $((OPTIND - 1))

export IAM_TOKEN

if [[ "${#CERTIFICATE_IDS[@]}" -eq 0 ]]; then
  echo "You must mentioned at least 1 certificate id."
  exit 1
fi

if [ -z "${TARGET_FOLDER}" ]; then
  echo "You must setup target folder were certificate update is required."
  exit 1
fi

if [ -z "${IAM_LINK}" ]; then
  echo "You must defined iam link or not mentioned that parameter. Default is http://169.254.169.254/computeMetadata/v1/instance/service-accounts/default/token."
  exit 1
fi

declare -i INIT_RUN
INIT_RUN=0
export INIT_RUN

declare -i REBOOT_CONTAINER
REBOOT_CONTAINER=0
export REBOOT_CONTAINER

if [ ! -f "./yc_crawler_initialized" ]; then
  INIT_RUN=1
  export INIT_RUN
fi

for i in "${!CERTIFICATE_IDS[@]}"; do
  CERTIFICATE_ID="${CERTIFICATE_IDS[$i]}"
  export CERTIFICATE_ID
  formatted_certificates_pem="${NULL:-}"
  formatted_private_key_pem="${NULL:-}"
  formatted_name="${NULL:-}"
  yandex_certificate_crawler
  echo "${formatted_certificates_pem}" >"/tmp/${formatted_name}-crt.pem"
  echo "${formatted_private_key_pem}" >"/tmp/${formatted_name}-key.pem"
  if [ -n "${formatted_name}" ]; then
    if { [ -f "${TARGET_FOLDER}/${formatted_name}-key.pem" ]; } && [ -f "${TARGET_FOLDER}/${formatted_name}-crt.pem" ]; then
      if cmp -s "/tmp/${formatted_name}-crt.pem" "${TARGET_FOLDER}/${formatted_name}-crt.pem"; then
        echo "Old and new certificates are same. No copy required."
      else
        cp "/tmp/${formatted_name}-crt.pem" "${TARGET_FOLDER}/${formatted_name}-crt.pem" -f
        echo "Certificates were different, old certificate were replaced."
        if [ "${INIT_RUN}" -eq 0 ]; then
          REBOOT_CONTAINER=1
          export REBOOT_CONTAINER
        fi
      fi
      if cmp -s "/tmp/${formatted_name}-key.pem" "${TARGET_FOLDER}/${formatted_name}-key.pem"; then
        echo "Old and new key are same. No copy required."
      else
        cp "/tmp/${formatted_name}-key.pem" "${TARGET_FOLDER}/${formatted_name}-key.pem" -f
        echo "Key were different, old key were replaced."
        if [ "${INIT_RUN}" -eq 0 ]; then
          REBOOT_CONTAINER=1
          export REBOOT_CONTAINER
        fi
      fi
    else
      cp "/tmp/${formatted_name}-crt.pem" "${TARGET_FOLDER}/${formatted_name}-crt.pem" -f
      cp "/tmp/${formatted_name}-key.pem" "${TARGET_FOLDER}/${formatted_name}-key.pem" -f
    fi
  fi
done

if [ "${REBOOT_CONTAINER}" -eq 1 ]; then
  ~/bin/docker restart cp_waf_agent
fi

if [ ! -f "./yc_crawler_initialized" ]; then
  touch "./yc_crawler_initialized"
fi
