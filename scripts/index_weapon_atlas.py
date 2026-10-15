"""Measure transparent weapon cells and retain explicit equip grip anchors."""
from pathlib import Path
from PIL import Image
import json
root=Path(__file__).resolve().parents[1]/'godot/assets/weapons19'
im=Image.open(root/'atlas.png').convert('RGBA');a=im.getchannel('A');w,h=im.size
names=['sword','silver_sword','ipetam','prajna','whip','pistol','smg','rifle','revolver','gatling','spellbook','curse_doll']
grips=[(.15,.28),(.15,.30),(.15,.35),(.15,.32),(.15,.30),(.22,.74),(.22,.72),(.14,.63),(.17,.76),(.16,.64),(.45,.6),(.5,.60)]
ys=[0,315,565,h];data={}
for i,name in enumerate(names):
 row,col=divmod(i,4);l=round(col*w/4);r=round((col+1)*w/4);t=ys[row];b=ys[row+1]
 bounds=a.crop((l,t,r,b)).point(lambda x:255 if x>90 else 0).getbbox();assert bounds,name
 x,y,x2,y2=bounds;x+=l;x2+=l;y+=t;y2+=t
 data[name]={'rect':[x,y,x2-x,y2-y],'grip':list(grips[i])}
(root/'atlas.json').write_text(json.dumps(data,indent=2)+'\n')
print('Indexed',len(data),'equippable weapon sprites')
