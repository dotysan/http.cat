#! /usr/bin/env bash

# to run this script you must provide an .env file containing the following
# variables:
#
# DEPLOY_USER=<the username on the remote server> ex. johndoe
# DEPLOY_HOST=<the host of the remote server> ex. example.com
# DEPLOY_DIR=<the deployment directory on the remote machine> ex. /var/www/
#
# CLOUDFLARE_ZONE_ID=<the zone id of your cloudflare domain> ex. 1234567890abcdef1234567890abcdef
# CLOUDFLARE_API_TOKEN=<a cloudflare api token with permissions to purge cache> ex. 1234567890abcdef1234567890abcdef

set -o nounset
set -o errexit
set -o xtrace

SOURCE_DIR=out/
DIR=$(dirname "$0")

main() {
  chk_env
  echo "📝 Source: ${DIR}/${SOURCE_DIR}"
  echo "🎯 Target: ${DEPLOY_USER}@${DEPLOY_HOST}:${DEPLOY_DIR}"
  deploy
  purge
}

chk_env() {
  # shellcheck disable=SC1091
  [[ ! -s "$DIR/.env" ]] ||source "$DIR/.env"

  if [[ -z "${DEPLOY_USER:-}" ||
        -z "${DEPLOY_HOST:-}" ||
        -z "${DEPLOY_DIR:-}" ||
        -z "${CLOUDFLARE_ZONE_ID:-}" ||
        -z "${CLOUDFLARE_API_TOKEN:-}" ]]
  then
    echo "❌ Missing required environment variables. Please check your .env or .envrc files."
    return 1
  fi >&2
}

deploy() {
  if rsync -rvzp --delete ${SOURCE_DIR} "${DEPLOY_USER}@${DEPLOY_HOST}:${DEPLOY_DIR}"
  then
    echo "✅ Deploy successful!"
  else
    echo "❌ Deployment error. Check the output!"
    return 1
  fi >&2
}

purge() {
  echo "🚀 Purging Cloudflare cache"
  curl --request POST \
    "https://api.cloudflare.com/client/v4/zones/${CLOUDFLARE_ZONE_ID}/purge_cache" \
    --header "Authorization: Bearer ${CLOUDFLARE_API_TOKEN}" \
    --header "Content-Type: application/json" \
    --data '{"purge_everything":true}'
  echo "✅ Cloudflare cache purged!"
}

main "$@"
exit $?
