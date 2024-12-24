#!/usr/bin/env node
const { genSectionRegex, readSync, writeAndFmtSync, normalizeNewlines, hexNoPrefix } = require('./common.js');

async function main() {
  const srcPath = 'src/utils/SafeCastLib.sol';
  let src = readSync(srcPath);

  const genUint256ToUintXCastDef = i => {
    const n = i * 8;
    let s = '/// @dev Casts `x` to a uint' + n + '. Reverts on overflow.\n'
    s += 'function toUint' + n + '(uint256 x) internal pure returns (uint' + n + ') {';
    s += 'if (x >= 1 << ' + n + ') _revertOverflow();'
    s += 'return uint' + n + '(x);}\n';
    return s;
  };

  const genInt256ToIntXCastDef = i => {
    const n = i * 8;
    const m = n - 1;
    let s = '/// @dev Casts `x` to a int' + n + '. Reverts on overflow.\n'
    s += 'function toInt' + n + '(int256 x) internal pure returns (int' + n + ') {';
    s += 'unchecked {';
    s += 'if (((1 << ' + m + ') + uint256(x)) >> ' + n + ' == uint256(0)) return int' + n + '(x);';
    s += '_revertOverflow();}}\n';
    return s;
  };

  const genUInt256ToIntXCastDef = i => {
    const n = i * 8;
    const m = n - 1;
    let s = '/// @dev Casts `x` to a int' + n + '. Reverts on overflow.\n'
    s += 'function toInt' + n + '(uint256 x) internal pure returns (int' + n + ') {';
    s += 'if (x >= 1 << ' + m + ') _revertOverflow();';
    s += 'return int' + n + '(int256(x));}\n';
    return s;
  };

  src = src.replace(
    genSectionRegex('UNSIGNED INTEGER SAFE CASTING OPERATIONS'),
    (m0, m1, m2) => {
      let chunks = [m1];
      for (let i = 1; i <= 31; ++i) {
        chunks.push(genUint256ToUintXCastDef(i));
      }
      chunks.push(m2);
      return normalizeNewlines(chunks.join('\n\n\n'));
    }
  ).replace(
    genSectionRegex('SIGNED INTEGER SAFE CASTING OPERATIONS'),
    (m0, m1, m2) => {
      let chunks = [m1];
      for (let i = 1; i <= 31; ++i) {
        chunks.push(genInt256ToIntXCastDef(i));
      }
      chunks.push(m2);
      return normalizeNewlines(chunks.join('\n\n\n'));
    }
  ).replace(
    genSectionRegex('OTHER SAFE CASTING OPERATIONS'),
    (m0, m1, m2) => {
      let chunks = [m1];
      for (let i = 1; i <= 31; ++i) {
        chunks.push(genUInt256ToIntXCastDef(i));
      }
      chunks.push(
        '/// @dev Casts `x` to a int256. Reverts on overflow.\n' +
        'function toInt256(uint256 x) internal pure returns (int256) {' +
        'if (int256(x) >= 0) return int256(x);'+
        '_revertOverflow();}'
      );
      chunks.push(
        '/// @dev Casts `x` to a uint256. Reverts on overflow.\n' +
        'function toUint256(int256 x) internal pure returns (uint256) {' +
        'if (x >= 0) return uint256(x);'+
        '_revertOverflow();}'
      );
      chunks.push(m2);
      return normalizeNewlines(chunks.join('\n\n\n'));
    }
  );
  writeAndFmtSync(srcPath, src);
};

main().catch(e => {
  console.error(e);
  process.exit(1);
});
