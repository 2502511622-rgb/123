"""Measure production JRPG sprite regions and anchors; preserve PNG source pixels.
Mirrored right-facing poses are explicit metadata and share the same body-part layout.
"""
from pathlib import Path
from PIL import Image
import json
ROOT=Path(__file__).resolve().parents[1]/'godot/assets/jrpg'
KINDS=['hungry_ghost','wraith','rakshasa','kumbhanda','asura','yaksha','kappa','chochin','ippon_datara','jorogumo','sogenbi','itsumade','daitengu','ryomen_sukuna','water','bone','archer','lantern','gunner','brute','well_boss','opera_boss','boss','daitengu_extra']
def index(name,cols,ys):
 im=Image.open(ROOT/(name+'.png')).convert('RGBA');a=im.getchannel('A'); w,h=im.size; out=[]
 for row in range(len(ys)-1):
  xs=[0]
  for col in range(1,cols):
   center=round(w*col/cols);span=round(w/cols*.24)
   def cost(x):return sum(v>100 for v in a.crop((x,ys[row],x+1,ys[row+1])).get_flattened_data())*100+abs(x-center)
   xs.append(min(range(center-span,center+span+1),key=cost))
  xs.append(w);frames=[]
  for col in range(cols):
   box=a.crop((xs[col],ys[row],xs[col+1],ys[row+1])).point(lambda v:255 if v>40 else 0).getbbox();assert box,(name,row,col)
   l,t,r,b=box;l+=xs[col];r+=xs[col];t+=ys[row];b+=ys[row]
   feet=a.crop((l,max(t,b-25),r,b)).point(lambda v:255 if v>100 else 0).getbbox()
   anchor=l+(feet[0]+feet[2])/2 if feet else (l+r)/2
   if name in ['hero_walk','hero_attack','tengu']:
    points=[]
    for y in range(max(t,b-38),b):
     for x in range(l,r):
      red,g,blue,alpha=im.getpixel((x,y))
      if alpha>180 and g>30 and 1.2*g<red<2.6*g and g>1.15*blue:points.append(x)
    if len(points)>15:
     points.sort();anchor=(points[len(points)//20]+points[len(points)*19//20])/2
   frames.append({'rect':[l,t,r-l,b-t],'anchor':[anchor-l,b-t],'mirror':False})
  out.append(frames)
 return out

def mirror(row):return [dict(frame,mirror=not frame["mirror"]) for frame in row]
def seams(name,rows):
 im=Image.open(ROOT/(name+'.png'));a=im.getchannel('A');w,h=im.size;ys=[0]
 for row in range(1,rows):
  n=round(h*row/rows);span=round(h/rows*.2)
  def cost(y):return sum(v>100 for v in a.crop((0,y,w,y+1)).get_flattened_data())*100+abs(y-n)
  ys.append(min(range(n-span,n+span+1),key=cost))
 return ys+[h]
def hand_anchors(sheet,rows,directions):
 im=Image.open(ROOT/(sheet+'.png')).convert('RGBA')
 for row,direction in zip(rows,directions):
  for frame in row:
   l,t,w,h=frame['rect']; candidates=[]
   for y in range(round(h*(.24 if sheet=="hero_attack" else .38)),round(h*.73)):
    for x in range(w):
     red,g,b,alpha=im.getpixel((l+x,t+y))
     if alpha>190 and g>38 and red>g*1.17 and red<g*2.1 and g>b*1.17 and red>85:
      candidates.append((x,y))
   if candidates:
    left=direction=='left' and not frame.get('mirror',False)
    extreme=min(x for x,y in candidates) if left else max(x for x,y in candidates)
    points=[(x,y) for x,y in candidates if abs(x-extreme)<max(3,w*.035)]
    frame['hand']=[sum(x for x,y in points)/len(points),sum(y for x,y in points)/len(points)]
   else:frame['hand']=[w*(.25 if direction=='left' else .75),h*.55]

walk=index('hero_walk',8,seams('hero_walk',4))
walk_alt=index('hero_walk_alt',8,seams('hero_walk_alt',4))
attack=index('hero_attack',6,[0,247,459,687,910,1131,1448])
for row in [attack[2],attack[5]]:
 for column in [4,5]:row[column]['mirror']=True
hand_anchors('hero_walk',walk,['down','up','left','right'])
hand_anchors('hero_walk_alt',walk_alt,['down','up','left','right'])
hand_anchors('hero_attack',attack,['down','up','left','down','up','left'])
# Neutral grip positions are calibrated to the two authored standing poses.
for row_index,row in enumerate(attack):
 direction=row_index%3
 dx,dy=[(8,-24),(9,-23),(-11,-23)][direction]
 scale=50/row[5]['rect'][3]
 for column in [0,5]:
  frame=row[column];sx=-dx if frame.get('mirror',False) else dx
  frame['hand']=[frame['anchor'][0]+sx/scale,frame['anchor'][1]+dy/scale]
legacy=json.loads((ROOT.parent/'actors16/atlas.json').read_text())
out={'hero':legacy['hero'],'hero_walk':walk,'hero_walk_alt':walk_alt,
     'hero_attack':attack[:3]+[mirror(attack[2])], 'hero_attack_alt':attack[3:6]+[mirror(attack[5])],
     'roster':dict(zip(KINDS,[f for row in index('roster',6,seams('roster',4)) for f in row])),
     'npc':index('npc',6,seams('npc',4)), 'tengu':index('tengu',4,seams('tengu',4))}
(ROOT/'atlas.json').write_text(json.dumps(out,ensure_ascii=False,indent=2)+'\n')
print('Indexed JRPG: 2 body presets, four directions x 8 walk / 6 combat poses; 23 enemies; 6 NPCs')
