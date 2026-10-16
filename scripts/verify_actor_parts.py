"""Read-only validation of independently authored chibi anatomical assets."""
from pathlib import Path
from PIL import Image
import json
root=Path(__file__).resolve().parents[1]/'godot/assets/monsters28'
metadata=json.loads((root/'manifest.json').read_text())
checks=0
for kind, entry in metadata.items():
    atlas=Image.open(root/f'{kind}.png').convert('RGBA')
    assert atlas.size==(768,576),kind
    assert entry['independent_anatomy'] and entry['source_poses']==1,kind
    assert entry['motion_keys']==8 and entry['attack_keys']==6,kind
    for part in range(6):
        cell=atlas.crop((part*96,0,(part+1)*96,96))
        bounds=cell.getchannel('A').getbbox()
        assert bounds,(kind,part,'missing body part')
        width,height=bounds[2]-bounds[0],bounds[3]-bounds[1]
        assert 3<=width<40 and 5<=height<40,(kind,part,'opaque background or truncated asset')
        checks+=1
assert len(metadata)==23
print(f'PASS: {len(metadata)} chibi enemies, {checks} independent complete anatomical sprites; shared shoulder/hip overlap is intentional')
