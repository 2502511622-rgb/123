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
  ['--headless', '--script', 'res://tests/test_display.gd'],
  ['--headless', '--script', 'res://tests/test_campaign.gd'],
  ['--headless', '--script', 'res://tests/player_campaign.gd'],
  ['--headless', '--script', 'res://tests/test_redesign.gd'],
  ['--headless', '--script', 'res://tests/test_adventure.gd'],
  ['--headless', '--script', 'res://tests/test_island.gd'],
  ['--headless', '--script', 'res://tests/test_factions.gd'],
  ['--headless', '--script', 'res://tests/test_temple.gd'],
  ['--headless', '--script', 'res://tests/test_art16.gd'],
  ['--headless', '--script', 'res://tests/test_weather.gd'],
  ['--headless', '--script', 'res://tests/test_reference_art.gd'],
  ['--headless', '--script', 'res://tests/test_living_style.gd'],
  ['--headless', '--script', 'res://tests/test_jrpg.gd'],
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
print('PASS: import, nineteen game suites, main-scene startup')
