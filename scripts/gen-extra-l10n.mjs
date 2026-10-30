import fs from 'fs';

function dartStr(s) {
  return (
    "'" +
    String(s)
      .replace(/\\/g, '\\\\')
      .replace(/'/g, "\\'")
      .replace(/\$/g, '\\$')
      .replace(/\r/g, '')
      .replace(/\n/g, '\\n') +
    "'"
  );
}

const en = JSON.parse(fs.readFileSync('scripts/missing-en.json', 'utf8'));
const hi = JSON.parse(fs.readFileSync('scripts/missing-hi.json', 'utf8'));
const kn = JSON.parse(fs.readFileSync('scripts/missing-kn.json', 'utf8'));
const ml = JSON.parse(fs.readFileSync('scripts/missing-ml.json', 'utf8'));

function block(name, obj) {
  const lines = en.map((k) => `    ${dartStr(k)}: ${dartStr(obj[k] ?? k)},`);
  return `  static const ${name} = <String, String>{\n${lines.join('\n')}\n  };`;
}

const out = `// Generated from scripts/missing-*.json. English text is the lookup key.
class ExtraL10n {
  ExtraL10n._();

${block('_hi', hi)}

${block('_kn', kn)}

${block('_ml', ml)}

  static Map<String, String> map(String lang) => switch (lang) {
        'hi' => _hi,
        'kn' => _kn,
        'ml' => _ml,
        _ => const {},
      };
}
`;

fs.writeFileSync('app/lib/l10n/extra_l10n.dart', out);
console.log('wrote extra_l10n.dart', en.length);
