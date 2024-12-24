# ERC1967FactoryConstants

The address and bytecode of the canonical ERC1967Factory deployment.


The canonical ERC1967Factory is deployed permissionlessly via
0age's ImmutableCreate2Factory located at 0x0000000000FFe8B47B3e2130213B802212439497.

`ADDRESS = immutableCreate2Factory.safeCreate2(SALT, INITCODE)`

If the canonical ERC1967Factory has not been deployed on your EVM chain of choice,
please feel free to deploy via 0age's ImmutableCreate2Factory.

If 0age's ImmutableCreate2Factory has not been deployed on your EVM chain of choice,
please refer to 0age's ImmutableCreate2Factory deployment instructions at:
https://github.com/ProjectOpenSea/seaport/blob/main/docs/Deployment.md

<b>Contract verification:</b>
<b>- Source code:</b>
https://github.com/Vectorized/solady/blob/5212e50fef1f2ff1b1b5e03a5d276a0d23c02713/src/utils/ERC1967Factory.sol
(The EXACT source code is required. Use the file at the commit instead of the latest copy.)
<b>- Optimization Enabled:</b> Yes with 1000000 runs
<b>- Compiler Version:</b> v0.8.19+commit.7dd6d404
<b>- Other Settings:</b> default evmVersion, MIT license



<!-- customintro:start --><!-- customintro:end -->

## Functions

### ADDRESS

```solidity
address internal constant ADDRESS =
    0x0000000000006396FF2a80c067f99B3d2Ab4Df24
```

The canonical ERC1967Factory address for EVM chains.

### BYTECODE

```solidity
bytes internal constant BYTECODE =
    hex"6080604052600436106100b15760003560e01c8063545e7c611161006957806399a88ec41161004e57806399a88ec41461019d578063a97b90d5146101b0578063db4c545e146101c357600080fd5b8063545e7c61146101775780639623609d1461018a57600080fd5b80633729f9221161009a5780633729f922146101315780634314f120146101445780635414dff01461015757600080fd5b80631acfd02a146100b65780632abbef15146100d8575b600080fd5b3480156100c257600080fd5b506100d66100d1366004610604565b6101e6565b005b3480156100e457600080fd5b506101076100f3366004610637565b30600c908152600091909152602090205490565b60405173ffffffffffffffffffffffffffffffffffffffff90911681526020015b60405180910390f35b61010761013f366004610652565b610237565b6101076101523660046106d7565b61024e565b34801561016357600080fd5b50610107610172366004610738565b610267565b610107610185366004610604565b61029a565b6100d66101983660046106d7565b6102af565b6100d66101ab366004610604565b61035f565b6101076101be366004610751565b610370565b3480156101cf57600080fd5b506101d86103a9565b604051908152602001610128565b30600c52816000526020600c2033815414610209576382b429006000526004601cfd5b81905580827f7e644d79422f17c01e4894b5f4f588d331ebfa28653d42ae832dc59e38c9798f600080a35050565b60006102468484843685610370565b949350505050565b600061025e8585838087876103c2565b95945050505050565b6000806102726103a9565b905060ff600053806035523060601b6001528260155260556000209150600060355250919050565b60006102a88383368461024e565b9392505050565b30600c5283600052336020600c2054146102d1576382b429006000526004601cfd5b6040518381527f360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc602082015281836040830137600080836040018334895af1610331573d610327576355299b496000526004601cfd5b3d6000803e3d6000fd5b5082847f5d611f318680d00598bb735d61bacf0c514c6b50e1e5ad30040a4df2b12791c7600080a350505050565b61036c82823660006102af565b5050565b60008360601c33148460601c151761039057632f6348366000526004601cfd5b61039f868686600187876103c2565b9695505050505050565b6000806103b461049c565b608960139091012092915050565b6000806103cd61049c565b90508480156103e757866089601384016000f592506103f3565b6089601383016000f092505b50816104075763301164256000526004601cfd5b8781527f360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc602082015282846040830137600080846040018334865af161045a573d6103275763301164256000526004601cfd5b30600c5281600052866020600c20558688837fc95935a66d15e0da5e412aca0ad27ae891d20b2fb91cf3994b6a3bf2b8178082600080a4509695505050505050565b6040513060701c801561054257666052573d6000fd607b8301527f3d356020355560408036111560525736038060403d373d3d355af43d6000803e60748301527f3735a920a3ca505d382bbc545af43d6000803e6052573d6000fd5b3d6000f35b60548301527f14605757363d3d37363d7f360894a13ba1a3210667c828492db98dca3e2076cc60348301523060148301526c607f3d8160093d39f33d3d337382525090565b66604c573d6000fd60758301527f3d3560203555604080361115604c5736038060403d373d3d355af43d6000803e606e8301527f3735a920a3ca505d382bbc545af43d6000803e604c573d6000fd5b3d6000f35b604e8301527f14605157363d3d37363d7f360894a13ba1a3210667c828492db98dca3e2076cc602e83015230600e8301526c60793d8160093d39f33d3d336d82525090565b803573ffffffffffffffffffffffffffffffffffffffff811681146105ff57600080fd5b919050565b6000806040838503121561061757600080fd5b610620836105db565b915061062e602084016105db565b90509250929050565b60006020828403121561064957600080fd5b6102a8826105db565b60008060006060848603121561066757600080fd5b610670846105db565b925061067e602085016105db565b9150604084013590509250925092565b60008083601f8401126106a057600080fd5b50813567ffffffffffffffff8111156106b857600080fd5b6020830191508360208285010111156106d057600080fd5b9250929050565b600080600080606085870312156106ed57600080fd5b6106f6856105db565b9350610704602086016105db565b9250604085013567ffffffffffffffff81111561072057600080fd5b61072c8782880161068e565b95989497509550505050565b60006020828403121561074a57600080fd5b5035919050565b60008060008060006080868803121561076957600080fd5b610772866105db565b9450610780602087016105db565b935060408601359250606086013567ffffffffffffffff8111156107a357600080fd5b6107af8882890161068e565b96999598509396509294939250505056fea26469706673582212200ac7c3ccbc2d311c48bf5465b021542e0e306fe3c462c060ba6a3d2f81ff6c5f64736f6c63430008130033"
```

The canonical ERC1967Factory bytecode for EVM chains.   
Useful for forge tests:   
`vm.etch(ADDRESS, BYTECODE)`.

### INITCODE

```solidity
bytes internal constant INITCODE = abi.encodePacked(
    hex"608060405234801561001057600080fd5b506107f6806100206000396000f3fe",
    BYTECODE
)
```

The initialization code used to deploy the canonical ERC1967Factory.

### SALT

```solidity
bytes32 internal constant SALT =
    0x0000000000000000000000000000000000000000e75e4f228818c80007508f33
```

For deterministic deployment via 0age's ImmutableCreate2Factory.