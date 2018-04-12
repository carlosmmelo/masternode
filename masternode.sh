#!/usr/bin/env bash

# The script will terminate after the first line that fails (returns nonzero exit code)
set -e

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

declare -r DATE_STAMP="$(date +%y-%m-%d-%s)"
declare -r SCRIPT_LOGFILE="/tmp/nodemaster_${DATE_STAMP}_out.log"


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
    ps aux | grep xsnd | grep -v grep | awk '{print $2}' | xargs kill -9
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

function start () {
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

    start

    clean_up
}

function stop_sentinel () {
    if pgrep sentinel &> /dev/null ; then sudo killall sentinel ; fi
}

#
# /* no parameters, creates a sentinel config for a set of masternodes (one per masternode)  */
#
function create_sentinel_setup () {
	# if code directory does not exists, proceed to clone sentinel repo
	if [ ! -d ${XSNCORE_PATH}/sentinel ]; then
		cd ${XSNCORE_PATH}                                          &>> ${SCRIPT_LOGFILE}
		git clone https://github.com/carlosmmelo/sentinel sentinel  &>> ${SCRIPT_LOGFILE}
		cd sentinel                                                 &>> ${SCRIPT_LOGFILE}
		rm -f rm sentinel.conf                                      &>> ${SCRIPT_LOGFILE}
	else
		echo "* Updating the existing sentinel GIT repo"
		cd ${XSNCORE_PATH}/sentinel   &>> ${SCRIPT_LOGFILE}
		git pull                      &>> ${SCRIPT_LOGFILE}
		rm -f rm sentinel.conf        &>> ${SCRIPT_LOGFILE}
	fi
	# create a python virtual environment and install sentinel requirements
	virtualenv --system-site-packages ${XSNCORE_PATH}/sentinelvenv      &>> ${SCRIPT_LOGFILE}
	${XSNCORE_PATH}/sentinelvenv/bin/pip install -r requirements.txt    &>> ${SCRIPT_LOGFILE}
    # setup sentinel config file
    if [ ! -f "${XSNCORE_PATH}/sentinel/xsn_sentinel.conf" ]; then
         echo "* Creating sentinel configuration for XSN Masternode"    &>> ${SCRIPT_LOGFILE}
         echo "xsn_conf=${XSNCORE_PATH}/xsn.conf"                       > ${XSNCORE_PATH}/sentinel/xsn_sentinel.conf
         echo "network=mainnet"                                         >> ${XSNCORE_PATH}/sentinel/xsn_sentinel.conf
         echo "db_name=database/xsn_sentinel.db"                        >> ${XSNCORE_PATH}/sentinel/xsn_sentinel.conf
         echo "db_driver=sqlite"                                        >> ${XSNCORE_PATH}/sentinel/xsn_sentinel.conf
    fi
}

function start_sentinel () {
    export SENTINEL_CONFIG=${XSNCORE_PATH}/sentinel/xsn_sentinel.conf; ${XSNCORE_PATH}/sentinelvenv/bin/python ${XSNCORE_PATH}/sentinel/bin/sentinel.py &
}

function set_sentinel_cron () {
    (crontab -l 2>/dev/null; echo "* * * * * export SENTINEL_CONFIG=${XSNCORE_PATH}/sentinel/xsn_sentinel.conf; cd ${XSNCORE_PATH}/sentinel && ${XSNCORE_PATH}/sentinelvenv/bin/python ${XSNCORE_PATH}/sentinel/bin/sentinel.py >/dev/null 2>&1") | sort - | uniq - | crontab -
}

function execute_sentinel () {

    stop_sentinel

    create_sentinel_setup

    #start_sentinel

    set_sentinel_cron
}

function usage () {
	echo -e "\nUsage:\n$0 [arguments]\n";
    echo "";
    echo "[update] = Updates and Starts your Masternode";
    echo "[start] = Start XSN Daemon only";
    echo "[execute_sentinel] = Create and Start Sentinel";
    echo "";
    echo "Example: bash masternode.sh update";
    echo "";
    echo "";
	exit 1
}

case $1 in
	update|start|execute_sentinel)
		cmd=$1 # Command is first arg
		shift
		$cmd $@ # Pass all the rest of args to the command
		;;
	*)
		usage
		;;
esac