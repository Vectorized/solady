var solady = require("./solady.js");

function test(msg, fn) {
    msg = msg.replace(/^[\s\uFEFF\xA0]+|[\s\uFEFF\xA0]+$/g, "").replace(/([^\.])$/, "$1.");
    try {
        fn();
        console.log("\x1b[32m[PASS]\x1b[0m", msg);
    } catch (e) {
        process.exitCode = 1;
        console.error("\x1b[31m[FAIL]\x1b[0m", msg);
        console.error(e.stack);
    }
}

function assert(cond, msg) {
    if (!cond) throw new Error(msg);
}

function assertEq(a, b) {
    assert(a === b, "Assertion failed!\n    Expected: " + b + "\n    Actual: " + a);
}

function expectRevert(fn) {
    var hasRevert = false;
    try { fn() } catch (e) { hasRevert = true }
    assert(hasRevert, "Revert expected.\n" + fn);
}

test("Calldata compress / decompress.", function() {
    function randomData() {
        var n = ~~(Math.random() * 2000);
        var s = Math.random() < 0.5 ? "" : "0x";
        var g = Math.random() < 0.5 ? 0.45 : (Math.random() ? 0.99 : 0.999);
        var h = g + 0.5 * (1.0 - g);
        for (var i = 0; i < n; ++i) {
            var r = Math.random();
            if (r < g) {
                s += "00";
            } else if (r < h) {
                s += "ff";
            } else {
                var b = ((Math.random() * 0x100) & 0xff).toString(16);
                s += b.length === 1 ? "0" + b : b;
            }
        }
        return Math.random() < 0.5 ? s.toUpperCase() : s.toLowerCase();
    }

    function padRandomWhitespace(data) {
        var before = "";
        var after = "";
        while (Math.random() < 0.5) before += Math.random() ? "\t" : " ";
        while (Math.random() < 0.5) after += Math.random() ? "\t" : " ";
        return before + data + after;
    }

    var totalDataLength = 0;
    var totalCompressedLength = 0;
    for (var t = 0; t < 10000; ++t) {
        var data = randomData();
        var compressed = solady.LibZip.cdCompress(padRandomWhitespace(data));
        var decompressed = solady.LibZip.cdDecompress(padRandomWhitespace(compressed));
        totalDataLength += data.length;
        totalCompressedLength += compressed.length;
        assertEq(compressed.slice(0, 2), "0x");
        assertEq(decompressed.slice(0, 2), "0x");
        assertEq(decompressed.replace(/^0x/, ""), data.toLowerCase().replace(/^0x/, ""));
    }
    assert(totalCompressedLength < totalDataLength, "Compress not working as intended.");

    assertEq(solady.LibZip.cdCompress(""), "0x");
    assertEq(solady.LibZip.cdCompress("0x"), "0x");
    assertEq(solady.LibZip.cdDecompress(""), "0x");
    assertEq(solady.LibZip.cdDecompress("0x"), "0x");

    function checkRevertOnInvalidInputs(fn) {
        expectRevert(function () { fn("hehe") });
        expectRevert(function () { fn("0xa") });
        expectRevert(function () { fn("0xas") });
        expectRevert(function () { fn(123) });
        expectRevert(function () { fn(false) });
        expectRevert(function () { fn(null) });
    }

    checkRevertOnInvalidInputs(solady.LibZip.cdCompress);
    checkRevertOnInvalidInputs(solady.LibZip.cdDecompress);
});

test("Calldata compress", function() {
    var data = "0xac9650d80000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000160000000000000000000000000000000000000000000000000000000000000022000000000000000000000000000000000000000000000000000000000000002a000000000000000000000000000000000000000000000000000000000000000a40c49ccbe000000000000000000000000000000000000000000000000000000000005b70e00000000000000000000000000000000000000000000000000000dfc79825feb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000645c48a7000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000084fc6f7865000000000000000000000000000000000000000000000000000000000005b70e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ffffffffffffffffffffffffffffffff00000000000000000000000000000000ffffffffffffffffffffffffffffffff00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004449404b7c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000001f1cdf1a632eaaab40d1c263edf49faf749010a1000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000064df2ab5bb0000000000000000000000007f5c764cbc14f9669b88837ca1490cca17c3160700000000000000000000000000000000000000000000000000000000000000000000000000000000000000001f1cdf1a632eaaab40d1c263edf49faf749010a100000000000000000000000000000000000000000000000000000000";
    var expected = "0x5369af27001e20001e04001e80001d0160001d0220001d02a0001ea40c49ccbe001c05b70e00190dfc79825feb005b645c48a7003a84fc6f7865001c05b70e002f008f000f008f003a4449404b7c002b1f1cdf1a632eaaab40d1c263edf49faf749010a1003a64df2ab5bb000b7f5c764cbc14f9669b88837ca1490cca17c31607002b1f1cdf1a632eaaab40d1c263edf49faf749010a1001b";
    assertEq(solady.LibZip.cdCompress(data), expected);
});

test("ERC1967Factory ABI and address", function() {
    function hashFnv32a(s) {
        var h = 0x811c9dc5;
        for (var i = 0; i < s.length; i++) {
            h ^= s.charCodeAt(i);
            h += (h << 1) + (h << 4) + (h << 7) + (h << 8) + (h << 24);
        }
        return h >>> 0;
    }
    assertEq(hashFnv32a(JSON.stringify(solady.ERC1967Factory.abi)), 1277805820);
    assertEq(solady.ERC1967Factory.address, "0x0000000000006396FF2a80c067f99B3d2Ab4Df24");
});
