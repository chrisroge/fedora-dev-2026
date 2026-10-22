#!/usr/bin/env python3
"""merge-json.py BASELINE TARGET — add baseline settings the target lacks.

Used for ~/.claude/settings.json: the user's existing values always win.
Top-level keys missing from TARGET are copied in; permissions.allow lists
are unioned; a hook event (e.g. "Stop") is added only if TARGET has none.
TARGET is created if absent. When it changes, the previous file is kept as
TARGET.bak-fedora-dev-<timestamp> (never overwriting an existing backup).
"""
import json
import os
import shutil
import sys
import tempfile
import time

baseline_path, target_path = sys.argv[1], sys.argv[2]
with open(baseline_path) as f:
    baseline = json.load(f)
target = {}
if os.path.exists(target_path):
    with open(target_path) as f:
        target = json.load(f)
before = json.dumps(target, sort_keys=True)

for key, value in baseline.items():
    if key == 'permissions':
        perms = target.setdefault('permissions', {})
        for pkey, pval in value.items():
            if isinstance(pval, list):
                have = perms.setdefault(pkey, [])
                have.extend(v for v in pval if v not in have)
            else:
                perms.setdefault(pkey, pval)
    elif key == 'hooks':
        hooks = target.setdefault('hooks', {})
        for event, entries in value.items():
            hooks.setdefault(event, entries)
    else:
        target.setdefault(key, value)

if json.dumps(target, sort_keys=True) != before:
    if os.path.exists(target_path):
        shutil.copy2(target_path, f'{target_path}.bak-fedora-dev-{time.strftime("%Y%m%d-%H%M%S")}')
    os.makedirs(os.path.dirname(target_path), exist_ok=True)
    fd, tmp = tempfile.mkstemp(dir=os.path.dirname(target_path))
    with os.fdopen(fd, 'w') as f:
        json.dump(target, f, indent=2)
        f.write('\n')
    os.replace(tmp, target_path)
    print(f'==> merged baseline into {target_path}')
