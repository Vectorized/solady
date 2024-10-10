#!/usr/bin/env node
const fs = require('fs');
const path = require('path');

async function main() {
  const walkSync = (dir, callback) => {
    fs.readdirSync(dir).forEach(file => {
      var srcPath = path.join(dir, file);
      const stats = fs.statSync(srcPath);
      if (stats.isDirectory()) {
        walkSync(srcPath, callback);
      } else if (stats.isFile()) {
        callback(srcPath, stats);
      }
    });
  };

  const libraryTestRegex = /library\s+([A-Za-z0-9]+)\s+\{/;
  const structTestRegex = /struct\s+[A-Za-z0-9]+\s+\{/;
  const structSectionRegex = /\s*\/\*\S+?\*\/\s*\/\*\s+STRUCTS?\s+\*\/\s*\/\*\S+?\*\/([\s\S]+?struct\s+[A-Za-z0-9]+\s+\{[\s\S]+?\})+/;
  const pragmaSolidityRegex = /pragma\s+solidity\s+\^0\.8\.\d+;/;
  const structStartRegex = /struct\s+([A-Za-z0-9]+)\s+\{[\s\S]+?\}/g;
  const uriRegex = /(https\:\/\/\S+?\/solady\/\S+?\/)([A-Za-z0-9]+\.sol)/;
  const localImportRegex = /(import\s[\s\S]*?["'])\.\/([\s\S]+["'])/g;
  
  ['src/utils'].forEach(dir => {
    walkSync(dir, srcPath => {
      if (srcPath.match(/\.sol$/i) && !(/\/g\//).test(srcPath)) {
        var src = fs.readFileSync(srcPath, { encoding: 'utf8', flag: 'r' });
        if (!(libraryTestRegex.test(src) && structTestRegex.test(src))) return;
        
        var structSectionText = '';
        src = src.replace(structSectionRegex, m => {
          structSectionText = m.replace(/\n    /g, '\n');
          return '';
        });
        var libraryStartMatch;
        if (!(libraryStartMatch = libraryTestRegex.exec(src))) return;

        var globalUsingsText = '';
        for (var structStartMatch; structStartMatch = structStartRegex.exec(structSectionText); ) {
          globalUsingsText += 'using ' + libraryStartMatch[1] + ' for ' + structStartMatch[1] + ' global;';
        }
        if (globalUsingsText == '') return;
        src = src.replace(
          pragmaSolidityRegex, 
          'pragma solidity ^0.8.13;' + structSectionText + '\n' + globalUsingsText
        ).replace(uriRegex, '$1g/$2').replace(localImportRegex, '$1../$2');

        const dstPath = srcPath.replace(/([A-Za-z0-9]+\.sol)/, 'g/$1');
        fs.mkdirSync(path.dirname(dstPath), { recursive: true });
        fs.writeFileSync(dstPath, src);  
      }
    });
  });
}

main().catch(e => {
  console.error(e);
  process.exit(1);
});
