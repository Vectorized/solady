#!/usr/bin/env node
const fs = require('fs');
const path = require('path');
const { spawnSync, execSync } = require('child_process');

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
  const tmpDir = path.join(__dirname, 'out', ('__t' + Math.random()).replace(/\./g, '_'));
  writeSync(
    path.resolve(path.join(tmpDir, 'foundry.toml')),
    fs.readFileSync(path.resolve('foundry.toml'), 'utf8')
    .replace(/line_length\s*=\s*\d+/g, 'line_length = ' + lineLength)
  );
  fs.copyFileSync(srcPath, path.join(tmpDir, 'x.sol'));
  execSync('forge fmt x.sol', { cwd: tmpDir, stdio: 'inherit' });
  const content = fs.readFileSync(path.join(tmpDir, 'x.sol'), 'utf8');
  fs.rmSync(tmpDir, { recursive: true, force: true });
  return content;
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
