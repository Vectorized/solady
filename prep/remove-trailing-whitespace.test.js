const assert = require('node:assert/strict');
const { execFileSync } = require('node:child_process');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { test } = require('node:test');

test('removes trailing spaces and tabs from Solidity sources', t => {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), 'solady-whitespace-'));
  t.after(() => fs.rmSync(root, { recursive: true, force: true }));
  fs.mkdirSync(path.join(root, 'src', 'nested'), { recursive: true });
  const source = path.join(root, 'src', 'nested', 'Example.sol');
  fs.writeFileSync(source, 'contract Example {  \n    uint256 value;\t\t\n}\n');
  const other = path.join(root, 'src', 'notes.txt');
  fs.writeFileSync(other, 'keep these spaces  \n');
  const script = path.join(__dirname, 'remove-trailing-whitespace.js');
  execFileSync(process.execPath, [script], { cwd: root });
  assert.equal(fs.readFileSync(source, 'utf8'), 'contract Example {\n    uint256 value;\n}\n');
  assert.equal(fs.readFileSync(other, 'utf8'), 'keep these spaces  \n');
  const cleaned = fs.readFileSync(source, 'utf8');
  execFileSync(process.execPath, [script], { cwd: root });
  assert.equal(fs.readFileSync(source, 'utf8'), cleaned);
});
