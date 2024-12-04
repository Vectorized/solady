#!/usr/bin/env node
const fs = require('fs');
const path = require('path');
const { spawnSync } = require('child_process');

const readSync = (srcPath) => {
  return fs.readFileSync(srcPath, { encoding: 'utf8', flag: 'r' });
};

const runCommandSync = (command, args) => {
  const result = spawnSync(command, args, { encoding:'utf-8' });
  if (result.error) {
    console.error('Error executing command:', result.error.message);
  } else {
    return result.stdout;
  }
};

const writeSync = (srcPath, src) => {
  const dir = path.dirname(srcPath);
  if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
  fs.writeFileSync(srcPath, src);
};

const writeAndFmtSync = (srcPath, src) => {
  writeSync(srcPath, src);
  runCommandSync('forge', ['fmt', srcPath]);
};

const walkSync = (dir, callback) => {
  fs.readdirSync(dir).forEach(file => {
    const srcPath = path.join(dir, file);
    const stats = fs.statSync(srcPath);
    stats.isDirectory() ? walkSync(srcPath, callback) : stats.isFile() && callback(srcPath, stats);
  });
};

const forEachWalkSync = (dirs, callback) => {
  dirs.forEach(dir => walkSync(dir, callback));
};

module.exports = {
  readSync,
  runCommandSync,
  writeSync,
  writeAndFmtSync,
  walkSync,
  forEachWalkSync
};
