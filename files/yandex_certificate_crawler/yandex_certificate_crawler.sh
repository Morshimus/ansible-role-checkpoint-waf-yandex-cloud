#!/bin/bash -e

function yandex_certificate_crawler() {

  if { [ -z "${IAM_LINK}" ]; } && [ -z "${IAM_TOKEN}" ]; then
    echo "Enter iam link:" && read -r IAM_LINK
  fi

  if [ -z "${CERTIFICATE_ID}" ]; then
    echo "Enter certificate id:" && read -r CERTIFICATE_ID
  fi

  if [ -z "${IAM_TOKEN}" ]; then
    IAM_TOKEN=$(/bin/curl -s "${IAM_LINK}" -H "Metadata-Flavor: Google")
    IAM_TOKEN=$(jq -r .access_token <<<"${IAM_TOKEN}")
    export IAM_TOKEN
  fi

  certificate_list=$(
    curl -H "Authorization: Bearer ${IAM_TOKEN}" \
      -XGET "https://data.certificate-manager.api.cloud.yandex.net/certificate-manager/v1/certificates/${CERTIFICATE_ID}:getContent" |
      jq .certificateChain[]
  )
  export certificate_list
  formatted_certificates_pem=$(echo -e "${certificate_list}" | sed -e 's/\"//' | sed -e 's/\"//' | sed -e 's/^\s//' | sed '/^$/d')
  export formatted_certificates_pem
  private_key=$(
    curl -H "Authorization: Bearer ${IAM_TOKEN}" \
      -XGET "https://data.certificate-manager.api.cloud.yandex.net/certificate-manager/v1/certificates/${CERTIFICATE_ID}:getContent" |
      jq .privateKey
  )
  formatted_private_key_pem=$(echo -e "${private_key}" | sed -e 's/^\"//' | sed -e 's/\"$//' | sed '/^$/d')
  export formatted_private_key_pem
  name=$(
    curl -H "Authorization: Bearer ${IAM_TOKEN}" \
      -XGET "https://certificate-manager.api.cloud.yandex.net/certificate-manager/v1/certificates/${CERTIFICATE_ID}" |
      jq .name
  )
  formatted_name=$(echo "${name}" | sed -e 's/^\"//' | sed -e 's/\"$//')
  export formatted_name
}
