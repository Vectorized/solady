<img align="right" width="150" height="150" top="100" src="./assets/readme.jpg">

# femplate • [![ci](https://github.com/abigger87/femplate/actions/workflows/ci.yml/badge.svg)](https://github.com/abigger87/femplate/actions/workflows/ci.yml) ![license](https://img.shields.io/github/license/abigger87/femplate?label=license) ![solidity](https://img.shields.io/badge/solidity-^0.8.15-lightgrey)

A **Clean**, **Robust** Template for Foundry Projects.

## Getting Started

Click [`use this template`](https://github.com/abigger87/femplate/generate) to create a new repository with this repo as the initial state.

Or, if your repo already exists, run:
```sh
forge init --template https://github.com/abigger87/femplate
git submodule update --init --recursive
forge install
```

Run `./scripts/rename.sh` to rename all instances of `femplate` with the name of your project/repository.

## Blueprint

```ml
lib
├─ forge-std — https://github.com/foundry-rs/forge-std
├─ solmate — https://github.com/Rari-Capital/solmate
scripts
├─ Deploy.s.sol — Simple Deployment Script
src
├─ Greeter — A Minimal Greeter Contract
test
└─ Greeter.t — Exhaustive Tests
```


## Development

**Setup**
```bash
forge install
```

**Building**
```bash
forge build
```

**Testing**
```bash
forge test
```

**Deployment & Verification**

Inside the [`scripts/`](./scripts/) directory are a few preconfigured scripts that can be used to deploy and verify contracts.

Scripts take inputs from the cli, using silent mode to hide any sensitive information.

_NOTE: These scripts are required to be _executable_ meaning they must be made executable by running `chmod +x ./scripts/*`._

_NOTE: these scripts will prompt you for the contract name and deployed addresses (when verifying). Also, they use the `-i` flag on `forge` to ask for your private key for deployment. This uses silent mode which keeps your private key from being printed to the console (and visible in logs)._


### First time with Forge/Foundry?

See the official Foundry installation [instructions](https://github.com/foundry-rs/foundry/blob/master/README.md#installation).

Then, install the [foundry](https://github.com/foundry-rs/foundry) toolchain installer (`foundryup`) with:
```bash
curl -L https://foundry.paradigm.xyz | bash
```

Now that you've installed the `foundryup` binary,
anytime you need to get the latest `forge` or `cast` binaries,
you can run `foundryup`.

So, simply execute:
```bash
foundryup
```

🎉 Foundry is installed! 🎉


### Writing Tests with Foundry

With [Foundry](https://github.com/foundry-rs/foundry), all tests are written in Solidity! 🥳

Create a test file for your contract in the `test/` directory.

For example, [`src/Greeter.sol`](./src/Greeter.sol) has its test file defined in [`./test/Greeter.t.sol`](./test/Greeter.t.sol).

To learn more about writing tests in Solidity for Foundry, reference Rari Capital's [solmate](https://github.com/Rari-Capital/solmate/tree/main/src/test) repository created by [@transmissions11](https://twitter.com/transmissions11).


### Configure Foundry

Using [foundry.toml](./foundry.toml), Foundry is easily configurable.

For a full list of configuration options, see the Foundry [configuration documentation](https://github.com/foundry-rs/foundry/blob/master/config/README.md#all-options).


## License

[AGPL-3.0-only](https://github.com/abigger87/femplate/blob/master/LICENSE)


## Acknowledgements

- [femplate](https://github.com/abigger87/femplate)
- [foundry](https://github.com/foundry-rs/foundry)
- [solmate](https://github.com/Rari-Capital/solmate)
- [forge-std](https://github.com/brockelmore/forge-std)
- [forge-template](https://github.com/foundry-rs/forge-template)
- [foundry-toolchain](https://github.com/foundry-rs/foundry-toolchain)


## Disclaimer

_These smart contracts are being provided as is. No guarantee, representation or warranty is being made, express or implied, as to the safety or correctness of the user interface or the smart contracts. They have not been audited and as such there can be no assurance they will work as intended, and users may experience delays, failures, errors, omissions, loss of transmitted information or loss of funds. The creators are not liable for any of the foregoing. Users should proceed with caution and use at their own risk._
