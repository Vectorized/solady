#!/usr/bin/env node
const fs = require('fs');
const path = require('path');
const { spawn } = require('child_process');

async function main() {
  const srcPath = 'src/utils/EfficientHashLib.sol';
  let src = fs.readFileSync(srcPath, { encoding: 'utf8', flag: 'r' });

  const hexNoPrefix = x => x.toString(16).replace(/^0[xX]/, '');

  const runCommand = async (command, args) => {
    return new Promise((resolve, reject) => {
      const child = spawn(command, args);
      let output = '';
      child.stdout.on('data', data => output += data.toString());
      child.stderr.on('data', data => console.error(`Error: ${data}`));
      child.on('close', code => {
        if (code === 0) {
          resolve(output);
        } else {
          reject(`Process exited with code: ${code}`);
        }
      });
    });
  };

  const genHashDef = (t, n) => {
    let s = '/// @dev Returns `keccak256(abi.encode(';
    let a = [];
    for (let i = 0; i < n; ++i) a.push(t + ' value' + i);
    let b = (n > 4 ? [a[0], '..', a[n - 1]] : a).join(', ');
    s += b.replace(new RegExp(t + ' ', 'g'), '');
    s += '))`.\n    function hash(';
    s += a.join(', ');
    s += ') internal pure returns (bytes32 result) {\n';
    s += '        /// @solidity memory-safe-assembly\n';
    s += '        assembly {\n';
    if (n == 1) {
      s += 'mstore(0x00, value0)\n';
      s += 'result := keccak256(0x00, 0x20)}}\n'
    } else if (n == 2) {
      s += 'mstore(0x00, value0)\n';
      s += 'mstore(0x20, value1)\n';
      s += 'result := keccak256(0x00, 0x40)}}\n'
    } else {
      s += 'let m := mload(0x40)\n';  
      s += 'mstore(m, value0)\n';
      for (let i = 1; i < n; ++i) {
        s += 'mstore(add(m, 0x' + hexNoPrefix(i << 5) + '), value' + i + ')\n';
      }
      s += 'result := keccak256(m, 0x' + hexNoPrefix(n << 5) +')}}\n';
    }
    return s;
  }
  src = src.replace(
    /(\s*\/\*\S+?\*\/\s*\/\*\s+MALLOC\-LESS HASHING OPERATIONS\s+\*\/\s*\/\*\S+?\*\/)[\s\S]+?(\/\*\S+?\*\/)/, 
    (m0, m1, m2) => {
      let body = '\n';
      for (let i = 1; i <= 16; ++i) {
        body += genHashDef('bytes32', i) + '\n';
        body += genHashDef('uint256', i) + '\n';
      }
      return m1 + '\n' + body + '    ' + m2;
    }
  );
  fs.writeFileSync(srcPath, src);
  await runCommand('forge', ['fmt', srcPath]);
};

main().catch(e => {
  console.error(e);
  process.exit(1);
});
