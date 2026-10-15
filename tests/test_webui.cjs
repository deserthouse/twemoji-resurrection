// Regression tests for the WebUI page (module/webroot/index.html).
// Verifies the fixed manager-bridge handling, fallback paths and gallery
// robustness in a minimal DOM sandbox. No device, no network; Node stdlib.
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const cp = require('node:child_process');
const assert = require('node:assert/strict');
const root = path.resolve(__dirname, '..');
const bash = process.env.AUDIT_BASH || 'C:/Program Files/Git/bin/bash.exe';
const html = fs.readFileSync(path.join(root, 'module/webroot/index.html'), 'utf8');
const script = html.match(/<script>([\s\S]*?)<\/script>/)[1];
let passed = 0;
function check(name, fn) { fn(); passed++; console.log('PASS:', name); }
function sh(input, args = []) {
  const r = cp.spawnSync(bash, args, { input, encoding: 'utf8', env: { ...process.env, MSYS_NO_PATHCONV: '1' } });
  if (r.error) throw r.error;
  return r;
}
function el() {
  return { textContent: '', innerHTML: '', className: '', style: {}, children: [],
    firstElementChild: { style: {} }, appendChild(c) { this.children.push(c); }, insertAdjacentHTML() {} };
}
const PROP = 'id=Twemoji-systemless\nversion=v17.0.3 (59)\n'
  + 'description=\u2705 Twemoji active (2/2 emoji fonts)...\n';
const CHECK_OUT = '/system/fonts/NotoColorEmoji.ttf\tOK\n/product/fonts/ProductEmoji.ttf\tOK\n';
async function page(bridge, intl = Intl, createElement) {
  const elements = new Map(['nav', 'main', 'status', 'ver', 'bar', 'barnote', 'slots', 'diag'].map(id => [id, el()]));
  const context = vm.createContext({ Intl: intl, window: bridge ? { ksu: bridge } : {},
    ...(bridge ? { ksu: bridge } : {}), document: {
      getElementById(id) { if (!elements.has(id)) elements.set(id, el()); return elements.get(id); },
      createElement: createElement || el } });
  vm.runInContext(script + '\nglobalThis.auditCommand = CHECK_CMD;', context);
  await new Promise(r => setImmediate(r));
  await new Promise(r => setImmediate(r));
  return { context, elements };
}
// Official KernelSU native WebViewInterface.exec(cmd): String (stdout only)
const native = () => ({ exec(cmd) { return cmd.startsWith('cat ') ? PROP : CHECK_OUT; } });
(async () => {
  const nat = await page(native());
  const obj = await page({ exec(cmd) { return Promise.resolve({ errno: 0, stdout: cmd.startsWith('cat ') ? PROP : CHECK_OUT }); } });
  const empty = await page({ exec(cmd) { return cmd.startsWith('cat ') ? PROP : ''; } });
  const none = await page();
  const intlNoSeg = { ...Intl };
  delete intlNoSeg.Segmenter;
  const noseg = await page(native(), intlNoSeg);
  const brokenDom = await page(native(), Intl, () => { throw new Error('DOM broken'); });

  check('R3: CHECK_CMD is a single valid shell command (no generated one-liner)', () => {
    assert.match(nat.context.auditCommand,
      /^sh \/data\/adb\/modules\/Twemoji-systemless\/bin\/emoji-slots\.sh check$/);
    assert.equal(sh(nat.context.auditCommand, ['-n']).status, 0);
  });
  check('R4: native string bridge — live check, slots and version rendered', () => {
    assert.match(nat.elements.get('status').innerHTML, /Twemoji active — all 2\/2/);
    assert.equal(nat.elements.get('slots').children.length, 2);
    assert.equal(nat.elements.get('ver').textContent, 'v17.0.3 (59)');
  });
  check('R4: wrapper-object bridge ({errno,stdout,stderr}) also works', () => {
    assert.match(obj.elements.get('status').innerHTML, /Twemoji active/);
  });
  check('R4: empty live output falls back to the boot-time description', () => {
    assert.match(empty.elements.get('status').textContent, /boot-time status/);
    assert.equal(empty.elements.get('ver').textContent, 'v17.0.3 (59)');
  });
  check('no bridge: explicit fallback text, gallery still built', () => {
    assert.match(none.elements.get('status').textContent, /without WebUI bridge/);
    assert.equal(none.elements.get('main').children.length, 9);
  });
  check('R6: missing Intl.Segmenter — gallery and self-check still work', () => {
    assert.equal(noseg.elements.get('main').children.length, 9);
    assert.match(noseg.elements.get('status').innerHTML, /Twemoji active/);
  });
  check('gallery failure does not abort the self-check', () => {
    assert.match(brokenDom.elements.get('status').innerHTML, /Twemoji active/);
  });
  console.log(`WebUI regression complete: ${passed} assertions, all PASS`);
})().catch(e => { console.error(e); process.exit(1); });
