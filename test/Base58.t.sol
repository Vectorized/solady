// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/SoladyTest.sol";
import {Base58} from "../src/utils/Base58.sol";
import {LibString} from "../src/utils/LibString.sol";

contract Base58Test is SoladyTest {
    function testBase58DecodeRevertsIfInvalidCharacter(bytes1 c) public {
        if (isValidBase58Character(c)) {
            this.base58DecodeRevertsIfInvalidCharacter(c);
        } else {
            vm.expectRevert(Base58.Base58DecodingError.selector);
            this.base58DecodeRevertsIfInvalidCharacter(c);
        }
    }

    function isValidBase58Character(bytes1 c) internal pure returns (bool) {
        bytes memory allowed = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz";
        for (uint256 i; i < allowed.length; ++i) {
            if (allowed[i] == c) return true;
        }
        return false;
    }

    function base58DecodeRevertsIfInvalidCharacter(bytes1 c) public {
        emit LogBytes(Base58.decode(string(abi.encodePacked(c))));
    }

    function testBase58EncodeDecode(bytes memory data, uint256 r) public {
        if (r & 0x00f == 0) {
            _brutalizeMemory();
        }
        if (r & 0x0f0 == 0) {
            _misalignFreeMemoryPointer();
        }
        if (r & 0xf00 == 0) {
            data = abi.encodePacked(new bytes(_bound(_random(), 0, 128)), data);
        }

        uint256 h;
        uint256 m;
        /// @solidity memory-safe-assembly
        assembly {
            // Since `encode` writes memory backwards, we do some extra checks to ensure
            // that the initial length overestimate is sufficient.
            mstore(0x00, r)
            mstore(0x20, "hehe")
            h := keccak256(0x00, 0x40)
            m := mload(0x40)
            mstore(m, h)
            mstore(0x40, add(m, 0x20))
        }
        string memory encoded = Base58.encode(data);
        /// @solidity memory-safe-assembly
        assembly {
            if iszero(eq(mload(m), h)) { invalid() }
        }

        _checkMemory(encoded);
        if (r & 0x00f000 == 0) {
            _brutalizeMemory();
        }
        if (r & 0x0f0000 == 0) {
            _misalignFreeMemoryPointer();
        }

        /// @solidity memory-safe-assembly
        assembly {
            // Since `decode` writes memory backwards, we do some extra checks to ensure
            // that the initial length overestimate is sufficient.
            mstore(0x00, r)
            mstore(0x20, "haha")
            h := keccak256(0x00, 0x40)
            m := mload(0x40)
            mstore(m, h)
            mstore(0x40, add(m, 0x20))
        }
        bytes memory decoded = Base58.decode(encoded);
        /// @solidity memory-safe-assembly
        assembly {
            if iszero(eq(mload(m), h)) { invalid() }
        }

        _checkMemory(decoded);
        assertEq(data, decoded);
    }

    function testBase58EncodeDecode() public {
        this._testBase58EncodeDecode(hex"", "");
        this._testBase58EncodeDecode(hex"0d", "E");
        this._testBase58EncodeDecode(hex"000e", "1F");
        this._testBase58EncodeDecode(hex"00f3", "15C");
        this._testBase58EncodeDecode(hex"00", "1");
        this._testBase58EncodeDecode(hex"f2", "5B");
        this._testBase58EncodeDecode(hex"0002da", "1Db");
        this._testBase58EncodeDecode(hex"0027b9", "142L");
        this._testBase58EncodeDecode(hex"00d80f", "1HSe");
        this._testBase58EncodeDecode(hex"ce", "4Z");
        this._testBase58EncodeDecode(hex"7c", "39");
        this._testBase58EncodeDecode(hex"cd0b5dfe722552f609ce", "CX9VkoSqX63kbo");
        this._testBase58EncodeDecode(
            hex"00598b3dc0966af86beb7898fc9921c2fbc38a19d52dee9dfed69e3d",
            "1D6w66tNCxvikkpma3BXnRnABJQojACXjHxtdJ"
        );
        this._testBase58EncodeDecode(
            hex"09100a2fc14628f168c2c9b980fb840857fbb9fe031013c9bf7e218d5c",
            "Qs1VMdvTSeZkZ5p4e4xQaLa8J3ptpJzJAcM1Mp7"
        );
        this._testBase58EncodeDecode(
            hex"001d85089c34888205378be7e8f9ff5e2f", "14eRVxHMi5hh14FM9Gpd1Ua"
        );
        this._testBase58EncodeDecode(
            hex"0090ccbb306b1cc8f226e905623d19604fd0ad73bd80b8b4712e",
            "121GLNsu9Tdp147zdSjFvJudL1pp1Qv39myF"
        );
        this._testBase58EncodeDecode(hex"012ee97bcab1", "bB9gNQp");
        this._testBase58EncodeDecode(
            hex"00f91f623af2d76e8ee2abdbfe5e3671373ad4736d2433397c93e08e63e9ce1830",
            "1HmUGpDZUwcvX5xPMNQ9oHoMz8nKQF6EWgqno2iSXQJc7"
        );
        this._testBase58EncodeDecode(
            hex"00000000000000000000000000000000000000000000000000000000000000fb53beb02ab2ab6583638677b592b2b56f321d94972b38acfd6d4cd1202f77ff1fddf68b9d2c4bdb1b6ced6ef31e282e48790854ce9c0ab93435761d0f5db1e16817119e682391a23f633d9cdd6481a07585ec17d6aeca0849eab41f5895cfc4e9503f97345a364964d7e024c947ae7c238d1a4705",
            "1111111111111111111111111111111QVs5qPAkBrBEtm1UXSAcNGHgA6cUYDn4oAXAxgEQ5jntH1aWoie6t7a1j2RTmP4E5uGFpWwTUj7zyeKcs7BKMXJBRXHuokJ13KmbHC6RLtAbUdobwBcjx2UjCK5rPwVBjABFvjgGAaFFwEZgnRPudGLqLqJdCx6G"
        );
        this._testBase58EncodeDecode(
            hex"000000000000000000000000000000000000000031f89a3264997ab236bf9c5200a5353c4e04a134ad572583a140f9c3cc7d4f3f6331716c",
            "11111111111111111111P1So9spX62PHGLRTG8SgU1Lm19f6SgCozbp8Use7LdcMGYAKD"
        );
        this._testBase58EncodeDecode(
            hex"000000000000000000000013bc3b22341190c36a1cda2a0a1ed6f93a080447160b626b2f711c9a266bdc17622794eb9d",
            "11111111111fN3TfvHm4xfWWJT7FqjTP9WXJiCoKJejeRgQmU6LcWUgJezrH2"
        );
        this._testBase58EncodeDecode(
            hex"000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b1859e09c90d4ac3dd4c89c3c2452b4d22c92d0eee246e75d72d7209078d5230159b5e52249d5b6017e6992696028d390c61d26c0d42395072378ad89df7b94dbef0624cd0e1e091829c6292e9cf8303b43bec",
            "1111111111111111111111111111111111111111111111111113sLfBS3DP3qb3hQoRZDt1DotgrCJU5N17jh4bFG6cs5KGz4Z1wqWJC6bHVbgKYXAUMVvoqFbZAzC5Rg95xvsbmhTLkuH3jbPkqiXuGcRm2wGmiom8f"
        );
        this._testBase58EncodeDecode(
            hex"0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000322a08fd25e4a383cf093664c6a28531bdfa2e6d3a0afdddae9a58fe1074642f979d6cc1dd196e77d63fac03e9e52815bb211a760e37470b006e9682a8d432",
            "11111111111111111111111111111111111111111111111111111111111EBQAEDu1wmQTkQGGtoxiwzZzxPp3q6jswQS8BoqBuKzxhmVg8ThLq8Z6HjrcBPX5BsGYWTA7sjHP9CeASeFEsj"
        );
        this._testBase58EncodeDecode(
            hex"00000000000000c305c2e9ca1fed1817ff8ddc60fb26b5665ce958f9cbeb3f907e6ae500d5917d24b3b30b0d9e382e9521eeb232c7f5d328f0e239cec44d21d49472727a1ec7555580c88f2776",
            "11111119a4d2p5cardGk5zgtKRV5xmbugoNWw3fp8eWTq3sjbVTYr7aXiE3wGzqe5bGgusiYsBzvdPibo5BVNxaxudCXc6WkikU8xwP"
        );
        this._testBase58EncodeDecode(
            hex"00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005fcee37b107ba13473fff385e60e48f7085c72ca9fa64af6c21a568a281161db2af9844f52867ea6048a502da3dd827158b199f1c7e330028b849e135d7f5418923e",
            "11111111111111111111111111111111111111111111111111eKPzXLFs4zguFbvYgRSoJDb6mTyCPFhve4Yww4PNDs89z8Kxd72pkXqDix6FkN62WxgNfrNry43pbizFaUuzaExHCy"
        );
        this._testBase58EncodeDecode(
            hex"00000013dff1618a82531e334a62f0de8f17c074732abf4c59cd7c",
            "1112p67UFfiuvQD92aDbWzpm1Z5EU6Q8TtpB"
        );
        this._testBase58EncodeDecode(
            hex"00000000000000000000003fd220658684b1ccef6552", "11111111111GpuXVbXqt99pach"
        );
        this._testBase58EncodeDecode(
            hex"0000000000000000000000000000000000000000000000000000e8271fe396fe0cf6bcc1f7881c9cbae4d147bbb61e947fb129177acd9887c0dca8348ffd2a385ecdac852073b60d7daf003d6e188c1841ddc5b68c3b9e3eda4c090f3567c54bd372676ee0ff9fbfede9",
            "111111111111111111111111113Xj8EySrK3wEvmYt59y4b1vxzjGwPc688wZA4jXsyGNgEh7ghaP9ohvqseUcNUUCeqLxtyzWDPfngB1iHzjsEeaN14UjSeSZdCoWUSVHAYVtX2"
        );
        this._testBase58EncodeDecode(
            hex"0000000000000000000000000000000000000000000000000000000000000000000000003c58cebe89322eee5505a37a842fb64cd726c8a8adaa8a20c34de8eaff08373abe2f5912c912dde618fcb0b4a8a14da4f3fbc7d6004684fcedd7f133af9abe9360793485dbe855f3875e631c96d8ee775240cac29f2c8640aa9485f8c6b6410c0ac7fc83",
            "1111111111111111111111111111111111113M2hXzVT7xgwnteR7ZsprbP5xBdDBWkkQHpVUJScKLca3WAfPSCUQ59d3a4zGU4P2Q5Dvgmz9LVbf1erXBmxLsha5PEhFmHDBpyGW5ZFSJswPtGRYQeVPWKpr3cbQbexUFsNpqVea"
        );
        this._testBase58EncodeDecode(
            hex"000000000000000000000000000000000000000000000000000000000000000060234520525c5c627553370b53eb6d76c7766490efc4dae6fd5c5940008b5110eb834a2168c9728d51840c4e571321d4f08391009a0c3785c6c6b9b14d774629995acf59bf07f88b2762b426ddd135516a24daf2",
            "111111111111111111111111111111117rbt7xcf57aaNKwQwTxYHWqqtGYNiSM63bYVGhBKNExhvAubcT68EToxSShmawAr33vALSbua2s1xt9C6yPCXU5dGA8cr1B8GS6WXVCh24heoNrUbSR"
        );
        this._testBase58EncodeDecode(
            hex"000000000000000000000000000000000000000000000000000000000000000000003b4c61dee11d868b463c055521a78d6552daefdfdc3fc03216cd84667365c0346a2954fe099bdf4baea658b3cee9589c6d217f8b3642",
            "11111111111111111111111111111111115nJEXtj9QijtXd2gqb9bgPvanHGcXLdhKX14UbmuitdejFDnZ5MiGpHALxfnMVvo4CbVKcPHhK"
        );
        this._testBase58EncodeDecode(
            hex"000000000000000000000000000013ba6b7a5b28ee62e23e2f037169950bfaa76a49cd560bf283cb7a76eab12b0766f61979108cd0bed77d37",
            "111111111111112THktPmYvuwnWuVqbsNgWfAaR1dxCTi6zHB6ggkAidRRhwrrWmL3PGGCJ2J"
        );
        this._testBase58EncodeDecode(
            hex"000000000000000000000000000000000000000000000000000000000000000000000000000000e357a949bd269668402d9fe64611b55659fa5c077ed6896ba83c99f6362ff3ddfb145512bd7825d25d99b62f392d42c397191d91a85cb3aac3f5aba7a1f8c7c5098ea8d8e452eab896ce53510d58f64518509dc4c9a93f9feccb8040b18fc8065e9811e954c4c421264d528ae0817f4981a11bfe",
            "1111111111111111111111111111111111111115pJo5spTW949hEVQhtDHsyhLcMfUC6gHCM9pPGYter8CD12cNuXbshZvtDZoFAjwjuCftRhweQ7TcuARE52aqNzC5He3rqs1YdEreCTYqoPuQDqufzeDjywYJQmkgwaLrDbhKcjUbxFVMertvBGeUkB7tDiSMBs"
        );
        this._testBase58EncodeDecode(
            hex"00000000000000000000000000000000000000af64ba6caafbbca128653eff8c51",
            "111111111111111111127UskEy2WhgsTGAY4Qi4"
        );
        this._testBase58EncodeDecode(
            hex"0000000000000000000000000f744c6b510384801d5d10035f00b562f05c585aac1fe57f27b640096aafc1cb28a859d7ece16ee8c6813708193047aafd18c4",
            "111111111111qkJMpKZLaSweHBvLEBUxhcB7AnaBv6QRC7mkQS54QEuh8PYp7pn7VfueHTsD4W1gF7px3"
        );
        this._testBase58EncodeDecode(
            hex"0000000000000000000000000000000000000000a4ae531a4546129e810fe716bef089bf466eed25dd729688c82481c3eea5cec22219d7dfcccb814a141dd14b98677f905c5efbc38f65040216f27042dcdf31ac81eff75985176ed0a40ae16eadca11464e40f16ee8fc2fd06ec6629d098759365df73073e4d4124b6003457367a484dc278b2e",
            "11111111111111111111nqeSEB5S7wspidSeWX3LCxrjoSxFcAEE3C9LFix6tQHFWPMUWMSoFf2rStXF5JxarB4Dhxvnhbanz6mLyMerUKxU6WFag1vQMgCTLeeNHcRiu1srGtHB3YrVgoz6h2mAHyhs1ukVrGYmSmmKRty75Jx4zJ661"
        );
        this._testBase58EncodeDecode(
            hex"000000451c0d1e6a9b414cd8ee1d1fa7f7805de82932a48991c9edaf814215d069d5f1fef3a63f931792b2d113ce0a309d5e22a1d9ede1cca2e7e358e9d2600498f2e9a0c8159cebffa293512fe5b0f3d9971bb2a07d1b7df5f81af612141e4693147428285c21621c8e772a627ca1a9",
            "1119kd1Rja2XCCMQDiRBv7EEX5upePsrmhBRHL4kkK8oBR3dSvVE4yuRtUzZKmtvWiBUD6qFk3HCoWpDapRw7WhBi3qR94ZeLkFuAZbqN4D2N4V6AgLdh2n1JwM3Z8i9quwNPHY4TNU2B2NYwZ2tons2"
        );
        this._testBase58EncodeDecode(
            hex"0000000000000000000000000000cc50f101efa6b062341bdc59edc70e9776728db82f5779100210d5907ebbe56673ef72e013987a297d560ad9e2229c508ce3568e5dd0f61e671e15f21521f9206a435c634b1f0d254326965d6c6eac24aec4b7fecc84b753d76d4e1bca902d662deb23a678f6cc1811",
            "111111111111114xLrKJa5yzRCpMhRUMMv6WoK9hkibnv9rVbDQgxq5oWvSUv3UBJUjQ5xeFapu4ZZ4nDoi1C34c115cirJd5f1LucLojD45CuiGWNbCFQsPcQPfpkheZe1b5xWGsBPZzvZHxUaik4YAtk5sEg"
        );
    }

    function _testBase58EncodeDecode(bytes memory data, string memory expectedEncoded) public {
        string memory encoded = Base58.encode(data);
        assertEq(expectedEncoded, encoded);
        bytes memory decoded = Base58.decode(encoded);
        assertEq(data, decoded);
    }

    function testCarryBoundsTrick(uint248 limb, uint8 carry) public pure {
        if (carry < 58) {
            uint256 acc = uint256(limb) * 58 + uint256(carry);
            assert((acc >> 248) < 58);
        }
    }

    function check_CarryBoundsTrick(uint248 limb, uint8 carry) public pure {
        testCarryBoundsTrick(limb, carry);
    }

    function testEncodeWordDifferential(bytes32 word) public {
        string memory expected = Base58.encode(abi.encodePacked(word));
        string memory computed = Base58.encodeWord(word);
        assertEq(computed, expected);
    }

    function testEncodeDecodeWord(bytes32 word) public {
        string memory encoded = Base58.encodeWord(word);
        assertEq(Base58.decodeWord(encoded), word);
    }

    function testDecodeWordDifferential(bytes32 word) public {
        string memory encoded = Base58.encodeWord(word);
        bytes32 expected = _decodeWordOriginal(encoded);
        bytes32 computed = Base58.decodeWord(encoded);
        _checkMemory();
        assertEq(computed, expected);
    }

    function testDecodeWordOverflowsReverts() public {
        bytes32 expected = bytes32(type(uint256).max);
        assertEq(this.decodeWord("JEKNVnkbo3jma5nREBBJCDoXFVeKkD56V3xKrvRmWxFG"), expected);
        assertEq(this.decodeWord("1JEKNVnkbo3jma5nREBBJCDoXFVeKkD56V3xKrvRmWxFG"), expected);
        assertEq(this.decodeWord("11JEKNVnkbo3jma5nREBBJCDoXFVeKkD56V3xKrvRmWxFG"), expected);

        vm.expectRevert(Base58.Base58DecodingError.selector);
        this.decodeWord("JEKNVnkbo3jma5nREBBJCDoXFVeKkD56V3xKrvRmWxFH");
        vm.expectRevert(Base58.Base58DecodingError.selector);
        this.decodeWord("JEKNVnkbo3jma5nREBBJCDoXFVeKkD56V3xKrvRmWxFJ");
    }

    function testDecodeWordInvalidCharacterReverts() public {
        vm.expectRevert(Base58.Base58DecodingError.selector);
        this.decodeWord("JEKNVnkbo3jma5nREBBJCDoXFVeKkD56V3xKrvRmWxFH@");
    }

    function decodeWord(string memory encoded) public pure returns (bytes32) {
        return Base58.decodeWord(encoded);
    }

    function _decodeWordOriginal(string memory encoded) internal pure returns (bytes32 result) {
        bytes memory t = Base58.decode(encoded);
        /// @solidity memory-safe-assembly
        assembly {
            let n := mload(t)
            if iszero(lt(n, 0x21)) {
                mstore(0x00, 0xe8fad793) // `Base58DecodingError()`.
                revert(0x1c, 0x04)
            }
            result := mload(add(t, n))
        }
    }

    function testDecodeWordGas() public {
        bytes32 expected = bytes32(type(uint256).max);
        assertEq(Base58.decodeWord("JEKNVnkbo3jma5nREBBJCDoXFVeKkD56V3xKrvRmWxFG"), expected);
    }

    function testDecodeGas() public {
        bytes memory expected = abi.encodePacked(type(uint256).max);
        assertEq(Base58.decode("JEKNVnkbo3jma5nREBBJCDoXFVeKkD56V3xKrvRmWxFG"), expected);
    }
}
