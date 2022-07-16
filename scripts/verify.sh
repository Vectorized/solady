#!/usr/bin/env bash

# TODO: Remove this prompt and parse dynamically
echo Which compiler version did you use to build?

read version

echo $version

echo Which contract do you want to verify?

read contract

echo $contract

echo What is the deployed address?

read deployed

echo $deployed

echo Enter constructor arguments separated by spaces \(eg 1 2 3\):

read -ra args

echo $args

echo Enter your Etherscan API Key:

read -s etherscan

if [ -z "$args" ]
then
  forge verify-contract --compiler-version "$version" $deployed ./src/${contract}.sol:${contract} $etherscan
else
  forge verify-contract --compiler-version "$version" $deployed ./src/${contract}.sol:${contract} $etherscan --constructor-args ${args}
fi
