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
  ['--headless', '--script', 'res://tests/test_foundation.gd'],
  ['--headless', '--script', 'res://tests/player_journey.gd'],
  ['--headless', '--script', 'res://tests/test_arsenal.gd'],
  ['--headless', '--script', 'res://tests/test_expansion.gd'],
  ['--headless', '--quit-after', '30']]
 for index,args in enumerate(commands):
  env['MOSSFIELD_RUNTIME_DIR']=str(Path(temp)/str(index))
  try:
   run=subprocess.run(['sh',str(root/'scripts/godot.sh'),*args],cwd=root,env=env,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True,timeout=60)
  except subprocess.TimeoutExpired as error:
   output=error.stdout or b''
   print(output.decode(errors='replace') if isinstance(output,bytes) else output)
   print('FAIL: timed out:',args)
   sys.exit(1)
  output=run.stdout
  print(output)
  if run.returncode or 'SCRIPT ERROR' in output or 'ERROR:' in output:
   sys.exit(run.returncode or 1)
print('PASS: import, farm rules, world integration, main-scene startup')
