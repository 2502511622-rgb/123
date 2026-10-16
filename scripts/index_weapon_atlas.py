"""Index the current twelve-item pixel weapon atlas and explicit equip grips."""
from pathlib import Path
import json
from atlas_regions import grid_regions
root=Path(__file__).resolve().parents[1]/'godot/assets/weapons19'
names=['sword','silver_sword','ipetam','prajna','whip','pistol','smg','rifle','revolver','gatling','spellbook','curse_doll']
grips=[(.12,.35),(.12,.50),(.12,.50),(.12,.50),(.15,.30),(.16,.74),(.22,.72),(.14,.63),(.17,.76),(.16,.64),(.5,.74),(.5,.60)]
data={name:{'rect':region,'grip':list(grip)} for name,region,grip in zip(names,grid_regions(root/'atlas.png',4,3),grips)}
(root/'atlas.json').write_text(json.dumps(data,indent=2)+'\n')
print('Indexed',len(data),'equippable weapon sprites')
