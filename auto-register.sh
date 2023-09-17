#!/bin/bash

## Check if jq is installed, if not, install it
REQUIRED_PKG="jq"

PKG_OK=$(dpkg-query -W --showformat='${Status}\n' $REQUIRED_PKG|grep "install ok installed")

echo Checking for $REQUIRED_PKG: $PKG_OK

if [ "" = "$PKG_OK" ]; then
  echo "No $REQUIRED_PKG. Setting up $REQUIRED_PKG."
  sudo apt-get --yes install $REQUIRED_PKG
fi

## Check if curl is installed, if not, install it
REQUIRED_PKG="curl"

PKG_OK=$(dpkg-query -W --showformat='${Status}\n' $REQUIRED_PKG|grep "install ok installed")

echo Checking for $REQUIRED_PKG: $PKG_OK

if [ "" = "$PKG_OK" ]; then
  echo "No $REQUIRED_PKG. Setting up $REQUIRED_PKG."
  sudo apt-get --yes install $REQUIRED_PKG
fi

## Set the parameters flags of the script
while getopts 'u:a:n:' option; do
  case $option in
    u)
      TENANT_URL="$OPTARG"
      ;;
    a)
      API_TOKEN="$OPTARG"
      ;;
    n)
      PUB_NAME="$OPTARG"
      ;;
    ?)
      echo "Usage: $0 [-u tenant_url] [-a API_token] [-n Publisher_name] [-t Publisher_tag]" >&2
      exit 1
      ;;
  esac
done

# Verify if all the parameters have been provided, if not, abort
shift "$(( OPTIND - 1 ))"
if [ -z "$TENANT_URL" ] || [ -z "$API_TOKEN" ] || [ -z "$PUB_NAME" ] ; then
  echo 'Missing parameters -u or -a or -n' >&2
  exit 1
fi

## Perform the API call to create a Publisher object using the provided parameters
PUB_CREATE=$(curl -X 'POST' "https://${TENANT_URL}/api/v2/infrastructure/publishers?silent=0" -H 'accept: application/json' -H "Netskope-Api-Token: ${API_TOKEN}" -H 'Content-Type: application/json' -d '{"name": "'"${PUB_NAME}"'","lbrokerconnect": false,"publisher_upgrade_profiles_id": 1}' | jq)

# Verify that the Publisher creation succeeded
STATUS=$(echo ${PUB_CREATE} | jq -r '.status')

if [ "$STATUS" == "error" ] ; then
  echo ${PUB_CREATE}
  exit 1
fi

## Grab the Publisher ID from the API response and initiate a Publisher Token retrieval
PUB_ID=$(echo ${PUB_CREATE} | jq '.data.id')
PUB_TOKEN=$(curl -X 'POST' "https://${TENANT_URL}/api/v2/infrastructure/publishers/${PUB_ID}/registration_token" -H 'accept: application/json' -H "Netskope-Api-Token: ${API_TOKEN}" -d '')

## Verify that the Publisher Token has been successfully retrieved, if not, abort
STATUS=$(echo ${PUB_CREATE} | jq -r '.status')

if [ "$STATUS" == "error" ] ; then
	  exit 1
fi

## Grab the Publisher Token from the API response and initiate Publisher registration
PUB_TOKEN=$(echo ${PUB_TOKEN} | jq '.data.token')
echo ${PUB_TOKEN}

sudo ./npa_publisher_wizard -token ${PUB_TOKEN}
