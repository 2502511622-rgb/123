"""Export the 23 current authored monster atlases and their per-frame pivots."""
from pathlib import Path
import json
import zipfile
root=Path(__file__).resolve().parents[1]
source=root/'godot/assets/monsters27'
output=root/'artifacts/monsters27'
output.mkdir(parents=True,exist_ok=True)
manifest=json.loads((source/'manifest.json').read_text())
for kind, entry in manifest.items():
    with zipfile.ZipFile(output/f'{kind}.zip','w',zipfile.ZIP_DEFLATED) as archive:
        archive.write(source/f'{kind}.png',f'{kind}/atlas.png')
        archive.writestr(f'{kind}/manifest.json',json.dumps(entry,ensure_ascii=False,indent=2))
        archive.writestr(f'{kind}/README.txt',
            'YinGui World v0.27 / original generated pixel artwork\n'
            '96x96 transparent cells, 8 columns. Root (48,92).\n'
            'Four source poses: idle, step A, step B, attack. Walk playback: 0,1,0,2.\n'
            'Cell frame*6+part; parts: body,head,arm_left,arm_right,leg_left,leg_right.\n'
            'Cut overlays: 24+frame*5+(part-1). Per-frame pivots in manifest.\n'
            'Layers partition visible artwork; they do not reconstruct hidden anatomy.\n'
            'Spectral bodies have no detachable limbs; spider/bird/multiarm use side groups.\n'
            'No four-direction animation or eight independently drawn walk frames is claimed.\n')
    with zipfile.ZipFile(output/f'{kind}.zip') as archive:assert archive.testzip() is None
print(f'Verified {len(manifest)} individual monster packages')
