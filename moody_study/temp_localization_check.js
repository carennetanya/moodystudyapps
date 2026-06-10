const fs = require('fs');
const path = require('path');
const root = path.join(process.cwd(), 'lib');
const walk = dir => {
  let res = [];
  for (const ent of fs.readdirSync(dir, { withFileTypes: true })) {
    const p = path.join(dir, ent.name);
    if (ent.isDirectory()) res = res.concat(walk(p));
    else if (p.endsWith('.dart')) res.push(p);
  }
  return res;
};
const files = walk(root);
const re = /(Text\(|title:\s*|label:\s*|hintText:\s*|subtitle:\s*|helperText:\s*|errorText:\s*|content:\s*)(['"])([^'\"]*[A-Za-z][^'\"]*)\2/;
const results = [];
for (const file of files) {
  const lines = fs.readFileSync(file, 'utf8').split(/\r?\n/);
  lines.forEach((line, i) => {
    const m = line.match(re);
    if (m) {
      results.push({ file, line: i + 1, text: m[3].trim(), snippet: line.trim() });
    }
  });
}
results.sort((a, b) => a.file.localeCompare(b.file) || a.line - b.line);
for (const r of results) {
  console.log(`${r.file}:${r.line}: ${r.snippet}`);
}
console.log('TOTAL', results.length);
