#!/usr/bin/env node
const { genSectionRegex, readSync, writeAndFmtSync, normalizeNewlines, hexNoPrefix } = require('./common.js');

async function main() {
  const srcPath = 'src/utils/EnumerableMapLib.sol';
  const maxDepth = 14;
  let src = readSync(srcPath);

  const capitalize = s => s.charAt(0).toUpperCase() + s.slice(1);
  
  const mapType = (f, t) => capitalize(f) + 'To' + capitalize(t) + 'Map';

  const crossForEach = (a, fn) => a.forEach(x => a.forEach(y => fn(x, y)));

  const genStructDef = (f, t) => {
    return '/// @dev A enumerable map of `' + f + '` to `' + t + '`.\n' +
      'struct ' + mapType(f, t) + '{\n' +
      'EnumerableSetLib.' + capitalize(f) + 'Set _keys;\n' +
      'mapping(' + f + ' => ' + t + ') _values;\n}\n\n';
  };

  const genGettersAndSettersDef = (f, t) => {
    const mt = mapType(f, t);
    let s = '/// @dev Adds a key-value pair to the map, or updates the value for an existing key.\n';
    s += '/// Returns true if `key` was added to the map, that is if it was not already present.\n';
    s += 'function set(' + mt + ' storage map, ' + f + ' key, ' + t + ' value) internal returns (bool) {\n';
    s += 'map._values[key] = value;\nreturn EnumerableSetLib.add(map._keys, key);\n}\n\n';

    s += '/// @dev Removes a key-value pair from the map.\n';
    s += '/// Returns true if `key` was removed from the map, that is if it was present.\n';
    s += 'function remove(' + mt + ' storage map, ' + f + ' key) internal returns (bool) {\n';
    s += 'delete map._values[key];\nreturn EnumerableSetLib.remove(map._keys, key);\n}\n\n';

    s += '/// @dev Returns true if the key is in the map.\n';
    s += 'function contains(' + mt + ' storage map, ' + f + ' key) internal view returns (bool) {\n';
    s += 'return EnumerableSetLib.contains(map._keys, key);\n}\n\n';

    s += '/// @dev Returns the number of key-value pairs in the map.\n';
    s += 'function length(' + mt + ' storage map) internal view returns (uint256) {\n';
    s += 'return EnumerableSetLib.length(map._keys);\n}\n\n';

    s += '/// @dev Returns the key-value pair at index `i`. Reverts if `i` is out-of-bounds.\n';
    s += 'function at(' + mt + ' storage map, uint256 i)'
    s += 'internal view returns (' + f + ' key, ' + t + ' value) {\n';
    s += 'value = map._values[key = EnumerableSetLib.at(map._keys, i)];\n}\n\n';

    s += '/// @dev Tries to return the value associated with the key.\n';
    s += 'function tryGet(' + mt + ' storage map, ' + f + ' key)'
    s += 'internal view returns (bool exists, ' + t + ' value) {\n';
    s += 'exists = (value = map._values[key]) != ' + t + '(0) || contains(map, key);\n}\n\n';

    s += '/// @dev Returns the value for the key. Reverts if the key is not found.\n';
    s += 'function get(' + mt + ' storage map, ' + f + ' key)'
    s += 'internal view returns (' + t + ' value)\n{\n';
    s += 'if ((value = map._values[key]) == ' + t + '(0)) if (!contains(map, key)) _revertNotFound();\n}\n\n';

    s += '/// @dev Returns the keys. May run out-of-gas if the map is too big.\n';
    s += 'function keys(' + mt + ' storage map) internal view returns (' + f + '[] memory) {\n';
    s += 'return EnumerableSetLib.values(map._keys);\n}\n\n';
    return s;
  }

  const types = ['bytes32', 'uint256', 'address'];

  src = src.replace(
    genSectionRegex('STRUCTS'),
    (m0, m1, m2) => {
      let chunks = [m1];
      crossForEach(types, (f, t) => chunks.push(genStructDef(f, t)));
      chunks.push(m2);
      return normalizeNewlines(chunks.join('\n\n\n'));
    }
  ).replace(
    genSectionRegex('GETTERS / SETTERS'),
    (m0, m1, m2) => {
      let chunks = [m1];
      crossForEach(types, (f, t) => chunks.push(genGettersAndSettersDef(f, t)));
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
