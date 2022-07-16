#!/usr/bin/env bash

# Read the contract name
echo Which contract do you want to flatten \(eg Greeter\)?
read contract

# Remove an existing flattened contracts
rm -rf flattened.txt

# FLATTEN
forge flatten ./src/${contract}.sol > flattened.txt