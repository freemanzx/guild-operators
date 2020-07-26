#!/bin/bash

# get helper functions from library file
. "$(dirname $0)"/scripts/cnode-helper-scripts/cntools.library

SYNCTOOL_VERSION=0.0.1

STORE_PATH=${REMOVABLE_DRIVE} # Replace with path to removable drive 

RETRIEVE_PATH=${STORE_PATH}/retrieve
RETRIEVE_WALLET_FOLDER=${RETRIEVE_PATH}/wallet
RETRIEVE_POOL_FOLDER=${RETRIEVE_PATH}/pool

SEND_PATH=${STORE_PATH}/send
SEND_WALLET_FOLDER=${SEND_PATH}/wallet
SEND_POOL_FOLDER=${SEND_PATH}/pool

REMOTE_HOME=node2://opt/cardano/cnode
REMOTE_WALLET_FOLDER=${REMOTE_HOME}/priv/wallet
REMOTE_POOL_FOLDER=${REMOTE_HOME}/priv/pool

LOCAL_HOME=/opt/cardano/cnode
LOCAL_WALLET_FOLDER=${LOCAL_HOME}/priv/wallet
LOCAL_POOL_FOLDER=${LOCAL_HOME}/priv/pool

# Create required folders in store if required
if [[ ! -d "${RETRIEVE_PATH}" || ! -d "${SEND_PATH}" ]]; then
  mkdir -v -p "${RETRIEVE_PATH}"
  mkdir -v -p "${SEND_PATH}"
  waitForInput
fi

function main {

while true; do # Main loop

# Display Options
clear
say "$(printf "%-48s %s" " >> Sync Tool $SYNCTOOL_VERSION << " "Synchronize files with on-line node")"
say "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
say " Main Menu"
say ""
say " ) On-Line Retrieve - retrieve on-line files to store"
say " ) On-Line Send - send files to on-line remote node"
say " ) Off-Line Retrieve - retrieve off-line files to store"
say " ) Off-Line Save - save files to off-line location"
say " ) List - list available files"
say " ) Remove - remove files in Retrieve folder"
say " ) Remove - remove files in Send folder"
say " ) PoolMeta - Get PoolMeta from URL"
say "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
say ""
case $(select_opt "[r] On-Line - Retrieve " "[s] On-Line - Send" "[e] Off-Line - Retrieve" "[a] Off-Line - Save" "[l] List" "[r] Remove from Retrieved" "[m] Remove from Send" "[p] PoolMeta" "[q] Quit") in
  0) OPERATION="retrieve" ;;
  1) OPERATION="send" ;;
  2) OPERATION="copy" ;;
  3) OPERATION="save" ;;
  4) OPERATION="list" ;;
  5) OPERATION="remove1" ;;
  6) OPERATION="remove2" ;;
  7) OPERATION="poolmeta" ;;
  8) clear && exit ;;
esac

case $OPERATION in
  retrieve)
  # On-Line Retrieve - retrieve on-line files to store
  clear
  say " >> On-Line Retrieve"
  say "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
  say ""

  scp ${REMOTE_HOME}/db/shelley_trans_epoch ${REMOTE_HOME}/temp/protparams.json ${REMOTE_HOME}/temp/BlockTip.out ${REMOTE_HOME}/temp/SlotTip.out ${REMOTE_HOME}/temp/ledger-state.json ${RETRIEVE_PATH}/
  scp -r ${REMOTE_HOME}/priv/wallet ${RETRIEVE_PATH}/

  say "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
  waitForInput
  ;; ###################################################################

  send)
  # On-Line Send - send files to on-line remote node
  clear
  say " >> On-Line Send"
  say "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
  say ""

  scp -r "${SEND_PATH}"/tx.signed ${REMOTE_HOME}/temp/
  scp -r "${SEND_PATH}"/tx.info ${REMOTE_HOME}/temp/

  while IFS= read -r -d '' wallet; do
    wallet_name=$(basename ${wallet})
    scp -r "${SEND_WALLET_FOLDER}/${wallet_name}" ${REMOTE_WALLET_FOLDER}/
  done < <(find "${SEND_WALLET_FOLDER}" -mindepth 1 -maxdepth 1 -type d -print0 | sort -z)

  while IFS= read -r -d '' pool; do
    pool_name=$(basename ${pool})
    scp -r "${SEND_POOL_FOLDER}/${pool_name}" ${REMOTE_POOL_FOLDER}/
  done < <(find "${SEND_POOL_FOLDER}" -mindepth 1 -maxdepth 1 -type d -print0 | sort -z)

  say "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
  waitForInput && continue
  ;; ###################################################################

  copy)
  # Off-Line Retrieve - retrieve off-line files to store
  clear
  say " >> Off-Line Retrieve"
  say "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
  say ""

  cp -v ${LOCAL_HOME}/temp/tx.signed "${SEND_PATH}"/
  cp -v ${LOCAL_HOME}/temp/tx.info "${SEND_PATH}"/

  while IFS= read -r -d '' wallet; do
    wallet_name=$(basename ${wallet})
    mkdir -p "${SEND_WALLET_FOLDER}/${wallet_name}"
    cp -v "${wallet}/"*.addr "${SEND_WALLET_FOLDER}/${wallet_name}/"
  done < <(find "${LOCAL_WALLET_FOLDER}" -mindepth 1 -maxdepth 1 -type d -print0 | sort -z)

  while IFS= read -r -d '' pool; do
    pool_name=$(basename ${pool})
    mkdir -p "${SEND_POOL_FOLDER}/${pool_name}"
    cp -v "${pool}/"hot.skey "${SEND_POOL_FOLDER}/${pool_name}/"
    cp -v "${pool}/"vrf.skey "${SEND_POOL_FOLDER}/${pool_name}/"
    cp -v "${pool}/"op.cert "${SEND_POOL_FOLDER}/${pool_name}/"
    cp -v "${pool}/"pool.config "${SEND_POOL_FOLDER}/${pool_name}/"
    cp -v "${pool}/"pool.id "${SEND_POOL_FOLDER}/${pool_name}/"
  done < <(find "${LOCAL_POOL_FOLDER}" -mindepth 1 -maxdepth 1 -type d -print0 | sort -z)

  say "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
  waitForInput && continue
  ;; ###################################################################

  save)
  # Off-Line Save - save files to off-line location
  clear
  say " >> Off-Line Save"
  say "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
  say ""
  cp -v ${RETRIEVE_PATH}/shelley_trans_epoch ${LOCAL_HOME}/db/
  cp -v ${RETRIEVE_PATH}/protparams.json ${LOCAL_HOME}/temp/
  cp -v ${RETRIEVE_PATH}/BlockTip.out ${LOCAL_HOME}/temp/
  cp -v ${RETRIEVE_PATH}/SlotTip.out ${LOCAL_HOME}/temp/
  cp -v ${RETRIEVE_PATH}/ledger-state.json ${LOCAL_HOME}/temp/
  cp -v ${RETRIEVE_PATH}/url_poolmeta.json ${LOCAL_HOME}/temp/
  while IFS= read -r -d '' wallet; do
    wallet_name=$(basename ${wallet})
    if [[ -d ${LOCAL_HOME}/priv/wallet/${wallet_name} ]]; then
      cp -v "${wallet}/"*.out "${LOCAL_HOME}/priv/wallet/${wallet_name}/"
    else 
      say "ERROR: Local wallet not found!"
    fi
  done < <(find "${RETRIEVE_WALLET_FOLDER}" -mindepth 1 -maxdepth 1 -type d -print0 | sort -z)
  say "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
  waitForInput && continue
  ;; ###################################################################

  list)
  # List all available retrieved files
  clear
  say " >> List"
  say "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
  ls -Ral ${RETRIEVE_PATH}
  say "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
  ls -Ral ${SEND_PATH}
  say "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
  waitForInput
  ;; ###################################################################

  remove1)
  # Remove all files in retrieved store
  clear
  say " >> Remove from Retrieved"
  say "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
  say ""
  rm -vRf ${RETRIEVE_PATH}/*
  say "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
  waitForInput
  ;; ###################################################################

  remove2)
  # Remove all files in retrieved store
  clear
  say " >> Remove from Send"
  say "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
  say ""
  rm -vRf ${SEND_PATH}/*
  say "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
  waitForInput
  ;; ###################################################################

  poolmeta)
  # Remove all files in retrieved store
  clear
  say " >> Remove from Send"
  say "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
  say ""
    read -r -p "Enter Pool's JSON URL to host metadata file - URL length should be less than 64 chars (default: ${meta_json_url}): " json_url_enter
    [[ -n "${json_url_enter}" ]] && meta_json_url="${json_url_enter}"
    if [[ ! "${meta_json_url}" =~ https?://.* || ${#meta_json_url} -gt 64 ]]; then
      say "${RED}ERROR${NC}: invalid URL format or more than 64 chars in length"
      waitForInput && continue
    fi
    if wget -q -T 10 $meta_json_url -O "$RETRIEVE_PATH/url_poolmeta.json"; then
      say "\nMetadata exists at URL.\n"
    fi
  say "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
  waitForInput
  ;; ###################################################################


esac # main OPERATION
done # main loop
}

##############################################################

main "$@"

