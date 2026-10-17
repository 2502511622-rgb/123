"""Measure transparent gutters without changing generated source pixels."""
from pathlib import Path
from PIL import Image
import json
root=Path(__file__).resolve().parents[1]/'godot/assets/monsters28/source'
result={}
for group,rows in [('grave',6),('island',6),('myths',6),('bosses',5)]:
    image=Image.open(root/(group+'.png')).convert('RGBA');alpha=image.getchannel('A');w,h=image.size
    ys=[0]
    for row in range(1,rows):
        mid=round(h*row/rows);span=round(h/rows*.28)
        def cost(y):return sum(v>160 for v in alpha.crop((0,y,w,y+1)).get_flattened_data())*10000+abs(y-mid)
        ys.append(min(range(mid-span,mid+span),key=cost))
    ys.append(h);columns=[]
    for row in range(rows):
        xs=[0]
        for col in range(1,6):
            mid=round(w*col/6);span=round(w/6*.30)
            def cost(x):return sum(v>160 for v in alpha.crop((x,ys[row],x+1,ys[row+1])).get_flattened_data())*10000+abs(x-mid)
            xs.append(min(range(mid-span,mid+span),key=cost))
        xs.append(w)
        for a,b in zip(xs,xs[1:]):assert alpha.crop((a,ys[row],b,ys[row+1])).getbbox(),(group,row,a,b)
        columns.append(xs)
    result[group]={'rows':ys,'columns':columns}
(root/'cells.json').write_text(json.dumps(result,indent=2)+'\n')
print('Measured 138 independently drawn body-part cells')
