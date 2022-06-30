#!/bin/bash

CURR_DIR=$(cd $(dirname $0); pwd)

solana --version
solana-keygen new --no-bip39-passphrase --outfile $CURR_DIR/mynft-keypair.json
solana-keygen new --no-bip39-passphrase --outfile $CURR_DIR/mynft-treasury.json
solana-keygen new --no-bip39-passphrase --outfile $CURR_DIR/devnet-keypair.json

deploy_wallet=$(solana-keygen pubkey $CURR_DIR/devnet-keypair.json)
treasury_wallet=$(solana-keygen pubkey $CURR_DIR/mynft-treasury.json)

solana config set --keypair $CURR_DIR/devnet-keypair.json

solana config set --url https://metaplex.devnet.rpcpool.com/
solana config get

echo "Airdrop 2 SOL to $deploy_wallet"
solana airdrop 2 $deploy_wallet

rm -rf "$CURR_DIR/uploaded_assets"
cp -rp "$CURR_DIR/assets_examples" "$CURR_DIR/uploaded_assets"
pushd "$CURR_DIR/uploaded_assets"
for f in $(find . -type f -name "*.json")
do
  sed -i $(basename $f).bak "s/REPLACEME_WITH_WALLET/$deploy_wallet/g" $f
done
rm -f *.bak
popd

echo "Current solana wallet is configured to $(solana address)"
echo "Current NFT treasury wallet is configured to $treasury_wallet"

if [ ! -d metaplex ] ; then
  echo "ERROR: metaplex directory should exist after running setup.sh within the same directory! exiting!"
  exit -1
fi

rm -rf metaplex/js/.cache
mkdir -p metaplex/assets
rm -f metaplex/assets/*
cp -rp uploaded_assets/* metaplex/assets/
rm -f metaplex/js/packages/candy-machine-ui/.env.example
cat example-candy-machine-upload-config.json | sed "s/REPLACEME_GOLIVE_DATE/$TIMENOW/g" | sed "s/REPLACEME_TREASURY_WALLET/$treasury_wallet/g" > metaplex/js/packages/cli/example-candy-machine-upload-config.json
TIMENOW=$(date +"%d %B %Y %H:%M:%S GMT")
pushd metaplex/js
yarn install
ts-node $CURR_DIR/metaplex/js/packages/cli/src/candy-machine-v2-cli.ts \
  upload \
  -e devnet \
  -k $CURR_DIR/devnet-keypair.json \
  -cp $CURR_DIR/metaplex/js/packages/cli/example-candy-machine-upload-config.json \
  $CURR_DIR/metaplex/assets | tee $CURR_DIR/metaplex.log

echo "Verifying upload"
ts-node $CURR_DIR/metaplex/js/packages/cli/src/candy-machine-v2-cli.ts \
  verify_upload \
  -e devnet \
  -k $CURR_DIR/devnet-keypair.json \
  $CURR_DIR/metaplex/assets 
popd

# Apply Candy Machine here to apply to UI
CANDY_MACHINE=$(grep "Candy machine address" $CURR_DIR/metaplex.log | cut -d: -f2- | tr -d ' ')
cat js-packages-cli-candy-machine-ui.env | sed "s/REPLACEME_CANDY_MACHINE/$CANDY_MACHINE/g" > metaplex/js/packages/candy-machine-ui/.env

echo "Candy Machine account is $CANDY_MACHINE"
echo "Starting local UI localhost:3000 for you to mint, you can use Firefox/Chrome Phantom extension and mint"
echo "Use 'solana airdrop 2 YOUR_WALLET' to airdrop 2 solana to your Phantom wallet to mint"

echo "To start a local mint server and UI, run the following. It will reset your screen, so review logs if necessary before running it."
echo ""
echo "#########################################"
echo "cd metaplex/js/packages/candy-machine-ui"
echo "yarn install && yarn start"
echo "#########################################"

exit 0
