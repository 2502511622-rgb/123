"""Export the 23 current authored monster atlases and their per-frame pivots."""
from pathlib import Path
import json
import zipfile
root=Path(__file__).resolve().parents[1]
source=root/'godot/assets/monsters28'
output=root/'artifacts/monsters28'
output.mkdir(parents=True,exist_ok=True)
manifest=json.loads((source/'manifest.json').read_text())
for kind, entry in manifest.items():
    with zipfile.ZipFile(output/f'{kind}.zip','w',zipfile.ZIP_DEFLATED) as archive:
        archive.write(source/f'{kind}.png',f'{kind}/atlas.png')
        archive.writestr(f'{kind}/manifest.json',json.dumps(entry,ensure_ascii=False,indent=2))
        archive.writestr(f'{kind}/README.txt',
            'YinGui World v0.28 / original generated pixel artwork\n'
            '96x96 transparent cells, 8 columns. Root (48,90).\n'
            'Six independently authored anatomical parts; one neutral source pose.\n'
            'Walk: eight interpolated whole-part joint keys; attack: six windup/strike/recovery keys.\n'
            'Parts overlap at neck, shoulder and hip. Removing a limb never cuts a torso mask.\n'
            'First six cells: body,head,arm_left,arm_right,leg_left,leg_right.\n'
            'Cells 6..23 repeat neutral parts only for old saved frame indices; not new drawings.\n'
            'Cut overlays: 24+frame*5+(part-1). Root (48,90). Pivot metadata included.\n'
            'Detached whole limbs use the actual animated shoulder/hip transform and rigid physics.\n'
            'Ghosts float; one-legged yokai have one leg; wings/spider legs use complete side groups.\n')
    with zipfile.ZipFile(output/f'{kind}.zip') as archive:assert archive.testzip() is None
print(f'Verified {len(manifest)} individual monster packages')
