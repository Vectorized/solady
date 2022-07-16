#!/usr/bin/env bash

# Read the RPC URL
echo Enter the mainnet RPC URL to fork a local hardhat node from:
echo Example: "https://eth-mainnet.alchemyapi.io/v2/XXXXXXXXXX"
read -s rpc

## Fork Mainnet
echo Please wait 5 seconds for hardhat to fork mainnet and run locally...
echo If this command fails, try running "yarn" to install hardhat dependencies...
make mainnet-fork $rpc &

# Wait for hardhat to fork mainnet
sleep 5

# Read the contract name
echo Which contract do you want to deploy \(eg Greeter\)?
read contract

# Read the constructor arguments
echo Enter constructor arguments separated by spaces \(eg 1 2 3\):
read -ra args

if [ -z "$args" ]
then
  forge create ./src/${contract}.sol:${contract} -i --rpc-url "http://localhost:8545"
else
  forge create ./src/${contract}.sol:${contract} -i --rpc-url "http://localhost:8545" --constructor-args ${args}
fi
