"""Run meaningful Godot checks in an isolated save profile and detect script errors."""
from pathlib import Path
import os, subprocess, sys, tempfile
root = Path(__file__).resolve().parents[1]
with tempfile.TemporaryDirectory(prefix='mossfield-checks-') as temp:
 env = dict(os.environ, MOSSFIELD_RUNTIME_DIR=temp)
 commands = [
  ['--headless', '--editor', '--import', '--quit'],
  ['--headless', '--script', 'res://tests/test_farm.gd'],
  ['--headless', '--script', 'res://tests/test_world.gd'],
  ['--headless', '--quit-after', '30']]
 for args in commands:
  run=subprocess.run(['sh',str(root/'scripts/godot.sh'),*args],cwd=root,env=env,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True,timeout=60)
  output=run.stdout
  print(output)
  if run.returncode or 'SCRIPT ERROR' in output or 'ERROR:' in output:
   sys.exit(run.returncode or 1)
print('PASS: import, farm rules, world integration, main-scene startup')
