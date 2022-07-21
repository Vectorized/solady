#!/usr/bin/env node
const fs = require('fs');
const path = require('path');

async function main() {
  const walkSync = (dir, callback) => {
    fs.readdirSync(dir).forEach(file => {
      var filepath = path.join(dir, file);
      const stats = fs.statSync(filepath);
      if (stats.isDirectory()) {
        walkSync(filepath, callback);
      } else if (stats.isFile()) {
        callback(filepath, stats);
      }
    });
  };

  const replaceImports = source => {
    return source
      .replace(/pragma solidity ([>=^0-9\.]+);/g, 'pragma solidity ^0.8.4;')
      .replace('// SPDX-License-Identifier: AGPL-3.0-only', '// SPDX-License-Identifier: MIT')
      .replace('/// @author Solmate', '/// @author Modified from Solmate')
      .replace(/\/rari-capital\//i, '/transmissions11/');
  };

  const walkAndReplace = dirPath => {
    walkSync(dirPath, filepath => {
      if (filepath.match(/\.sol$/i)) {
        const source = fs.readFileSync(filepath, { encoding: 'utf8', flag: 'r' });
        fs.writeFileSync(filepath, replaceImports(source));
      }
    });
  };

  walkAndReplace('src');
  walkAndReplace('test');
}

main().catch(e => {
  console.error(e);
  process.exit(1);
});
