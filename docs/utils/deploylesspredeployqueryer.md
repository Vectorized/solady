# DeploylessPredeployQueryer

Deployless queryer for predeploys.


This contract is not meant to ever actually be deployed,
only mock deployed and used via a static `eth_call`.

<b>Creation code (hex-encoded):</b>
`3860b63d393d516020805190606051833b15607e575b5059926040908285528351938460051b9459523d604087015260005b858103603e578680590390f35b6000828683820101510138908688820151910147875af115607457603f19875903018482890101523d59523d6000593e84016031565b3d6000803e3d6000fd5b816000828193519083479101906040515af11560ad5783815114601f3d111660155763d1f6b81290526004601cfd5b3d81803e3d90fdfe`
See: https://gist.github.com/Vectorized/f77fce00a03dfa99aee526d2a77fd2aa

May be useful for generating ERC-6492 compliant signatures.
Inspired by Ambire's DeploylessUniversalSigValidator
(https://github.com/AmbireTech/signature-validator/blob/main/contracts/DeploylessUniversalSigValidator.sol)



<!-- customintro:start --><!-- customintro:end -->

## Custom Errors

### ReturnedAddressMismatch()

```solidity
error ReturnedAddressMismatch()
```

The returned address by the factory does not match the provided address.