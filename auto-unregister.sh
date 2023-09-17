#!/bin/bash
  
PUB_INFO=$(<publisherinfo)

PUB_ID=$(echo ${PUB_INFO} | jq -r '.data.id')

## Set the parameters flags of the script
while getopts 'u:a:' option; do
case $option in
    u)
TENANT_URL="$OPTARG"
;;
    a)
API_TOKEN="$OPTARG"
;;
    ?)
echo "Usage: $0 [-u tenant_url] [-a API_token] [-n Publisher_name] [-t Publisher_tag]" >&2
exit 1
;;
  esac
done

# Verify if all the parameters have been provided, if not, abort
shift "$(( OPTIND - 1 ))"

if [ -z "$TENANT_URL" ] || [ -z "$API_TOKEN" ] ; then
  echo 'Missing parameters -u or -a' >&2
  exit 1
fi

# Invoke the API to delete the Publisher
PUB_DELETE=$(curl -s -X 'DELETE' "https://${TENANT_URL}/api/v2/infrastructure/publishers/207" -H 'accept: application/json' -H "Netskope-Api-Token: ${API_TOKEN}")

# Verify that the Publisher deletion succeeded
STATUS=$(echo ${PUB_DELETE} | jq -r '.status')

if [ "$STATUS" != "success" ] ; then
echo ${PUB_DELETE}
exit 1
fi

# Remove activation files on the Publisher and restart the docker
rm -rf resources/
docker restart -t 0 $(docker ps -a -q)
