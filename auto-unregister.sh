#!/bin/bash

# Check if the publisherid file exists under resources and if yes extract the Publisher common_name
if [ -f "./resources/publisherid" ]; then
  PUB_CN=$(</home/ubuntu/resources/publisherid)
else
  echo "The file /home/ubuntu/resources/publisherid does not exist. Please check the path and if the Publisher is registered"
  exit 1
fi

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
echo "Gathering Publisher info via API and initiate the removal of the Publisher from the tenant..."
echo ""

# Invoke the API to retrieve the list of publishers
PUB_LIST=$(curl -s -X 'GET' "https://${TENANT_URL}/api/v2/infrastructure/publishers" -H 'accept: application/json' -H "Netskope-Api-Token: ${API_TOKEN}")

# Extracts the Publisher ID from the list of Publishers
PUB_ID=$(echo ${PUB_LIST} | jq .data.publishers | jq 'map({ common_name: .common_name, publisher_id: .publisher_id}) | map(select(.common_name == "'"${PUB_CN}"'"))' | jq .[].publisher_id)

# Invoke the API to delete the Publisher
PUB_DELETE=$(curl -s -X 'DELETE' "https://${TENANT_URL}/api/v2/infrastructure/publishers/${PUB_ID}" -H 'accept: application/json' -H "Netskope-Api-Token: ${API_TOKEN}")

# Verify that the Publisher deletion succeeded
STATUS=$(echo ${PUB_DELETE} | jq -r '.status')

if [ "$STATUS" != "success" ] ; then
echo "The Publisher cannot be deleted from the tenant"
echo "API response: "${PUB_DELETE}
exit 1
fi

PUB_NAME=$(echo ${PUB_LIST} | jq .data.publishers | jq 'map({ common_name: .common_name, publisher_name: .publisher_name}) | map(select(.common_name == "'"${PUB_CN}"'"))' | jq .[].publisher_name)
echo "Publisher "${PUB_NAME}" correctly removed from the tenant"
echo ""

# Remove activation files on the Publisher and restart the docker
echo "Removing publisher configuration files on the machine and restart docker container.."
echo ""
rm -rf /home/ubuntu/resources/
docker restart -t 0 $(docker ps -a -q)
echo ""
echo "Publisher data removed. The Publisher is no longer registered"
