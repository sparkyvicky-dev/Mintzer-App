import fs from 'fs';
import vm from 'vm';

const src = fs
  .readFileSync('assets/mockups/mintzer-i18n.js', 'utf8')
  .replace('})(window);', '})(globalThis);');
const ctx = { globalThis: {} };
vm.createContext(ctx);
vm.runInContext(src, ctx);
const i18n = ctx.globalThis.MINTZER_I18N;

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

function mapBlock(name, obj) {
  const lines = Object.keys(i18n.en).map((k) => `    '${k}': ${dartStr(obj[k])},`);
  return `  static const ${name} = <String, String>{\n${lines.join('\n')}\n  };`;
}

const out = `// Generated from assets/mockups/mintzer-i18n.js. Do not edit by hand.
// Regenerate: node scripts/gen-l10n.mjs

class DemoL10n {
  DemoL10n._();

${mapBlock('_en', i18n.en)}

${mapBlock('_hi', i18n.hi)}

${mapBlock('_kn', i18n.kn)}

${mapBlock('_ml', i18n.ml)}

  static Map<String, String> map(String lang) => switch (lang) {
        'hi' => _hi,
        'kn' => _kn,
        'ml' => _ml,
        _ => _en,
      };
}
`;

fs.writeFileSync('app/lib/l10n/demo_l10n.dart', out);
console.log('wrote demo_l10n.dart', Object.keys(i18n.en).length, 'keys');
