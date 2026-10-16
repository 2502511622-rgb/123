"""Read-only validation of the current 96px monster layers and authored poses."""
from pathlib import Path
from PIL import Image
import json
root=Path(__file__).resolve().parents[1]/'godot/assets/monsters27'
metadata=json.loads((root/'manifest.json').read_text())
checks=0
for kind, entry in metadata.items():
    atlas=Image.open(root/f'{kind}.png').convert('RGBA')
    assert atlas.size==(768,576),kind
    signatures=set()
    for frame in range(4):
        occupied=set()
        pixels=[]
        for part in range(6):
            index=frame*6+part
            cell=atlas.crop(((index%8)*96,(index//8)*96,(index%8+1)*96,(index//8+1)*96))
            for y in range(96):
                for x in range(96):
                    color=cell.getpixel((x,y))
                    if not color[3]:continue
                    assert (x,y) not in occupied,(kind,frame,'overlap')
                    occupied.add((x,y));pixels.append((x,y,color))
        assert len(occupied)>150,(kind,frame,'empty source pose')
        assert len(occupied)<96*96*.85,(kind,frame,'opaque background')
        signatures.add(hash(tuple(sorted(pixels))))
        checks+=1
    assert len(signatures)==4,(kind,'duplicate source poses')
    assert len(entry['pivots'])==4,kind
assert len(metadata)==23
print(f'PASS: {len(metadata)} independent monsters, {checks} disjoint transparent authored poses')
