"""Verify source-pixel conservation and non-overlap of anatomical alpha layers."""
from pathlib import Path
from PIL import Image
import json
ROOT=Path(__file__).resolve().parents[1]
base=ROOT/'godot/assets/jrpg'
data=json.loads((base/'parts/parts.json').read_text())
sources={name:Image.open(base/(name+'.png')).convert('RGBA') for name in ['roster','tengu']}
checks=0
for name,entry in data.items():
 l,t,w,h=map(int,entry['frame']['rect'])
 raw=sources[entry['atlas']].crop((l,t,l+w,t+h));expected=raw.tobytes()
 actual=bytearray(w*h*4);occupied=bytearray(w*h)
 for part in entry['parts']:
  p=ROOT/'godot'/part['path'].removeprefix('res://')
  im=Image.open(p).convert('RGBA');px=im.tobytes();cx,cy,cw,ch=part['crop']
  assert im.size==(cw,ch),(name,part['joint'],'size')
  for y in range(ch):
   for x in range(cw):
    i=(y*cw+x)*4
    if not px[i+3]:continue
    j=(y+cy)*w+x+cx
    assert not occupied[j],(name,part['joint'],'overlap',x,y)
    occupied[j]=1;actual[j*4:j*4+4]=px[i:i+4]
 for i in range(w*h):
  if expected[i*4+3]:assert actual[i*4:i*4+4]==expected[i*4:i*4+4],(name,'pixel mismatch',i)
  else:assert not actual[i*4+3],(name,'extra pixel',i)
 checks+=1
print('PARTS PASS:',checks,'poses reconstruct source pixels exactly with disjoint anatomical layers')
