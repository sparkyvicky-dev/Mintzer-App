import fs from 'fs';

const en = JSON.parse(fs.readFileSync('scripts/missing-en.json', 'utf8'));
for (const lang of ['hi', 'kn', 'ml']) {
  const obj = JSON.parse(fs.readFileSync(`scripts/missing-${lang}.json`, 'utf8'));
  const keys = Object.keys(obj);
  const missing = en.filter((k) => !(k in obj));
  const extra = keys.filter((k) => !en.includes(k));
  let same = 0;
  for (const k of en) if (obj[k] === k && k.length > 3 && /[A-Za-z]{4}/.test(k)) same++;
  console.log(lang, 'keys', keys.length, 'missing', missing.length, 'extra', extra.length, 'unchanged-latin', same);
  if (missing.length) console.log(' missing sample', missing.slice(0, 5));
}
