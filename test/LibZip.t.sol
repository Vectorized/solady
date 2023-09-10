// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/SoladyTest.sol";
import {MockCd, MockCdFallbackDecompressor} from "./utils/mocks/MockCd.sol";
import {LibClone} from "../src/utils/LibClone.sol";
import {ERC1967Factory} from "../src/utils/ERC1967Factory.sol";
import {LibString} from "../src/utils/LibString.sol";
import {DynamicBufferLib} from "../src/utils/DynamicBufferLib.sol";
import {LibZip} from "../src/utils/LibZip.sol";

contract LibZipTest is SoladyTest {
    using DynamicBufferLib for DynamicBufferLib.DynamicBuffer;

    function testFlzCompressDecompress() public brutalizeMemory {
        assertEq(LibZip.flzCompress(""), "");
        assertEq(LibZip.flzDecompress(""), "");
        bytes memory compressed =
            hex"1f4e65772077617665206469676974616c206172742073686f756c64206e6f74201f6265206a756467656420736f6c656c79206f6e20616573746865746963206d65017269202301757420240e737420617320696d706f7274616e74202a1b666f7220697473206162696c69747920746f20646576656c6f702061200c406d03766973692051026f662020510320576972206801616e200301626f209315616c6c20637265617465206e6574776f726b20737069207201756140500e2e20416e6369656e7420477265656b60ba04697320686520bb01696e6051036869676820ad062072656761726420cd0463617573652095c089406f0220776820db03206d79742007016f6720a801686141040061401d0272656c2119066f6e2c206d6f72607660a0017761210a0866206c6966652e2054212f016768607c20ff026c6963205fa080414e40b80073402de003ae016365613741630373756666203320c8213406646973656e676141710366726f6d208b016520201102736f722097006f208e03666c6563205e21570b6f776e2070726f647563747340840065400d03626c656d406b056d6f6465726e417621120074201ba17a006d2066401f0272617420d521f00273656c200d805620118048036265617520e920e140c00561707065617220dc21fb41d5006d21310a69636820636f6e74726173208a02616273200920972142410a40450275732ce0081720852028016f798092056e616976652f40dd02756f752044057070726563696098c07a2072076578657274696e6760f3046e617475722172015265818b20dc02736c612025016279208e006d20400068212c60c701507221de2281026e7465409a201304207769746820a200652008426906696e766f6c7665808c20bf006e21940373657061811b4082227c2312e006dc620004616363656c20580074203e0165782062214b01697380bb2072026f207020a74009017569407a072c20656d626f647940c74080c2cf42ec01756e4183214c0273636921074204027261774029006f235905747275746873e2010c02636f6c42012139223c046f73706865410f025468724178205b2111016265603c830280ea0077228a02636869237e21c20172652144201d006f214e2047002ce0078140b620da2064c20f06696e64697669642377032065676f6175036163726922b6234060ee40d4e00b9a405c210121be205701756e2294208063fc23fa201583d040c0427523aa427021cf404f80ba20d04325016f6e21186297036966756c633c82fc21800061e1004f804e20a722f9052e2049206c6f20634488024e657443870d2053706972697475616c69747921";
        bytes memory decompressed = LibZip.flzDecompress(compressed);
        bytes memory expectedDecompressed =
            "New wave digital art should not be judged solely on aesthetic merit but just as importantly for its ability to develop a total vision of the Wired and above all create network spirituality. Ancient Greek art is held in the highest regard because it developed a whole mythology that shaped religion, morality and way of life. Thought is implicit in the art works of Ancient Greece but not sufficiently disengaged from the sensory to reflect its own products. The problem of modernity is the development of rational self reflection. The beauty of art appears in a form which contrasts abstract thought. Thus, abstract thought destroys the naive/sensuous appreciation of art in exerting its nature. Reality is slain by comprehension. Proper interaction with the wired involves the trance separation of real abstract thought and accelerates externalisation into pure intuition, embodying the network and unselfconsciously drawing out truths from the collective noosphere. Through this being on the wired we achieve a return to naive, unselfconscious interaction. The individual ego is sacrificed into the collective noosphere, uniting us under a totalising spirit. The best art in the wired is not only beautiful but produces a network spirituality. I long for Network Spirituality!";
        assertEq(decompressed, expectedDecompressed);
        assertEq(LibZip.flzCompress(decompressed), compressed);
        // Check backwards compatibility with older FastLZ releases.
        compressed =
            hex"1f4e65772077617665206469676974616c206172742073686f756c64206e6f74201f6265206a756467656420736f6c656c79206f6e20616573746865746963206d65017269202301757420240e737420617320696d706f7274616e74202a1b666f7220697473206162696c69747920746f20646576656c6f702061200c406d03766973692051026f662020510320576972206801616e200301626f209315616c6c20637265617465206e6574776f726b20737069207201756140500e2e20416e6369656e7420477265656b60ba04697320686520bb01696e6051036869676820ad062072656761726420cd0463617573652095c089406f0220776820db03206d79742007016f6720a801686141040061401d0272656c2119066f6e2c206d6f72607660a0017761210a0866206c6966652e2054212f016768607c20ff026c6963205fa080414e40b80073402de003ae016365613741630373756666203320c8213406646973656e676141710366726f6d208b016520201102736f722097006f208e03666c6563205e21570b6f776e2070726f647563747340840065400d03626c656d406b056d6f6465726e417621124044a17a006d2066401f0272617420d521f00273656c200d805620118048036265617520e920e140c00561707065617220dc21fb41d5006d21310a69636820636f6e74726173208a02616273200920972142410a40450275732ce0081720852028016f798092056e616976652f40dd02756f752044057070726563696098c07a2072076578657274696e6760f3046e617475722172015265818b20dc02736c612025016279208e006d20400068212c60c701507221de2281026e7465409a201304207769746820a200652008426906696e766f6c7665808c20bf006e21940373657061811b4082227c2312e006dc620004616363656c20580074203e0165782062214b01697380bb2072026f207020a74009017569407a072c20656d626f647940c74080c2cf42ec01756e4183214c0273636921074204027261774029006f235905747275746873e2010c02636f6c42012139223c046f73706865410f025468724178205b2111016265603c830280ea0077228a02636869237e21c20172652144201d006f214e2047002ce0078140b620da2064c20f06696e64697669642377032065676f6175036163726922b6234060ee40d4e00b9a405c210121be205701756e2294208063fc23fa201583d040c0427523aa427021cf404f80ba20d04325016f6e21186297036966756c633c82fc21800061e1004f804e20a722f9052e2049206c6f20634488004ea4400c53706972697475616c69747921";
        assertEq(LibZip.flzDecompress(compressed), decompressed);
    }

    function _expandedData(bytes memory data) internal returns (bytes memory) {
        unchecked {
            DynamicBufferLib.DynamicBuffer memory buffer;
            bytes memory r = abi.encode(_random());
            if (_random() % 8 == 0) {
                r = abi.encodePacked(r, r, r, r);
                r = bytes(LibString.slice(string(r), 0, _random() % r.length));
            }
            uint256 n = _random() % 16 + 1;
            uint256 c = _random();
            for (uint256 i; i < n; ++i) {
                buffer.p((c >> i) & 1 == 0 ? r : data);
            }
            return buffer.data;
        }
    }

    function testFlzCompressDecompress(bytes memory data) public brutalizeMemory {
        if (_random() % 2 == 0) {
            data = _expandedData(data);
        }
        bytes32 dataHash = keccak256(data);
        _misalignFreeMemoryPointer();
        bytes memory compressed = LibZip.flzCompress(data);
        bytes32 compressedHash = keccak256(compressed);
        _checkMemory(compressed);
        _misalignFreeMemoryPointer();
        bytes memory decompressed = LibZip.flzDecompress(compressed);
        _checkMemory(compressed);
        _checkMemory(decompressed);
        assertEq(decompressed, data);
        assertEq(keccak256(data), dataHash);
        assertEq(keccak256(compressed), compressedHash);
    }

    function testFlzCompressDecompress2() public brutalizeMemory {
        bytes memory data =
            "______________________________________________________________e_______8______________________________________________________________________________________________________________________12_______8______________________________________________________________________________________________________________________16_______8______________________________________________________________________________________________________________________1a_______________________________________________________________2_____________________________________________732e2_5_726f2_49__73______________________________________________________________2_____________________________________________732e2_5_726f2_49__73______________________________________________________________2_____________________________________________732e2_5_726f2_49__73______________________________________________________________2_____________________________________________732e2_5_726f2_49__73";
        bytes32 dataHash = keccak256(data);
        bytes memory expectedCompressed =
            hex"015f5fe033010065a03c0038a007e06600013132a070e06f7f0036e0767f0061a07fe02f00c13fe01d000f37333265325f355f37323666325f34394011e01d39e00f00e0fd7fe02e7f04395f5f3733";
        bytes memory compressed = LibZip.flzCompress(data);
        assertEq(compressed, expectedCompressed);
        bytes32 compressedHash = keccak256(compressed);
        _checkMemory(compressed);
        bytes memory decompressed = LibZip.flzDecompress(compressed);
        _checkMemory(compressed);
        _checkMemory(decompressed);
        assertEq(decompressed, data);
        assertEq(keccak256(data), dataHash);
        assertEq(keccak256(compressed), compressedHash);
    }

    function testCdCompressDecompress(bytes memory data) public brutalizeMemory {
        if (_random() % 8 == 0) {
            data = _expandedData(data);
        }
        bytes32 dataHash = keccak256(data);
        _misalignFreeMemoryPointer();
        bytes memory compressed = LibZip.cdCompress(data);
        bytes32 compressedHash = keccak256(compressed);
        _checkMemory(compressed);
        _misalignFreeMemoryPointer();
        bytes memory decompressed = LibZip.cdDecompress(compressed);
        _checkMemory(compressed);
        _checkMemory(decompressed);
        assertEq(decompressed, data);
        assertEq(keccak256(data), dataHash);
        assertEq(keccak256(compressed), compressedHash);
    }

    function _randomCd() internal returns (bytes memory data) {
        uint256 n = _random() % 8 == 0 ? _random() % 2048 : _random() % 256;
        data = new bytes(n);
        if (_random() % 2 == 0) {
            /// @solidity memory-safe-assembly
            assembly {
                for { let i := 0 } lt(i, n) { i := add(i, 0x20) } {
                    mstore(add(add(data, 0x20), i), not(0))
                }
            }
        }
        if (n != 0) {
            uint256 m = _random() % 8;
            for (uint256 j; j < m; ++j) {
                data[_random() % n] = bytes1(uint8(_random()));
            }
        }
    }

    function testCdCompressDecompress(uint256) public brutalizeMemory {
        unchecked {
            bytes memory data = _randomCd();
            bytes memory compressed = LibZip.cdCompress(data);
            bytes memory decompressed = LibZip.cdDecompress(compressed);
            assertEq(decompressed, data);
        }
    }

    function testCdFallbackDecompressor(bytes memory data) public {
        bytes memory compressed = LibZip.cdCompress(data);
        MockCdFallbackDecompressor decompressor = new MockCdFallbackDecompressor();
        (, bytes memory result) = address(decompressor).call(compressed);
        assertEq(abi.decode(result, (bytes32)), keccak256(data));
    }

    function testCdFallbackDecompressor(uint256) public {
        bytes memory data = _randomCd();
        bytes memory compressed = LibZip.cdCompress(data);
        MockCdFallbackDecompressor decompressor = new MockCdFallbackDecompressor();
        (, bytes memory result) = address(decompressor).call(compressed);
        assertEq(abi.decode(result, (bytes32)), keccak256(data));
    }

    function testCdCompress() public {
        assertEq(LibZip.cdCompress(""), "");
        assertEq(LibZip.cdDecompress(""), "");
        bytes memory data =
            hex"ac9650d80000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000160000000000000000000000000000000000000000000000000000000000000022000000000000000000000000000000000000000000000000000000000000002a000000000000000000000000000000000000000000000000000000000000000a40c49ccbe000000000000000000000000000000000000000000000000000000000005b70e00000000000000000000000000000000000000000000000000000dfc79825feb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000645c48a7000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000084fc6f7865000000000000000000000000000000000000000000000000000000000005b70e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ffffffffffffffffffffffffffffffff00000000000000000000000000000000ffffffffffffffffffffffffffffffff00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004449404b7c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000001f1cdf1a632eaaab40d1c263edf49faf749010a1000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000064df2ab5bb0000000000000000000000007f5c764cbc14f9669b88837ca1490cca17c3160700000000000000000000000000000000000000000000000000000000000000000000000000000000000000001f1cdf1a632eaaab40d1c263edf49faf749010a100000000000000000000000000000000000000000000000000000000";
        bytes memory expected =
            hex"5369af27001e20001e04001e80001d0160001d0220001d02a0001ea40c49ccbe001c05b70e00190dfc79825feb005b645c48a7003a84fc6f7865001c05b70e002f008f000f008f003a4449404b7c002b1f1cdf1a632eaaab40d1c263edf49faf749010a1003a64df2ab5bb000b7f5c764cbc14f9669b88837ca1490cca17c31607002b1f1cdf1a632eaaab40d1c263edf49faf749010a1001b";
        assertEq(LibZip.cdCompress(data), expected);
    }

    function testCdDecompressOnInvalidInput() public {
        bytes memory data = hex"ffffffff00ff";
        bytes memory expected =
            hex"0000ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000";
        bytes memory decompressed = LibZip.cdDecompress(data);
        assertEq(decompressed, expected);
    }

    function testDecompressWontRevert(bytes memory data) public brutalizeMemory {
        data = LibZip.cdDecompress(data);
        bytes memory compressed = LibZip.cdCompress(data);
        bytes memory decompressed = LibZip.cdDecompress(compressed);
        assertEq(decompressed, data);
    }

    function testCdFallback() public {
        MockCd mockCd = new MockCd();
        _testCdFallback(mockCd);
        // Check if it also works for clones.
        mockCd = MockCd(payable(LibClone.clone(address(mockCd))));
        _testCdFallback(mockCd);
        // Check if it also works for CWIA.
        mockCd = MockCd(payable(LibClone.clone(address(mockCd), "")));
        _testCdFallback(mockCd);
        // Check if it also works for ERC1967 proxies.
        ERC1967Factory factory = new ERC1967Factory();
        mockCd = MockCd(payable(factory.deploy(address(mockCd), address(this))));
        _testCdFallback(mockCd);
    }

    function _testCdFallback(MockCd mockCd) internal {
        uint256[] memory numbers = new uint256[](100);
        unchecked {
            for (uint256 i; i < numbers.length; ++i) {
                numbers[i] = i % 2 == 0 ? i : ~i;
            }
        }
        assertEq(mockCd.numbersHash(), 0);
        assertEq(mockCd.lastCallvalue(), 0);
        assertEq(mockCd.lastCaller(), address(0));

        uint256 callValue = 123 ether;
        vm.deal(address(this), callValue * 2);

        (bool success, bytes memory result) = payable(mockCd).call{value: callValue}(
            LibZip.cdCompress(
                abi.encodeWithSignature("storeNumbersHash(uint256[],bool)", numbers, true)
            )
        );

        assertTrue(success);
        bytes32 decodedNumbersHash = abi.decode(result, (bytes32));
        bytes32 expectedNumbersHash = keccak256(abi.encode(numbers));
        assertEq(decodedNumbersHash, expectedNumbersHash);
        assertEq(mockCd.numbersHash(), expectedNumbersHash);
        assertEq(mockCd.lastCallvalue(), callValue);
        assertEq(mockCd.lastCaller(), address(this));
        assertEq(address(mockCd).balance, callValue);

        (success, result) = payable(mockCd).call{value: callValue}(
            LibZip.cdCompress(
                abi.encodeWithSignature("storeNumbersHash(uint256[],bool)", numbers, false)
            )
        );

        assertFalse(success);
        assertEq(address(mockCd).balance, callValue);
        assertEq(abi.encodeWithSelector(MockCd.Hash.selector, expectedNumbersHash), result);
        assertEq(address(mockCd).balance, callValue);

        (success, result) = payable(mockCd).call{value: callValue}("");
        assertEq(address(mockCd).balance, callValue * 2);
        assertTrue(success);
    }

    function testCdFallback(bytes memory data, uint256 callValue) public brutalizeMemory {
        MockCd mockCd = new MockCd();
        callValue = _bound(callValue, 0, 123 ether);
        vm.deal(address(this), callValue * 2);
        if (_random() % 8 == 0) {
            data = _expandedData(data);
        }

        (bool success, bytes memory result) = payable(mockCd).call{value: callValue}(
            LibZip.cdCompress(abi.encodeWithSignature("storeDataHash(bytes,bool)", data, true))
        );

        assertTrue(success);
        bytes32 decodedDataHash = abi.decode(result, (bytes32));
        bytes32 expectedDataHash = keccak256(data);
        assertEq(decodedDataHash, expectedDataHash);
        assertEq(mockCd.dataHash(), expectedDataHash);
        assertEq(mockCd.lastCallvalue(), callValue);
        assertEq(mockCd.lastCaller(), address(this));
        assertEq(address(mockCd).balance, callValue);

        (success, result) = payable(mockCd).call{value: callValue}(
            LibZip.cdCompress(abi.encodeWithSignature("storeDataHash(bytes,bool)", data, false))
        );

        assertFalse(success);
        assertEq(address(mockCd).balance, callValue);
        assertEq(abi.encodeWithSelector(MockCd.Hash.selector, expectedDataHash), result);
        assertEq(address(mockCd).balance, callValue);

        (success, result) = payable(mockCd).call{value: callValue}("");
        assertEq(address(mockCd).balance, callValue * 2);
        assertTrue(success);
    }

    function testCdFallbackMaskTrick(uint256 i, uint256 j) public {
        i = _bound(i, 0, 2 ** 248 - 1);
        uint256 a;
        uint256 b;
        /// @solidity memory-safe-assembly
        assembly {
            a := byte(0, xor(add(i, not(3)), j))
            b := xor(byte(i, shl(224, 0xffffffff)), byte(0, j))
        }
        assertEq(a, b);
    }
}
