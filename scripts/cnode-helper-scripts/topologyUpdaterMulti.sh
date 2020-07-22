#!/bin/bash

USERNAME="${USERNAME}" # replace nonroot with your username

CNODE_BIN="/home/${USERNAME}/.cabal/bin"
CNODE_HOME="/opt/cardano/cnode"
CNODE_LOG_DIR="${CNODE_HOME}/logs/"

TESTNET_MAGIC=42

export DISPLAY=":0"
export PATH="${CNODE_BIN}:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
export SHELL="/bin/bash"
export CARDANO_NODE_SOCKET_PATH="${CNODE_HOME}/sockets/node1.socket"

blockNo=$(cardano-cli shelley query tip --testnet-magic $TESTNET_MAGIC | jq '.blockNo')

submit_node {

        CNODE_PORT=$1  # must match your relay node port as set in the startup command
        CNODE_HOSTNAME=$2  # optional. must resolve to the IP you are requesting from
        CNODE_VALENCY=$3   # optional for multi-IP hostnames

        curl -s "https://api.clio.one/htopology/v1/?port=${CNODE_PORT}&blockNo=${blockNo}&hostname=${CNODE_HOSTNAME}&valency=${CNODE_VALENCY}" | tee -a ${CNODE_LOG_DIR}/${CNODE_HOSTNAME}_topologyUpdater_lastresult.json
}

submit_node 3001 "relay1.adaocean.com" 1;
submit_node 3002 "relay2.adaocean.com" 1;
