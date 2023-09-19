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
while getopts 'u:a:n:t:up:' option; do
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
    t)
      _PUB_TAG="$OPTARG"
      ;;
    up)
      PUB_UPGRADE=$OPTARG"
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

# Verify if tags were provided and in case create the tag list in the correct form for the json API call
if [ ! -z "$_PUB_TAG" ]
then
  IFS=, read -a arr <<<"${_PUB_TAG}"
  printf -v tags ',{"tag_name": "%s"}' "${arr[@]}"
  PUB_TAG="${tags:1}"
  TAGS=',"tags": [ '${PUB_TAG}' ]'
fi

# Verify if the upgrade flag was provided and if not assign it the default upgrade profile "1"
if [ -z "$PUB_UPGRADE" ]
then
  PUB_UPGRADE=1
fi

echo "Trying to create the Publisher object in the tenant..."
echo ""
## Perform the API call to create a Publisher object using the provided parameters
PUB_CREATE=$(curl -s -X 'POST' "https://${TENANT_URL}/api/v2/infrastructure/publishers?silent=0" -H 'accept: application/json' -H "Netskope-Api-Token: ${API_TOKEN}" -H 'Content-Type: application/json' -d '{"name": "'"${PUB_NAME}"'","lbrokerconnect": false'"${TAGS}"',"publisher_upgrade_profiles_id": '${PUB_UPGRADE}'}' | jq)

# Verify that the Publisher creation succeeded
STATUS=$(echo ${PUB_CREATE} | jq -r '.status')

if [ "$STATUS" != "success" ] ; then
  echo "Failed to create the Publisher object in the tenant !"
  echo "API response: "${PUB_CREATE}
  exit 1
fi

echo "Publisher "${PUB_NAME}" created successfully
echo ""

echo "Trying to retrieve the Publisher Token...:
echo ""
## Grab the Publisher ID from the API response and initiate a Publisher Token retrieval
PUB_ID=$(echo ${PUB_CREATE} | jq '.data.id')
PUB_TOKEN=$(curl -s -X 'POST' "https://${TENANT_URL}/api/v2/infrastructure/publishers/${PUB_ID}/registration_token" -H 'accept: application/json' -H "Netskope-Api-Token: ${API_TOKEN}" -d '')

## Verify that the Publisher Token has been successfully retrieved, if not, abort
STATUS=$(echo ${PUB_TOKEN} | jq -r '.status')

if [ "$STATUS" != "success" ] ; then
  echo "Failed to retrieve the Publisher Token !"
  echo "API Response: "${PUB_TOKEN}
  exit 1
fi

echo "Publisher token correctly retireved. Registering the ublisher now..."

## Grab the Publisher Token from the API response and initiate Publisher registration
PUB_TOKEN=$(echo ${PUB_TOKEN} | jq '.data.token')
sudo ./npa_publisher_wizard -token ${PUB_TOKEN}
