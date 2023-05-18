var solady = require("./solady.js");

function test(msg, fn) {
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

test("Calldata compress / decompress.", function () {
    function randomData() {
        var n = ~~(Math.random() * 2000);
        var s = Math.random() < 0.5 ? "" : "0x";
        var g = Math.random() < 0.5 ? 0.45 : 0.99;
        var h = Math.random() < 0.5 ? 0.90 : 0.9999;
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

    var totalDataLength = 0;
    var totalCompressedLength = 0;
    for (var t = 0; t < 10000; ++t) {
        var data = randomData();
        var compressed = solady.LibZip.cdCompress(data);
        var decompressed = solady.LibZip.cdDecompress(compressed);
        totalDataLength += data.length;
        totalCompressedLength += compressed.length;
        assertEq(compressed.slice(0, 2), "0x");
        assertEq(decompressed.slice(0, 2), "0x");
        assertEq(decompressed.replace(/^0x/, ""), data.toLowerCase().replace(/^0x/, ""));
    }
    assert(totalCompressedLength < totalDataLength, "Compress not working as intended.");
});

test("ERC1967Factory ABI and address.", function () {
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
