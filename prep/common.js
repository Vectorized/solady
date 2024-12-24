#!/usr/bin/env node
const fs = require('fs');
const path = require('path');
const { spawnSync } = require('child_process');

const normalizeNewlines = s => s.replace(/\n(\n\s*)+/g, '\n\n');

const hexNoPrefix = x => x.toString(16).replace(/^0[xX]/, '');

const readSync = srcPath => 
  fs.existsSync(srcPath) ? fs.readFileSync(srcPath, { encoding: 'utf8', flag: 'r' }) : '';

const runCommandSync = (command, args) => {
  const result = spawnSync(command, args, { encoding:'utf-8' });
  if (result.error) {
    console.error('Error executing command:', result.error.message);
  } else {
    return result.stdout;
  }
};

const hasAnyPathSequence = (srcPath, paths) => {
  const d = '\0', norm = p => d + path.normalize(p).split(path.sep).join(d) + d;
  return paths.some(p => norm(srcPath).indexOf(norm(p)) !== -1);
};

const genSectionRegex = name =>
  new RegExp(
    '(\\s*\\/\\*\\S+?\\*\\/\\s*\\/\\*\\s+' +
    name.replace(/[.*+?^${}()|[\]\\]/g, '\\$&') +
    '\\s+\\*\\/\\s*\\/\\*\\S+?\\*\\/)[\\s\\S]+?(\\/\\*\\S+?\\*\\/)'
  );

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

const readSolWithLineLengthSync = (srcPath, lineLength) => {
  const withModifiedToml = callback => {
    const originalFile = path.resolve('foundry.toml');
    const backupFile = path.resolve('__tmp_foundry.toml');
    try {
      fs.copyFileSync(originalFile, backupFile);
      let content = fs.readFileSync(originalFile, 'utf8');
      content = content.replace(/line_length\s*=\s*\d+/g, 'line_length = ' + lineLength);
      fs.writeFileSync(originalFile, content, 'utf8');
      return callback();
    } catch (err) {
    } finally {
      if (fs.existsSync(backupFile)) {
        fs.copyFileSync(backupFile, originalFile);
        fs.unlinkSync(backupFile);
      }
    }
  };
  return withModifiedToml(() => {
    const tempFile = '__tmp.sol';
    fs.copyFileSync(srcPath, tempFile);
    runCommandSync('forge', ['fmt', tempFile]);
    let content = fs.readFileSync(tempFile, 'utf8');
    fs.unlinkSync(tempFile);
    return content;
  });
};

module.exports = {
  genSectionRegex,
  hexNoPrefix,
  hasAnyPathSequence,
  normalizeNewlines,
  readSync,
  runCommandSync,
  writeSync,
  writeAndFmtSync,
  walkSync,
  forEachWalkSync,
  readSolWithLineLengthSync
};
