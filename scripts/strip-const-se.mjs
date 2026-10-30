import fs from 'fs';
import path from 'path';

function walk(d, out = []) {
  for (const n of fs.readdirSync(d)) {
    const p = path.join(d, n);
    if (fs.statSync(p).isDirectory()) walk(p, out);
    else if (p.endsWith('.dart')) out.push(p);
  }
  return out;
}

let n = 0;
for (const file of walk('app/lib')) {
  const lines = fs.readFileSync(file, 'utf8').split(/\n/);
  let changed = false;
  for (let i = 0; i < lines.length; i++) {
    if (!lines[i].includes('S.e(') || !lines[i].includes('const')) continue;
    const before = lines[i];
    lines[i] = lines[i].replace(/\bconst\b/, '');
    if (lines[i] !== before) {
      changed = true;
      n++;
    }
  }
  if (changed) fs.writeFileSync(file, lines.join('\n'));
}
console.log('stripped const on', n, 'lines');
