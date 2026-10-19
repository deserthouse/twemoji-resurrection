"""2026-10-19 review: run regressions and independently probe XML semantics.

Read-only for production files; fixtures/artifacts stay under .audit-work.
No deletion, device access, package installation, or network operations.
The JSON distinguishes suite success from newly reproduced defects.
"""
import contextlib
import importlib.util
import io
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import xml.etree.ElementTree as ET

sys.dont_write_bytecode = True
sys.stdout.reconfigure(encoding='utf-8')
sys.stderr.reconfigure(encoding='utf-8')

ROOT = Path(__file__).resolve().parent.parent
WORK = ROOT / 'tests/.audit-work/review-2026-10-19'
BASH = Path(os.environ.get('AUDIT_BASH', 'C:/Program Files/Git/bin/bash.exe'))
NODE = Path(os.environ.get('AUDIT_NODE', str(Path.home() / '.cache/codex-runtimes/codex-primary-runtime/dependencies/node/bin/node.exe')))
WORK.mkdir(parents=True, exist_ok=True)
RESULTS = {}


def posix(p):
    value = str(p).replace('\\', '/')
    if len(value) > 1 and value[1] == ':':
        return '/' + value[0].lower() + value[2:]
    return value


def run(args, **kwargs):
    env = dict(os.environ, MSYS_NO_PATHCONV='1', PYTHONIOENCODING='utf-8')
    env.update(kwargs.pop('env', {}))
    completed = subprocess.run(args, cwd=ROOT, text=True, encoding='utf-8',
                               errors='replace', capture_output=True, env=env, **kwargs)
    return {'returncode': completed.returncode, 'stdout': completed.stdout, 'stderr': completed.stderr}


# Run the original shell suite with its delete operations adapted to preserve
# artifacts. Assertions and production scripts remain unchanged.
suite = (ROOT / 'tests/test_emoji_slots.sh').read_text(encoding='utf-8')
changes = {
    'WORK=.test-work': 'WORK=.audit-work/review-2026-10-19/original-suite',
    'rm -rf "$WORK"': ': # review keeps fixture directory',
    'rm "$FX/system/fonts/CompactEmoji.ttf"': 'mv "$FX/system/fonts/CompactEmoji.ttf" "$WORK/CompactEmoji.absent"',
    'rm -f "$WORK/mount.calls"': ': > "$WORK/mount.calls"',
}
for old, new in changes.items():
    assert old in suite, old
    suite = suite.replace(old, new)
assert 'rm ' not in suite
RESULTS['original_shell_suite_preserving_files'] = run(
    [str(BASH), '-c', suite, posix(ROOT / 'tests/test_emoji_slots.sh')])
RESULTS['original_webui_suite'] = run([str(NODE), str(ROOT / 'tests/test_webui.cjs')])
bridge_probe = r'''
const fs = require('node:fs');
const path = require('node:path');
const source = fs.readFileSync('tests/test_webui.cjs', 'utf8');
const setup = source.slice(0, source.indexOf('(async () => {'));
const probe = setup + `(async () => {
  const p = await page({ exec(cmd) {
    return cmd.startsWith('cat ') ? PROP : { errno: 1, stdout: CHECK_OUT, stderr: 'check failed after partial output' };
  }});
  console.log(JSON.stringify({ status: p.elements.get('status').innerHTML, version: p.elements.get('ver').textContent }));
})().catch(e => { console.error(e); process.exitCode = 1; });`;
require('node:vm').runInNewContext(probe, { require, __dirname: path.resolve('tests'), console, process, setImmediate, Intl });
'''
RESULTS['webui_nonzero_errno_with_rows'] = run([str(NODE), '-e', bridge_probe])

asset_name = 'Twemoji-Resurrection-17.0.3-ksu.zip'
asset = WORK / asset_name
RESULTS['build_gate'] = run([sys.executable, str(ROOT / 'tests/build_package.py'), '--out', str(asset)])
RESULTS['package_font_audit'] = run([sys.executable, str(ROOT / 'tests/audit_package.py')])

cases = {
    'baseline_compact': '<familyset><family lang="und-Zsye"><font>NotoColorEmoji.ttf</font></family><family lang="en"><font>Body.ttf</font></family></familyset>',
    'family_tab': '<familyset><family\tlang="und-Zsye"><font>NotoColorEmoji.ttf</font></family></familyset>',
    'single_quoted_attribute': "<familyset><family lang='und-Zsye'><font>NotoColorEmoji.ttf</font></family></familyset>",
    'attribute_equals_spaces': '<familyset><family lang = "und-Zsye"><font>NotoColorEmoji.ttf</font></family></familyset>',
    'font_text_newlines': '<familyset><family lang="und-Zsye"><font>\n NotoColorEmoji.ttf \n</font></family></familyset>',
    'nested_axis': '<familyset><family lang="und-Zsye"><font>NotoColorEmoji.ttf<axis tag="wght" stylevalue="400"/></font></family></familyset>',
    'commented_families': '''<familyset>
<!-- Disabled example families:
<family lang="en"><font>Example.ttf</font></family>
<family lang="und-Zsye"><font>Body.ttf</font></family>
-->
<family lang="en"><font>Body.ttf</font></family>
<family lang="und-Zsye"><font>NotoColorEmoji.ttf</font></family>
</familyset>''',
}
RESULTS['xml_probes'] = {}
for name, xml in cases.items():
    fixture = WORK / 'xml' / name
    etc = fixture / 'system/etc'
    etc.mkdir(parents=True, exist_ok=True)
    (etc / 'fonts.xml').write_text(xml, encoding='utf-8', newline='\n')
    tree = ET.fromstring(xml)  # XML oracle excludes comments and accepts legal whitespace/quoting.
    expected = sorted({
        '/system/fonts/' + ''.join(font.itertext()).strip()
        for family in tree.iter('family') if 'und-Zsye' in family.get('lang', '').split()
        for font in family.findall('font')
    })
    result = run([str(BASH), '-c', 'sh module/bin/emoji-slots.sh list'],
                 env={'EMOJI_SLOTS_READ_ROOT': posix(fixture), 'EMOJI_SLOTS_EMIT_ROOT': ''})
    actual = sorted(result['stdout'].splitlines())
    RESULTS['xml_probes'][name] = {'xml_expected': expected, 'actual': actual,
                                  'matches': expected == actual, 'returncode': result['returncode']}

# Demonstrate the consequence of a false-positive target using the real boot
# script plus the usual isolated filesystem/mount adapter.
integration = WORK / 'comment-integration'
integration_mod = integration / 'module'
integration_sys = integration / 'root'
(integration_mod / 'bin').mkdir(parents=True, exist_ok=True)
(integration_mod / 'system/fonts').mkdir(parents=True, exist_ok=True)
(integration_sys / 'system/etc').mkdir(parents=True, exist_ok=True)
(integration_sys / 'system/fonts').mkdir(parents=True, exist_ok=True)
shutil.copyfile(ROOT / 'module/bin/emoji-slots.sh', integration_mod / 'bin/emoji-slots.sh')
(integration_mod / 'system/fonts/NotoColorEmoji.ttf').write_text('TWEMOJI_FIXTURE', encoding='utf-8')
(integration_mod / 'module.prop').write_text('description=initial\n', encoding='utf-8')
(integration_sys / 'system/etc/fonts.xml').write_text(cases['commented_families'], encoding='utf-8')
for name in ['Body.ttf', 'NotoColorEmoji.ttf']:
    (integration_sys / 'system/fonts' / name).write_text('STOCK_' + name, encoding='utf-8')
boot = 'mount() { cp "$2" "$3"; }\n' + (ROOT / 'module/post-fs-data.sh').read_text(encoding='utf-8')
(integration_mod / 'run.sh').write_text(boot, encoding='utf-8', newline='\n')
RESULTS['comment_boot_integration'] = run([str(BASH), posix(integration_mod / 'run.sh')],
    env={'EMOJI_SLOTS_READ_ROOT': posix(integration_sys), 'EMOJI_SLOTS_EMIT_ROOT': posix(integration_sys)})
RESULTS['comment_boot_integration'].update({
    'body_font_after': (integration_sys / 'system/fonts/Body.ttf').read_text(encoding='utf-8'),
    'module_prop_after': (integration_mod / 'module.prop').read_text(encoding='utf-8'),
})

# Execute the real on_install callback and real unzip against the built zip.
# ln is a recorder; no symlink points into host system paths. This host's unzip
# '*' does not cross '/', unlike the manager BusyBox. Expand the known system
# pattern for the current package only; use native unzip for actual extraction.
install = WORK / 'install'
mod = install / 'module'
fx = install / 'root'
mod.mkdir(parents=True, exist_ok=True)
for partition, filename in [('system', 'fonts.xml'), ('product', 'fonts_customization.xml')]:
    etc = fx / partition / 'etc'
    etc.mkdir(parents=True, exist_ok=True)
    font = 'NotoColorEmoji.ttf' if partition == 'system' else 'ProductEmoji.ttf'
    xml = (f'<fonts-modification><family customizationType="new-locale-family" lang="und-Zsye" operation="replace"><font>{font}</font></family></fonts-modification>'
           if partition == 'product' else f'<familyset><family lang="und-Zsye"><font>{font}</font></family></familyset>')
    (etc / filename).write_text(xml, encoding='utf-8')
links = install / 'links.txt'
links.write_text('', encoding='utf-8')
commands = f'''ui_print() {{ :; }}
ln() {{ printf '%s\\n' "$3" >> '{posix(links)}'; }}
unzip() {{
  if [ "$3" = 'system/*' ]; then
    command unzip "$1" "$2" 'system/fonts/*' "$4" "$5"
  else command unzip "$@"; fi
}}
export EMOJI_SLOTS_READ_ROOT='{posix(fx)}'
export EMOJI_SLOTS_EMIT_ROOT=''
MODPATH='{posix(mod)}'
ZIPFILE='{posix(asset)}'
. module/install.sh
on_install
'''
RESULTS['real_install_callback_with_link_recorder'] = run([str(BASH), '-c', commands])
RESULTS['product_overlay_layout'] = {
    'recorded_link_destinations': links.read_text(encoding='utf-8').splitlines(),
    'module_product_fonts_exists': (mod / 'product/fonts').exists(),
    'module_system_product_fonts_exists': (mod / 'system/product/fonts').exists(),
}

# Mutation-test the version gate without touching the real repository files.
# Freeze only the tracked-file-list dependency; gate code and validations run unchanged.
tracked = subprocess.check_output(['git', '-C', str(ROOT / 'module'), 'ls-files', '-z']).decode().strip('\0').split('\0')
gate_root = WORK / 'gate-wrong-tag'
for name in tracked:
    dest = gate_root / 'module' / name
    dest.parent.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(ROOT / 'module' / name, dest)
update_file = gate_root / 'module/update.json'
upd = json.loads(update_file.read_text(encoding='utf-8'))
upd['zipUrl'] = upd['zipUrl'].replace('/download/v17.0.3/', '/download/v0.0.0/')
update_file.write_text(json.dumps(upd, indent=2), encoding='utf-8')
spec = importlib.util.spec_from_file_location('review_build_gate', ROOT / 'tests/build_package.py')
gate = importlib.util.module_from_spec(spec)
spec.loader.exec_module(gate)
gate.ROOT = gate_root
gate.MOD = gate_root / 'module'
original_check_output = subprocess.check_output
old_argv = sys.argv
try:
    subprocess.check_output = lambda *args, **kwargs: ('\0'.join(tracked) + '\0').encode()
    sys.argv = ['build_package.py']
    output = io.StringIO()
    exit_code = 0
    with contextlib.redirect_stdout(output):
        try:
            gate.main()
        except SystemExit as error:
            exit_code = error.code
    RESULTS['wrong_tag_mutation'] = {'exit_code': exit_code, 'stdout': output.getvalue(), 'zipUrl': upd['zipUrl']}
finally:
    subprocess.check_output = original_check_output
    sys.argv = old_argv

target = WORK / 'results.json'
target.write_text(json.dumps(RESULTS, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
print(json.dumps(RESULTS, ensure_ascii=False, indent=2))
print(f'Persisted evidence: {target}')
required = ['original_shell_suite_preserving_files', 'original_webui_suite', 'build_gate',
            'package_font_audit', 'real_install_callback_with_link_recorder', 'comment_boot_integration']
if any(RESULTS[name]['returncode'] != 0 for name in required):
    sys.exit(1)
