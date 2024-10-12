#!/usr/bin/env node
const fs = require('fs');
const path = require('path');

async function main() {
  const walkSync = (dir, callback) => {
    fs.readdirSync(dir).forEach(file => {
      const srcPath = path.join(dir, file);
      const stats = fs.statSync(srcPath);
      stats.isDirectory() ? walkSync(srcPath, callback) : stats.isFile() && callback(srcPath, stats);
    });
  };

  ['src/utils'].forEach(dir => {
    walkSync(dir, srcPath => {
      if (!srcPath.match(/\.sol$/i) || srcPath.match(/\/g\//)) return;

      let src = fs.readFileSync(srcPath, { encoding: 'utf8', flag: 'r' });
      const libraryStartMatch = src.match(/library\s+([A-Za-z0-9]+)\s+\{/);
      if (!libraryStartMatch) return;
      
      let structsSrc = '', usings = [];
      src = src.replace(
        /\s*\/\*\S+?\*\/\s*\/\*\s+STRUCTS?\s+\*\/\s*\/\*\S+?\*\/([\s\S]+?struct\s+[A-Za-z0-9]+\s+\{[\s\S]+?\})+/, 
        m => (structsSrc = m, '')
      );

      for (let m, r = /struct\s+([A-Za-z0-9]+)\s+\{/g; m = r.exec(structsSrc); ) {
        usings.push('using ' + libraryStartMatch[1] + ' for ' + m[1] + ' global;');
      }
      if (usings.length === 0 || structsSrc === '') return;

      const dstPath = srcPath.replace(/([A-Za-z0-9]+\.sol)/, 'g/$1');
      console.log(dstPath);
      fs.mkdirSync(path.dirname(dstPath), { recursive: true });
      fs.writeFileSync(
        dstPath, 
        src.replace(
          /pragma\s+solidity\s+\^0\.8\.\d+;/, 
          [
            'pragma solidity ^0.8.13;',
            '// This file is auto-generated.',
            structsSrc.replace(/\n    /g, '\n').replace(/^\s*\n+|\n+\s*$/g, ''),
            usings.join('\n').replace(/^\s*\n+|\n+\s*$/g, '')
          ].join('\n\n')
        )
        .replace(/(https\:\/\/\S+?\/solady\/\S+?\/)([A-Za-z0-9]+\.sol)/, '$1g/$2')
        .replace(/(import\s[\s\S]*?["'])\.\/([\s\S]+["'])/g, '$1../$2')
        .replace(/(library\s+([A-Za-z0-9]+)\s+\{\n)\n*/, '$1')
      );
    });
  });
};

main().catch(e => {
  console.error(e);
  process.exit(1);
});
