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
    var LibZip = solady.LibZip;

    function randomData() {
        var n = ~~(Math.random() * 2000);
        var s = "0x";
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
        return s;
    }

    for (var t = 0; t < 10000; ++t) {
        var data = randomData();
        var compressed = LibZip.cdCompress(data);
        var decompressed = LibZip.cdDecompress(compressed);
        assertEq(decompressed, data);
    }
});
