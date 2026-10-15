// HISTORICAL (2026-10-15 audit evidence): these assertions reproduce the
// PRE-build-59 defects exactly as the review found them. They intentionally
// FAIL against the fixed module; the successor suites are test_emoji_slots.sh
// and test_webui.cjs. Kept unchanged as the audit's reproduction record.
//
// Review characterization tests. Assertions reproduce the reviewed behavior,
// including defects; a successful run does NOT mean the module is defect-free.
// No device, privileges, production paths, mounts, or network are used.
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const cp = require('node:child_process');
const assert = require('node:assert/strict');
const root = path.resolve(__dirname, '..');
const bash = process.env.AUDIT_BASH || 'C:/Program Files/Git/bin/bash.exe';
const read = p => fs.readFileSync(path.join(root, p), 'utf8');
const html = read('module/webroot/index.html');
const script = html.match(/<script>([\s\S]*?)<\/script>/)[1];
const work = path.join(__dirname, '.audit-work');
fs.mkdirSync(work, { recursive: true });
const results = [];
function check(name, fn) { fn(); results.push({ name, reproduced: true }); }
function sh(input, args = []) {
  const r = cp.spawnSync(bash, args, { input, encoding: 'utf8', env: { ...process.env, MSYS_NO_PATHCONV: '1' } });
  if (r.error) throw r.error;
  return r;
}
function posix(p) { return p.replaceAll('\\', '/').replace(/^([A-Za-z]):/, (_, d) => '/' + d.toLowerCase()); }
function el() {
  return { textContent: '', innerHTML: '', className: '', style: {}, children: [],
    firstElementChild: { style: {} }, appendChild(c) { this.children.push(c); }, insertAdjacentHTML() {} };
}
async function page(bridge, intl = Intl) {
  const elements = new Map(['nav', 'main', 'status', 'ver', 'bar', 'barnote', 'slots', 'diag'].map(id => [id, el()]));
  const context = vm.createContext({ Intl: intl, window: bridge ? { ksu: bridge } : {},
    ...(bridge ? { ksu: bridge } : {}), document: {
      getElementById(id) { if (!elements.has(id)) elements.set(id, el()); return elements.get(id); },
      createElement: el
    } });
  vm.runInContext(script + '\n globalThis.auditCommand = CHECK_CMD;', context);
  await new Promise(resolve => setImmediate(resolve));
  return { context, elements };
}
const boot = read('module/post-fs-data.sh');
const family = names => '<family lang="und-Zsye">\n' + names.map(n => `  <font weight="400" style="normal">${n}</font>`).join('\n') + '\n</family>\n';
function bootCase(name, xml, fallback = '', missing = [], failures = []) {
  const base = path.join(work, name);
  const sys = path.join(base, 'fixture-system');
  fs.mkdirSync(path.join(base, 'system/fonts'), { recursive: true });
  fs.mkdirSync(path.join(sys, 'etc'), { recursive: true });
  fs.mkdirSync(path.join(sys, 'fonts'), { recursive: true });
  fs.writeFileSync(path.join(base, 'system/fonts/NotoColorEmoji.ttf'), 'Twemoji-audit-fixture');
  fs.writeFileSync(path.join(base, 'module.prop'), 'description=initial\n');
  fs.writeFileSync(path.join(sys, 'etc/fonts.xml'), xml);
  fs.writeFileSync(path.join(sys, 'etc/font_fallback.xml'), fallback);
  for (const f of ['NotoColorEmoji.ttf', 'VendorEmoji.ttf', 'LegacyEmoji.ttf', 'Other.ttf']) {
    if (!missing.includes(f)) fs.writeFileSync(path.join(sys, 'fonts', f), 'stock-' + f);
  }
  const instrumented = boot.replaceAll('/system/etc/', `${posix(sys)}/etc/`)
    .replaceAll('"/system/fonts/', `"${posix(sys)}/fonts/`);
  // The original boot logic runs unchanged after filesystem redirection.
  // mount is a mock: copy fixture content, or simulate permission denial.
  const mock = `mount() {\n dst=\"\${@: -1}\"\n case \"$dst\" in ${failures.map(f => '*/' + f).join('|') || '__none__'}) return 1;; esac\n printf '%s\\n' \"$dst\" >> '${posix(base)}/mount.calls'\n cp \"$SRC\" \"$dst\"\n}\n`;
  fs.writeFileSync(path.join(base, 'mount.calls'), '');
  fs.writeFileSync(path.join(base, 'post-fs-data.sh'), mock + instrumented);
  const r = sh(`bash '${posix(base)}/post-fs-data.sh'\n`);
  assert.equal(r.status, 0, r.stderr);
  return { description: fs.readFileSync(path.join(base, 'module.prop'), 'utf8'),
    calls: fs.readFileSync(path.join(base, 'mount.calls'), 'utf8'),
    font: f => fs.readFileSync(path.join(sys, 'fonts', f), 'utf8') };
}
(async () => {
  for (const file of ['module/install.sh', 'module/post-fs-data.sh', 'module/META-INF/com/google/android/update-binary']) {
    check('shell syntax: ' + file, () => assert.equal(sh(read(file), ['-n']).status, 0));
  }
  check('versionCode mismatch: module=57, update=58', () => {
    assert.equal(read('module/module.prop').match(/^versionCode=(\d+)$/m)[1], '57');
    assert.equal(JSON.parse(read('module/update.json')).versionCode, 58);
  });
  const noBridge = await page();
  check('no bridge: gallery and explicit fallback render', () => {
    assert.match(noBridge.elements.get('status').textContent, /without WebUI bridge/);
    assert.equal(noBridge.elements.get('main').children.length, 9);
  });
  check('WebUI CHECK_CMD fails shell syntax', () => {
    const r = sh(noBridge.context.auditCommand, ['-n']);
    assert.notEqual(r.status, 0);
    assert.match(r.stderr, /syntax error/);
    results.push({ name: 'CHECK_CMD shell stderr', detail: r.stderr.trim() });
  });
  // KernelSU native single-argument exec returns String (official Kotlin API).
  const native = await page({ exec(cmd) { return cmd.startsWith('cat ') ? 'version=v17.0.3 (58)\ndescription=✅ Twemoji active (1/1 emoji fonts)' : 'NotoColorEmoji.ttf\tOK'; } });
  check('native string bridge: successful output discarded, fallback says installed', () => {
    assert.equal(native.elements.get('status').textContent, 'installed');
    assert.equal(native.elements.get('ver').textContent, '');
  });
  const object = await page({ exec() { return Promise.resolve({ errno: 0, stdout: 'NotoColorEmoji.ttf\tOK' }); } });
  check('object bridge: live success leaves version empty', () => {
    assert.match(object.elements.get('status').innerHTML, /Twemoji active/);
    assert.equal(object.elements.get('ver').textContent, '');
  });
  check('missing Intl.Segmenter aborts gallery and self-check', () => {
    const context = vm.createContext({ Intl: {}, window: {}, document: { getElementById: el, createElement: el } });
    assert.throws(() => vm.runInContext(script, context), /Segmenter/);
  });
  check('normal multiline config: all existing slots active', () => {
    const r = bootCase('normal', family(['NotoColorEmoji.ttf', 'VendorEmoji.ttf']));
    assert.match(r.description, /active \(2\/2/);
    assert.equal(r.calls.trim().split('\n').length, 2);
  });
  check('absent slot excluded from denominator', () => {
    const r = bootCase('absent', family(['NotoColorEmoji.ttf', 'LegacyEmoji.ttf']), '', ['LegacyEmoji.ttf']);
    assert.match(r.description, /active \(1\/1/);
  });
  check('one mount denied: partial status', () => {
    const r = bootCase('partial', family(['NotoColorEmoji.ttf', 'VendorEmoji.ttf']), '', [], ['VendorEmoji.ttf']);
    assert.match(r.description, /partial \(1\/2/);
  });
  check('all mounts denied: not active status', () => {
    const r = bootCase('denied', family(['NotoColorEmoji.ttf']), '', [], ['NotoColorEmoji.ttf']);
    assert.match(r.description, /not active/);
  });
  check('font_fallback used only when legacy parser returns empty', () => {
    const r = bootCase('fallback', '<familyset/>', family(['VendorEmoji.ttf']));
    assert.match(r.description, /active \(1\/1/);
    assert.equal(r.font('VendorEmoji.ttf'), 'Twemoji-audit-fixture');
  });
  check('both configs: new config slot ignored; false fully-active status', () => {
    const r = bootCase('precedence', family(['NotoColorEmoji.ttf']), family(['NotoColorEmoji.ttf', 'VendorEmoji.ttf']));
    assert.match(r.description, /active \(1\/1/);
    assert.equal(r.font('VendorEmoji.ttf'), 'stock-VendorEmoji.ttf');
  });
  check('multiline font element: parser misses existing slot', () => {
    const r = bootCase('multiline', '<family lang="und-Zsye">\n<font weight="400">\nNotoColorEmoji.ttf\n</font>\n</family>\n');
    assert.match(r.description, /not active/);
    assert.equal(r.calls, '');
  });
  check('two fonts on one line: parser only replaces the last slot', () => {
    const r = bootCase('same-line', '<family lang="und-Zsye">\n<font>NotoColorEmoji.ttf</font><font>VendorEmoji.ttf</font>\n</family>\n');
    assert.match(r.description, /active \(1\/1/);
    assert.equal(r.font('NotoColorEmoji.ttf'), 'stock-NotoColorEmoji.ttf');
  });
  check('non-emoji family following compact emoji family: overmatched by sed range', () => {
    const r = bootCase('range', '<family lang="und-Zsye"><font>NotoColorEmoji.ttf</font></family>\n<family lang="en">\n<font>Other.ttf</font>\n</family>\n');
    assert.equal(r.font('Other.ttf'), 'Twemoji-audit-fixture');
    assert.match(r.description, /active \(2\/2/);
  });
  check('repeat invocation: identical font skips additional mount calls', () => {
    const r = bootCase('noop', family(['NotoColorEmoji.ttf']));
    assert.equal(r.calls.trim().split('\n').length, 1);
    assert.equal(sh(`bash '${posix(work)}/noop/post-fs-data.sh'\n`).status, 0);
    assert.equal(fs.readFileSync(path.join(work, 'noop/mount.calls'), 'utf8').trim().split('\n').length, 1);
  });
  fs.writeFileSync(path.join(work, 'results.json'), JSON.stringify(results, null, 2) + '\n');
  console.log(JSON.stringify(results, null, 2));
  console.log(`Review characterization complete: ${results.filter(r => r.reproduced).length} assertions. Defects are expected and reproduced.`);
})().catch(e => { console.error(e); process.exitCode = 1; });
