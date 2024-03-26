object "DeploylessPredeployQueryer" {
    code {
        codecopy(returndatasize(), dataoffset("runtime"), codesize())
        let target := mload(returndatasize())
        let targetQueryCalldata := mload(0x20)
        let factoryCalldata := mload(0x60)
        // If the target does not exist, deploy it.
        if iszero(extcodesize(target)) {
            if iszero(
                call(
                    gas(),
                    mload(0x40),
                    returndatasize(),
                    add(factoryCalldata, 0x20),
                    mload(factoryCalldata),
                    0x00,
                    0x20
                )
            ) {
                returndatacopy(0x00, 0x00, returndatasize())
                revert(0x00, returndatasize())
            }
            if iszero(and(gt(returndatasize(), 0x1f), eq(mload(0x00), target))) {
                mstore(0x00, 0xd1f6b812) // `ReturnedAddressMismatch()`.
                revert(0x1c, 0x04)
            }
        }
        if iszero(
            call(
                gas(),
                target,
                callvalue(),
                add(targetQueryCalldata, 0x20),
                mload(targetQueryCalldata),
                codesize(),
                0x00
            )
        ) {
            returndatacopy(0x00, 0x00, returndatasize())
            revert(0x00, returndatasize())
        }
        mstore(0x00, 0x20)
        mstore(0x20, returndatasize())
        returndatacopy(0x40, 0x00, returndatasize())
        return(0x00, add(0x60, returndatasize()))
    }
    object "runtime" {
        code {}
    }
}
