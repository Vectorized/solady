(function (global, factory) {

    "use strict";

    if (typeof module === "object" && typeof module.exports === "object") {
        module.exports = factory(global, 1);
        if (typeof exports === "object") {
            exports.LibZip = module.exports.LibZip;
        }
    } else {
        factory(global);
    }

})(typeof window !== "undefined" ? window : this, function (window, noGlobal) {

    "use strict";

    var solady = {};

    /*============================================================*/
    /*                 LibZip Calldata Operations                 */
    /*============================================================*/

    // See: (src/utils/LibZip.sol)

    var LibZip = {};

    solady.LibZip = LibZip;

    function hexString(data) {
        var isHexString = false;
        if (typeof data === "string" || data instanceof String) {
            data = data.replace(/^[\s\uFEFF\xA0]+|[\s\uFEFF\xA0]+$/g, "").toLowerCase();
            if (data.match(/^(0x)?[0-9a-f]*$/)) {
                data = data.replace(/^0x/, "");
                if (data.length % 2 > 0) {
                    throw new Error("Hex string length must be a multiple of 2.");
                } else {
                    isHexString = true;
                }
            }
        }
        if (!isHexString) {
            throw new Error("Data must be a hex string.");
        }
        return data;
    }

    function byteToString(b) {
        b = b.toString(16);
        return b.length === 1 ? "0" + b : b;
    }

    /**
     * Compresses hex encoded calldata.
     * @param {string} data A hex encoded string representing the original data.
     * @returns {string} The compressed result as a hex encoded string.
     */
    LibZip.cdCompress = function (data) {
        data = hexString(data);
        var o = "0x";
        var z = 0;
        var y = 0;
        function pushByte(b) {
            o += byteToString(o.length < 4 * 2 + 2 ? 0xff ^ b : b);
        }
        function rle(v, d) {
            pushByte(0x00);
            pushByte(d - 1 + v * 0x80);
        }
        for (var i = 0; i < data.length; i += 2) {
            var c = parseInt(data.slice(i, i + 2), 16);
            if (c === 0x00) {
                if (y) { rle(1, y); y = 0; }
                if (++z === 0x80) { rle(0, 0x80); z = 0; }
                continue;
            }
            if (c === 0xff) {
                if (z) { rle(0, z); z = 0; }
                if (++y === 0x20) { rle(1, 0x20); y = 0; }
                continue;
            }
            if (y) { rle(1, y); y = 0; }
            if (z) { rle(0, z); z = 0; }
            pushByte(c);
        }
        if (y) { rle(1, y); y = 0; }
        if (z) { rle(0, z); z = 0; }
        return o;
    }

    /**
     * Decompresses hex encoded calldata.
     * @param {string} data A hex encoded string representing the compressed data.
     * @returns {string} The decompressed result as a hex encoded string.
     */
    LibZip.cdDecompress = function (data) {
        data = hexString(data);
        var o = "0x";
        function getByte(data, i) {
            var c = parseInt(data.slice(i, i + 2), 16);
            return i < 4 * 2 ? 0xff ^ c : c;
        }
        for (var i = 0; i < data.length; ) {
            var c = getByte(data, i);
            i += 2;
            if (c === 0x00) {
                var d = getByte(data, i);
                var s = (d & 0x7f) + 1;
                i += 2;
                var b = d < 0x80 ? 0x00 : 0xff;
                for (var j = 0; j < s; ++j) o += byteToString(b);
                continue;
            }
            o += byteToString(c);
        }
        return o;
    }

    /*============================================================*/
    /*                       ERC1967Factory                       */
    /*============================================================*/

    solady.ERC1967Factory = {
        "address": "0x0000000000006396FF2a80c067f99B3d2Ab4Df24",
        "abi": JSON.parse('[{0:[],1:"DeploymentFailed"96"SaltDoesNotStartWithCaller"96"Unauthorized"96"UpgradeFailed",2:3959790,9791],1:"AdminChanged",2:10959790,9792,9791],1:"Deployed",2:10959790,9792],1:"Upgraded",2:10},{0:[{90],1:"adminOf",12:[{9199{0:[{90,{91],1:"changeAdmin",12:[],13:"nonpayable",2:15},{0:[{92,{91],1:"deploy",12:[{9098,{0:[{92,{91,{94],1:"deployAndCall",12:[{9098,{0:[{92,{91,{93],1:"deployDeterministic",12:[{9098,{0:[{92,{91,{93,{94],1:"deployDeterministicAndCall",12:[{9098,{0:[],1:"initCodeHash",12:[{6:19,1:"result",2:19}99{0:[{93],1:"predictDeterministicAddress",12:[{6:7,1:"predicted",2:7}99{0:[{90,{92],1:"upgrade",12:[98,{0:[{90,{92,{94],1:"upgradeAndCall",12:[98]'.replace(/9\d/g, function (m) { return ["6:7,1:8,2:7}","6:7,1:9,2:7}","6:7,1:11,2:7}","6:19,1:20,2:19}","6:17,1:18,2:17}","},{4:false,0:[",",2:3},{0:[],1:","{5:true,","],13:16,2:15}","],13:14,2:15},"][m-90] }).replace(/\d+/g, function (m) { return '"' + ("inputs,name,type,error,anonymous,indexed,internalType,address,proxy,admin,event,implementation,outputs,stateMutability,view,function,payable,bytes,data,bytes32,salt".split(",")[~~m]) + '"' }))
    }

    /*--------------------------- END ----------------------------*/
    
    if (typeof define === "function" && define.amd) {
        define("solady", [], function () { return solady });
    }

    if (!noGlobal) {
        window.solady = solady;
    }

    return solady;
});
