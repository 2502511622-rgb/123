"""Index generated alpha sprite sheets without modifying their pixels.
The PNGs are source assets; this only measures cells, alpha bounds and foot anchors.
"""
from pathlib import Path
import json
from PIL import Image
ROOT=Path(__file__).resolve().parents[1]/'godot/assets/actors16'
KINDS=['hungry_ghost','wraith','rakshasa','kumbhanda','asura','yaksha','kappa','chochin','ippon_datara','jorogumo','sogenbi','itsumade','daitengu','ryomen_sukuna','water','bone','archer','lantern','gunner','brute','well_boss','opera_boss','boss','daitengu_extra']
def index(name,cols,rows,ys=None):
 im=Image.open(ROOT/(name+'.png')).convert('RGBA'); alpha=im.getchannel('A'); w,h=im.size
 ys=ys or [round(i*h/rows) for i in range(rows+1)]
 output=[]
 for row in range(rows):
  # Locate gutters independently in every row, since attack wings and cloth are wider.
  xs=[0]
  for col in range(1,cols):
   nominal=round(w*col/cols); span=round(w/cols*.24)
   def cost(x):
    values=alpha.crop((x,ys[row],x+1,ys[row+1])).get_flattened_data()
    return sum(v>100 for v in values)*100+abs(x-nominal)
   xs.append(min(range(nominal-span,nominal+span+1),key=cost))
  xs.append(w)
  frames=[]
  for col in range(cols):
   cell=(xs[col],ys[row],xs[col+1],ys[row+1]); a=alpha.crop(cell)
   # Ignore imperceptible antialias pixels when measuring, not when rendering.
   box=a.point(lambda v:255 if v>40 else 0).getbbox()
   assert box, (name,row,col)
   l,t,r,b=box; l+=cell[0];r+=cell[0];t+=cell[1];b+=cell[1]
   feet=alpha.crop((l,max(t,b-12),r,b)).point(lambda v:255 if v>100 else 0).getbbox()
   anchor=l+(feet[0]+feet[2])/2 if feet else (l+r)/2
   if name in ['hero','tengu']:
    # Sandals/claws identify feet; long red ribbons must not pull the body anchor.
    points=[]
    for yy in range(max(t,b-45),b):
     for xx in range(l,r):
      red,green,blue,opacity=im.getpixel((xx,yy))
      if opacity>180 and green>35 and 1.2*green<red<2.6*green and green>1.2*blue:points.append(xx)
    if len(points)>20:
     points.sort();anchor=(points[len(points)//20]+points[len(points)*19//20])/2
   frames.append({'rect':[l,t,r-l,b-t],'anchor':[anchor-l,b-t]})
  output.append(frames)
 return output
# This historical helper now indexes only the retained hero source.
# Enemy metadata below is retained solely for legacy identities, not rendering.
out=json.loads((ROOT/'atlas.json').read_text())
out['hero']=index('hero',6,4,[0,334,626,924,1254])
(ROOT/'atlas.json').write_text(json.dumps(out,ensure_ascii=False,indent=2)+'\n')
print('Indexed 24 historical hero poses. Current monsters: godot/tools/bake_monsters27.gd')
