// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice The address and bytecode of the canonical ERC1967Factory deployment.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/ERC1967FactoryLib.sol)
/// @author jtriley-eth (https://github.com/jtriley-eth/minimum-viable-proxy)
library ERC1967FactoryLib {
    /// @dev The canonical ERC1967Factory address for EVM chains.
    address internal constant ADDRESS = 0x0000000000066388c89f9BAA9dD2A8e426643200;

    /// @dev The canonical ERC1967Factory bytecode for EVM chains.
    /// Useful for forge tests:
    /// `vm.etch(ADDRESS, BYTECODE)`.
    bytes internal constant BYTECODE =
        hex"608060405234801561001057600080fd5b506107ed806100206000396000f3fe6080604052600436106100b15760003560e01c8063545e7c611161006957806399a88ec41161004e57806399a88ec4146101a1578063a97b90d5146101b4578063db4c545e146101c757600080fd5b8063545e7c611461017b5780639623609d1461018e57600080fd5b80633729f9221161009a5780633729f922146101355780634314f120146101485780635414dff01461015b57600080fd5b80631acfd02a146100b65780632abbef15146100d8575b600080fd5b3480156100c257600080fd5b506100d66100d13660046105fb565b6101ea565b005b3480156100e457600080fd5b5061010b6100f336600461062e565b6398762005600c908152600091909152602090205490565b60405173ffffffffffffffffffffffffffffffffffffffff90911681526020015b60405180910390f35b61010b610143366004610649565b61023f565b61010b6101563660046106ce565b610256565b34801561016757600080fd5b5061010b61017636600461072f565b61026f565b61010b6101893660046105fb565b6102a2565b6100d661019c3660046106ce565b6102b7565b6100d66101af3660046105fb565b61036b565b61010b6101c2366004610748565b61037c565b3480156101d357600080fd5b506101dc6103b5565b60405190815260200161012c565b6398762005600c52816000526020600c2033815414610211576382b429006000526004601cfd5b81905580827f7e644d79422f17c01e4894b5f4f588d331ebfa28653d42ae832dc59e38c9798f600080a35050565b600061024e848484368561037c565b949350505050565b6000610266858583808787610461565b95945050505050565b60008061027a6103b5565b905060ff600053806035523060601b6001528260155260556000209150600060355250919050565b60006102b083833684610256565b9392505050565b6398762005600c5283600052336020600c2054146102dd576382b429006000526004601cfd5b6040518381527f360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc602082015281836040830137600080836040018334895af161033d573d610333576355299b496000526004601cfd5b3d6000803e3d6000fd5b5082847f5d611f318680d00598bb735d61bacf0c514c6b50e1e5ad30040a4df2b12791c7600080a350505050565b61037882823660006102b7565b5050565b60008360601c33148460601c151761039c57632f6348366000526004601cfd5b6103ab86868660018787610461565b9695505050505050565b600080610453604051623d90fd60778201527f2035556040803611606557005b36038060403d373d3d355af43d82803e60515760748201527f3735a920a3ca505d382bbc545af43d82803e6051573d90fd5b3d90f35b3d356060548201527f14605557363d3d37363d7f360894a13ba1a3210667c828492db98dca3e2076cc60348201523060148201526d607c3d8160093d39f33d3d3d3373815290565b608560129091012092915050565b6000806104ff604051623d90fd60778201527f2035556040803611606557005b36038060403d373d3d355af43d82803e60515760748201527f3735a920a3ca505d382bbc545af43d82803e6051573d90fd5b3d90f35b3d356060548201527f14605557363d3d37363d7f360894a13ba1a3210667c828492db98dca3e2076cc60348201523060148201526d607c3d8160093d39f33d3d3d3373815290565b905084801561051957866085601284016000f59250610525565b6085601283016000f092505b50816105395763301164256000526004601cfd5b8781527f360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc602082015282846040830137600080846040018334865af161058c573d6103335763301164256000526004601cfd5b6398762005600c5281600052866020600c20558688837fc95935a66d15e0da5e412aca0ad27ae891d20b2fb91cf3994b6a3bf2b8178082600080a4509695505050505050565b803573ffffffffffffffffffffffffffffffffffffffff811681146105f657600080fd5b919050565b6000806040838503121561060e57600080fd5b610617836105d2565b9150610625602084016105d2565b90509250929050565b60006020828403121561064057600080fd5b6102b0826105d2565b60008060006060848603121561065e57600080fd5b610667846105d2565b9250610675602085016105d2565b9150604084013590509250925092565b60008083601f84011261069757600080fd5b50813567ffffffffffffffff8111156106af57600080fd5b6020830191508360208285010111156106c757600080fd5b9250929050565b600080600080606085870312156106e457600080fd5b6106ed856105d2565b93506106fb602086016105d2565b9250604085013567ffffffffffffffff81111561071757600080fd5b61072387828801610685565b95989497509550505050565b60006020828403121561074157600080fd5b5035919050565b60008060008060006080868803121561076057600080fd5b610769866105d2565b9450610777602087016105d2565b935060408601359250606086013567ffffffffffffffff81111561079a57600080fd5b6107a688828901610685565b96999598509396509294939250505056fea2646970667358221220792821579dda4cc236eb2c48669868e9ede6c80a196587eb9b2c9711d665b39e64736f6c63430008130033";
}
