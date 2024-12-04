#!/usr/bin/env node
const { readSync, writeAndFmtSync } = require('./common.js');

async function main() {
  const srcPath = 'src/utils/EfficientHashLib.sol';
  const maxDepth = 15;
  let src = readSync(srcPath);

  const hexNoPrefix = x => x.toString(16).replace(/^0[xX]/, '');

  const genHashDef = (t, n) => {
    let s = '/// @dev Returns `keccak256(abi.encode(';
    let a = [];
    for (let i = 0; i < n; ++i) a.push(t + ' v' + i);
    let b = (n > 4 ? [a[0], '..', a[n - 1]] : a).join(', ');
    s += b.replace(new RegExp(t + ' ', 'g'), '');
    s += '))`.\nfunction hash(' + a.join(', ');
    s += ') internal pure returns (bytes32 result) {\n';
    s += '/// @solidity memory-safe-assembly\nassembly {\n';
    if (n == 1) {
      s += 'mstore(0x00, v0)\nresult := keccak256(0x00, 0x20)}}\n'
    } else if (n == 2) {
      s += 'mstore(0x00, v0)\nmstore(0x20, v1)\nresult := keccak256(0x00, 0x40)}}\n'
    } else if (n <= 14) {
      s += 'let m := mload(0x40)\nmstore(m, v0)\n';
      for (let i = 1; i < n; ++i) {
        s += 'mstore(add(m, 0x' + hexNoPrefix(i << 5) + '), v' + i + ')\n';
      }
      s += 'result := keccak256(m, 0x' + hexNoPrefix(n << 5) +')}}\n';
    } else {
      s += 'mstore(mload(0x40), v0)\n';
      for (let i = 1; i < n; ++i) {
        s += 'mstore(add(mload(0x40), 0x' + hexNoPrefix(i << 5) + '), v' + i + ')\n';
      }
      s += 'result := keccak256(mload(0x40), 0x' + hexNoPrefix(n << 5) +')}}\n';
    }
    return s;
  }
  src = src.replace(
    /(\s*\/\*\S+?\*\/\s*\/\*\s+MALLOC\-LESS HASHING OPERATIONS\s+\*\/\s*\/\*\S+?\*\/)[\s\S]+?(\/\*\S+?\*\/)/, 
    (m0, m1, m2) => {
      let hashDefs = [];
      for (let i = 1; i <= maxDepth; ++i) {
        hashDefs.push(genHashDef('bytes32', i));
        hashDefs.push(genHashDef('uint256', i));
      }
      return m1 + '\n' + hashDefs.join('\n') + '    ' + m2;
    }
  );
  writeAndFmtSync(srcPath, src);
};

main().catch(e => {
  console.error(e);
  process.exit(1);
});
