import fs from 'fs';

const en = JSON.parse(fs.readFileSync('scripts/missing-en.json', 'utf8'));
const extra = [];

const format = fs.readFileSync('app/lib/util/format.dart', 'utf8');
for (const m of format.matchAll(/'((?:\\'|[^'])*)'/g)) {
  const s = m[1].replace(/\\'/g, "'");
  if (s.length > 8 && /[A-Za-z]/.test(s)) extra.push(s);
}

const faq = fs.readFileSync('app/lib/mock/faq_data.dart', 'utf8');
for (const m of faq.matchAll(/title: '((?:\\'|[^'])*)'|q: '((?:\\'|[^'])*)'|a: '((?:\\'|[^'])*)'/g)) {
  extra.push((m[1] || m[2] || m[3]).replace(/\\'/g, "'"));
}

const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
const all = [...new Set([...en, ...extra, ...months])].sort();
fs.writeFileSync('scripts/missing-en.json', JSON.stringify(all, null, 2));
console.log('total', all.length);
