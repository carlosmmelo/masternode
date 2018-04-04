#!/usr/bin/env bash

# ======================================================================================================================
# CONFIGURATION
# ======================================================================================================================

# ----------  Configuration  ----------

[ -z "${DIR_ROOT}"        ] && declare DIR_ROOT=$( pwd )
[ -z "${PATH_JQ}"         ] && declare PATH_JQ="${DIR_ROOT}/jq"

SYSTEM=`uname`
if [[ $SYSTEM = "Darwin" ]]; then
    declare IS_OSX="true"
fi
[ -z "${IS_OSX}" ] && declare IS_OSX="false"

declare XSNCORE_URL="https://api.github.com/repos/X9Developers/XSN/releases/latest"
declare FILE_CURL_OUT="curl.out"
declare XSNCORE_PATH=${XSNCORE_PATH:-$HOME/.xsncore}


# ======================================================================================================================
# FUNCTIONS
# ======================================================================================================================

function setup_jq () {
    # ----------  Initialization  ----------

    local __PATH_JQ=$1


    # ----------  Download JQ if not present  ----------

    if [ ! -f "${__PATH_JQ}" ]; then
        if [ "${IS_OSX}" == "true" ]; then
            wget https://github.com/stedolan/jq/releases/download/jq-1.5/jq-osx-amd64 > /dev/null 2>&1 || return $( logError "Could not download jq" )
            mv jq-osx-amd64 "${__PATH_JQ}"
        else
            wget https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64 > /dev/null 2>&1 || return $( logError "Could not download jq" )
            mv jq-linux64 "${__PATH_JQ}"
        fi

        chmod u+x "${__PATH_JQ}"
    fi
}

function get_latest_released_tag() {
    curl                                                \
        -X GET                                          \
        "${XSNCORE_URL}"                                \
    > "${FILE_CURL_OUT}"                                \
    2> /dev/null                                        \
    || return `logError "Could not download latest release tag info"`

    __DOWNLOAD_URL=$( "${PATH_JQ}" -r ".assets[0].browser_download_url" "${FILE_CURL_OUT}" )
    echo ${__DOWNLOAD_URL}
}

function stop_xsncore () {
    ps aux | grep xsnd | grep -v grep | awk '{print $2}' | xargs kill
}

function download_last_release_version () {
    __LAST_RELEASE_URL=$(get_latest_released_tag)
    wget ${__LAST_RELEASE_URL}
}

function update_xsn_with_latest_version () {
    __COMPRESSED_NAME=$( "${PATH_JQ}" -r ".assets[0].name" "${FILE_CURL_OUT}" )
    UNCOMPRESSED_NAME=$( echo "${__COMPRESSED_NAME//-linux64.tar.gz}")
    tar xfvz ${__COMPRESSED_NAME}
    cp ${UNCOMPRESSED_NAME}/bin/xsnd ${XSNCORE_PATH}
    cp ${UNCOMPRESSED_NAME}/bin/xsn-cli ${XSNCORE_PATH}
    chmod 777 ${XSNCORE_PATH}/xsn*
}

function start_xsncore () {
    ${XSNCORE_PATH}/xsnd -reindex
}

function clean_up () {
    [ -f "${FILE_CURL_OUT}" ] && rm -rf "${FILE_CURL_OUT}"
    [ -d "${UNCOMPRESSED_NAME}" ] && rm -rf "${UNCOMPRESSED_NAME}"*
}

function update () {

    setup_jq "${PATH_JQ}" || exitError "Could not setup JQ"

    get_latest_released_tag

    stop_xsncore

    download_last_release_version

    update_xsn_with_latest_version

    start_xsncore

    clean_up
}

# The script will terminate after the first line that fails (returns nonzero exit code)
set -e

function usage () {
	echo -e "\nUsage:\n$0 [arguments]\n";
    echo "";
    echo "[update] = Updates and starts your Masternode";
    echo "";
    echo "Example: bash masternode.sh update";
    echo "";
    echo "";
	exit 1
}

if [[ -z $(echo ${1} | grep -e "\(update\)") ]] || [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]] || [[ ${#} -eq 0 ]] || [[ ${#} -gt 1 ]]; then
    usage
fi

case $1 in
	(update)
		cmd=$1 # Command is first arg
		shift
		$cmd $@ # Pass all the rest of args to the command
		;;
	*)
		usage
		;;
esac