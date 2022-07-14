#!/bin/bash

CURR_DIR=$(cd $(dirname $0); pwd)

# Using metaplex devnet here
SOLANA_NETWORK="https://metaplex.devnet.rpcpool.com/"

solana --version

# Metaplex dev environment setup
# Doc reference: https://docs.metaplex.com/candy-machine-v2/getting-started

echo "Setting up Metaplex dev environment, reference"
echo "https://docs.metaplex.com/candy-machine-v2/getting-started"

# Setting up nvm
nvm_version=$(nvm version 2>/dev/null)
ret=$?
if [ $ret != "0" ] ; then
  echo "nvm not installed, we use nvm to install Node.js and switch between version."
  echo "installing nvm now, Ctrl+C if you don't want to run this. Comment these line out as needed."
  brew install nvm
  mkdir ~/.nvm
  brew cleanup
  export NVM_DIR="$HOME/.nvm"
  [ -s "/usr/local/opt/nvm/nvm.sh" ] && \. "/usr/local/opt/nvm/nvm.sh"
  [ -s "/usr/local/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/usr/local/opt/nvm/etc/bash_completion.d/nvm"
else
  echo "nvm version $nvm_version detected, we will use v16 here."
fi
nvm install 16
nvm use 16
nvm list

# upgrade yarn version to 1.22 if applicable
yarn_version=$(yarn --version 2>/dev/null)
ret=$?
if [ $ret != "0" ] ; then
  echo "installing yarn via brew"
  brew install yarn
else
  echo "detect yarn version $yarn_version"  
fi

# node version >= 16.10
corepack enable

# node version < 16.10
# npm i -g corepack

# Check installed version, node => v16.15.1, yarn => 1.17.3 as of 20220622
node --version
yarn --version

npm install -g ts-node
# 10.7.0
ts-node --version

# intel = x86_64
# M1 = arm64
HW_CPU_SPEC=$(uname -m)
if [ "x${HW_CPU_SPEC}" != "x86_64" ] ; then
  echo "***WARNING***: CPU Intel chip not detected, Apple M1 chip? additional dependencies required! See"
  echo "https://docs.metaplex.com/candy-machine-v2/getting-started#apple-m1-chip"
  echo "You will want to run the following command to support M1 Chip:"
  echo "brew install pkg-config cairo pango libpng jpeg giflib librsvg"
fi

# use master branch
git clone -b master https://github.com/metaplex-foundation/metaplex.git

