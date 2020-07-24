#!/bin/bash

get_input() {
  printf "%s (default: %s): " "$1" "$2" >&2; read -r answer
  if [ -z "$answer" ]; then echo "$2"; else echo "$answer"; fi
}

err_exit() {
  printf "%s\nExiting..." "$*" >&2
  exit 1
}

usage() {
  cat <<EOF >&2
Usage: $(basename "$0") [-i]
Install pre-requisites for 'cardano-node'

-i                  Interactive mode
EOF
  exit 1
}

while getopts "i" opt
do
  case "$opt" in
    i)
      INTERACTIVE='Y'
      ;;
    *)
      usage
      ;;
    esac
done

# For who runs the script within containers and running it as root.
U_ID=$(id -u)
G_ID=$(id -g)

# Defaults
CNODE_PATH="/opt/cardano"
CNODE_NAME="cnode"
CNODE_HOME=${CNODE_PATH}/${CNODE_NAME}
CNODE_VNAME=$(echo "$CNODE_NAME" | awk '{print toupper($0)}')

WANT_BUILD_DEPS='Y'

#if [ $(id -u$( -eq 0 ]; then
#  err_exit "Please run as non-root user."
#fi

SUDO="Y";
if [ "${SUDO}" = "Y" ] || [ "${SUDO}" = "y" ] ; then sudo="sudo"; else sudo="" ; fi

if [ "$INTERACTIVE" = 'Y' ]; then
  clear;
  CNODE_PATH=$(get_input "Please enter the project path" ${CNODE_PATH})
  CNODE_NAME=$(get_input "Please enter directory name" ${CNODE_NAME})
  CNODE_HOME=${CNODE_PATH}/${CNODE_NAME}
  CNODE_VNAME=$(echo "$CNODE_NAME" | awk '{print toupper($0)}')

  if [ -d "${CNODE_HOME}" ]; then
    err_exit "The \"${CNODE_HOME}\" directory exist, pls remove or choose an other one."
  fi

fi

echo "Creating Folder Structure .."

if grep -q "${CNODE_VNAME}_HOME" ~/.bashrc; then
  echo "Environment Variable already set up!"
else
  echo "Setting up Environment Variable"
  echo "export ${CNODE_VNAME}_HOME=${CNODE_HOME}" >> ~/.bashrc
  # shellcheck source=/dev/null
  . "${HOME}/.bashrc"
fi

$sudo mkdir -p "$CNODE_HOME"/files "$CNODE_HOME"/db "$CNODE_HOME"/logs "$CNODE_HOME"/scripts "$CNODE_HOME"/sockets "$CNODE_HOME"/priv
$sudo chown -R "$U_ID":"$G_ID" "$CNODE_HOME"
chmod -R 755 "$CNODE_HOME"

cd "$CNODE_HOME/files" || return

curl -s -o ptn0-praos.json https://raw.githubusercontent.com/freemanzx/guild-operators/offline-ops/files/ptn0/files/ptn0-praos.json
curl -s -o ptn0-combinator.json https://raw.githubusercontent.com/freemanzx/guild-operators/offline-ops/files/ptn0/files/ptn0-combinator.json
if [[ "$2" = "g" ]]; then
  # guild-operators network
  curl -s -o genesis.json https://raw.githubusercontent.com/freemanzx/guild-operators/offline-ops/files/ptn0/files/genesis.json
  curl -s -o byron-genesis.json https://raw.githubusercontent.com/freemanzx/guild-operators/offline-ops/files/ptn0/files/byron-genesis.json
  curl -s -o topology.json https://raw.githubusercontent.com/freemanzx/guild-operators/offline-ops/files/ptn0/files/topology.json
else
  # mainnet_candidate network
  curl -s -o byron-genesis.json https://hydra.iohk.io/build/3554884/download/1/mainnet_candidate-byron-genesis.json
  curl -s -o genesis.json https://hydra.iohk.io/build/3554884/download/1/mainnet_candidate-shelley-genesis.json
  curl -s -o topology.json https://hydra.iohk.io/build/3554884/download/1/mainnet_candidate-topology.json
fi

if [[ "$1" = "p" ]]; then
  cp ptn0-praos.json ptn0.json
else
  cp ptn0-combinator.json ptn0.json
fi

# If using a different CNODE_HOME than in this example, execute the below:
# sed -i -e "s#/opt/cardano/cnode#${CNODE_HOME}#" $CNODE_HOME/files/ptn*.json
## For future use:
## It generates random NodeID:
## -e "s#NodeId:.*#NodeId:$(od -A n -t u8 -N 8 /dev/urandom$(#" \

cd "$CNODE_HOME"/scripts || return
curl -s -o env https://raw.githubusercontent.com/freemanzx/guild-operators/offline-ops/scripts/cnode-helper-scripts/env
sed -e "s@CNODE_HOME@${CNODE_VNAME}_HOME@g" -i env
curl -s -o createAddr.sh https://raw.githubusercontent.com/freemanzx/guild-operators/offline-ops/scripts/cnode-helper-scripts/createAddr.sh
curl -s -o sendADA.sh https://raw.githubusercontent.com/freemanzx/guild-operators/offline-ops/scripts/cnode-helper-scripts/sendADA.sh
curl -s -o balance.sh https://raw.githubusercontent.com/freemanzx/guild-operators/offline-ops/scripts/cnode-helper-scripts/balance.sh
curl -s -o cnode.sh https://raw.githubusercontent.com/freemanzx/guild-operators/offline-ops/files/ptn0/scripts/cnode.sh.templ
curl -s -o cntools.sh https://raw.githubusercontent.com/freemanzx/guild-operators/offline-ops/scripts/cnode-helper-scripts/cntools.sh
curl -s -o cntools.config https://raw.githubusercontent.com/freemanzx/guild-operators/offline-ops/scripts/cnode-helper-scripts/cntools.config
curl -s -o cntools.library https://raw.githubusercontent.com/freemanzx/guild-operators/offline-ops/scripts/cnode-helper-scripts/cntools.library
curl -s -o cntoolsBlockCollector.sh https://raw.githubusercontent.com/freemanzx/guild-operators/offline-ops/scripts/cnode-helper-scripts/cntoolsBlockCollector.sh
curl -s -o cntoolsUpdater.sh https://raw.githubusercontent.com/freemanzx/guild-operators/offline-ops/scripts/cnode-helper-scripts/cntoolsUpdater.sh
curl -s -o setup_mon.sh https://raw.githubusercontent.com/freemanzx/guild-operators/offline-ops/scripts/cnode-helper-scripts/setup_mon.sh
curl -s -o topologyUpdater.sh https://raw.githubusercontent.com/freemanzx/guild-operators/offline-ops/scripts/cnode-helper-scripts/topologyUpdater.sh
sed -e "s@CNODE_HOME=.*@${CNODE_VNAME}_HOME=${CNODE_HOME}@g" -e "s@CNODE_HOME@${CNODE_VNAME}_HOME@g" -i cnode.sh
curl -s -o cabal-build-all.sh https://raw.githubusercontent.com/freemanzx/guild-operators/offline-ops/files/ptn0/scripts/cabal-build-all.sh
curl -s -o stack-build.sh https://raw.githubusercontent.com/freemanzx/guild-operators/offline-ops/files/ptn0/scripts/stack-build.sh
curl -s -o system-info.sh https://raw.githubusercontent.com/freemanzx/guild-operators/offline-ops/files/ptn0/scripts/system-info.sh
curl -s -o "$CNODE_HOME"/priv/delegate.counter https://raw.githubusercontent.com/freemanzx/guild-operators/offline-ops/files/ptn0/files/delegate.counter
chmod 755 ./*.sh
# If you opt for an alternate CNODE_HOME, please run the below:
# sed -i -e "s#/opt/cardano/cnode#${CNODE_HOME}#" *.sh
cd - || return
