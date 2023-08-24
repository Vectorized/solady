// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/SoladyTest.sol";
import {JSONParserLib} from "../src/utils/JSONParserLib.sol";

contract JSONParserLibTest is SoladyTest {
    using JSONParserLib for *;

    function testParseNumber() public {
        JSONParserLib.Item memory item;
        JSONParserLib.Item[] memory children;
        assertEq(item.value(), "");
        assertTrue(item.isUndefined());
        // console.log(JSONParserLib.parse("  true  ").value());
        // console.log(JSONParserLib.parse("  true").value());
        // console.log(JSONParserLib.parse("  false  ").value());
        // console.log(JSONParserLib.parse("  false").value());
        // console.log(JSONParserLib.parse("  null  ").value());
        // console.log(JSONParserLib.parse("  null").value());

        // item = JSONParserLib.parse('[1,2,[3,4],[5,6],7,"hehe", true]');
        // children = item.children();
        // for (uint256 i; i < children.length; ++i) {
        //     console.log(children[i].index());
        //     // console.log(children[i].value());
        // }

        // item = JSONParserLib.parse('{"a":"A","b"  :  "B"}');
        // children = item.children();
        // for (uint256 i; i < children.length; ++i) {
        //     console.log(children[i].key());
        //     console.log(children[i].value());
        // }

        // console.log(JSONParserLib.parse("  01234567890  ").value());
        console.log(JSONParserLib.parse("  -1.234567890e+22  ").value());
        console.log(JSONParserLib.parse("  -1.234567890e-22  ").value());
        console.log(JSONParserLib.parse("  -1.234567890e22  ").value());
        console.log(JSONParserLib.parse("  1234567890  ").value());
        console.log(JSONParserLib.parse("  123  ").value());
        console.log(JSONParserLib.parse("  1  ").value());
        // console.log(JSONParserLib.parse("    ").value());

        console.log(JSONParserLib.parse(' "aabbcc"  ').value());

        string memory s =
            '{"animation_url":"","artist":"Daniel Allan","artwork":{"mimeType":"image/gif","uri":"ar://J5NZ-e2NUcQj1OuuhpTjAKtdW_nqwnwo5FypF_a6dE4","nft":null},"attributes":[{"trait_type":"Criteria","value":"Song Edition"}],"bpm":null,"credits":null,"description":"Criteria is an 8-track project between Daniel Allan and Reo Cragun.\n\nA fusion of electronic music and hip-hop - Criteria brings together the best of both worlds and is meant to bring web3 music to a wider audience.\n\nThe collection consists of 2500 editions with activations across Sound, Bonfire, OnCyber, Spinamp and Arpeggi.","duration":105,"external_url":"https://www.sound.xyz/danielallan/criteria","genre":"Pop","image":"ar://J5NZ-e2NUcQj1OuuhpTjAKtdW_nqwnwo5FypF_a6dE4","isrc":null,"key":null,"license":null,"locationCreated":null,"losslessAudio":"","lyrics":null,"mimeType":"audio/wave","nftSerialNumber":11,"name":"Criteria #11","originalReleaseDate":null,"project":null,"publisher":null,"recordLabel":null,"tags":null,"title":"Criteria","trackNumber":1,"version":"sound-edition-20220930","visualizer":null}';
        item = JSONParserLib.parse(s);
        children = item.children();
        for (uint256 i; i < children.length; ++i) {
            console.log(children[i].key());
        }
        assertEq(item.getType(), JSONParserLib.TYPE_OBJECT);
        assertTrue(item.isObject());
        console.log(item.children()[0].parent().value());
    }
}
