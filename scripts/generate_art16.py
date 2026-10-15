"""Rebuild original 16-bit game sprites and terrain; no downloaded concept image is used.
Requires Pillow for development only. All randomness is seeded for reproducible assets.
"""
from pathlib import Path
from PIL import Image, ImageDraw
import random, re, math
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'godot/assets/art16'; OUT.mkdir(parents=True,exist_ok=True)
rng=random.Random(14016)
def canvas(w,h):
    im=Image.new('RGBA',(w,h)); return im,ImageDraw.Draw(im)
def save(im,name): im.save(OUT/(name+'.png'))
def mix(a,b,t):
    a=tuple(bytes.fromhex(a.lstrip('#'))); b=tuple(bytes.fromhex(b.lstrip('#')))
    return tuple(round(x*(1-t)+y*t) for x,y in zip(a,b))
def sculpt(im,cell_w,cell_h):
    # Original sprite construction pass: dark contour, lit upper edge and cloth ramps.
    source=im.copy();px=source.load();out=im.load()
    w,h=im.size
    for y in range(h):
        for x in range(w):
            r,g,b,a=px[x,y]
            if not a:continue
            left=px[x-1,y][3] if x%cell_w else 0
            above=px[x,y-1][3] if y%cell_h else 0
            right=px[x+1,y][3] if x%cell_w<cell_w-1 else 0
            factor=0.96+0.045*(1.0-(x%cell_w)/cell_w)
            if not above:factor=1.12
            elif not right:factor=0.78
            elif not left:factor=0.91
            out[x,y]=(min(255,round(r*factor)),min(255,round(g*factor)),min(255,round(b*factor)),a)
    return im
PALETTES={'farm':('#425d49','#8e927c'),'village':('#3b5748','#93917b'),'graveyard':('#354d49','#727e78'),'forest':('#2e4940','#7e8875'),'island':('#3e5750','#9c9682'),'temple':('#47574b','#96917b'),'sunken':('#364f4c','#7f8c84'),'theatre':('#434d46','#8a8274'),'hall':('#394640','#8b7c65'),'shop':('#3c4b42','#928269')}
for zone,(grass,stone) in PALETTES.items():
    atlas=Image.new('RGBA',(32*32,32))
    for index in range(32):
        im,d=canvas(32,32)
        base=grass if index<8 or index in [14,15] or index>=16 else '#63533e' if index==8 else '#443e33' if index==9 else stone if index==10 else '#233f47'
        d.rectangle((0,0,31,31),fill=base)
        if index<8 or index in [14,15] or index>=16:
            for j in range(10):
                x,y=rng.randrange(32),rng.randrange(32)
                shade=mix(grass,'#b7b689',.12 if j%3 else .21)
                d.line((x,y,x+1,y-2),fill=shade)
            for j in range(3):
                x,y=rng.randrange(30),rng.randrange(30)
                d.line((x,y,x+2,y),fill=mix(grass,'#172e2e',.22))
            if index==14:
                for x,y in [(7,13),(18,22),(25,8)]:
                    d.line((x,y,x,y+4),fill='#67805e'); d.rectangle((x-1,y-1,x+1,y),fill='#bdaf76')
        if index==10 or index>=16:
            mask=index-16 if index>=16 else 15
            left=0 if mask&8 else 4; right=31 if mask&2 else 27
            top=0 if mask&1 else 4; bottom=31 if mask&4 else 27
            d.rectangle((left,top,right,bottom),fill=mix(stone,'#24362f',.28))
            for row in range(4):
                y=row*9-2
                for col in range(4):
                    x=col*12-(5 if row%2 else 0)
                    box=(max(left+1,x),max(top+1,y),min(right-1,x+10),min(bottom-1,y+7))
                    if box[2]<=box[0] or box[3]<=box[1]: continue
                    c=mix(stone,'#c3b993',rng.choice([.01,.06,.12,.2]))
                    d.rounded_rectangle(box,radius=1,fill=c)
                    d.line((box[0]+1,box[1],box[2]-1,box[1]),fill=mix(stone,'#d6c8a5',.23))
            for j in range(9):
                x,y=rng.randrange(32),rng.randrange(32)
                if left<x<right and top<y<bottom and (x<left+3 or y>bottom-4):d.point((x,y),fill='#657b58')
        elif index in [8,9]:
            for y in [6,15,24]:
                d.line((2,y,29,y),fill='#846749' if index==8 else '#5c5140',width=2)
                d.line((3,y+2,28,y+2),fill='#514634' if index==8 else '#35392f')
            for j in range(16):d.point((rng.randrange(32),rng.randrange(32)),fill='#aa8660' if index==8 else '#7d7560')
        elif index in [11,12,13]:
            for x,y in [(2,6),(17,15),(7,26)]:
                dx=index-11
                d.line((x+dx,y,x+dx+7,y),fill='#42646a')
                d.line((x+dx+1,y+1,x+dx+4,y+1),fill='#537779')
            for x,y in [(22,4),(12,19)]:d.point((x,y),fill='#7f998c')
        atlas.alpha_composite(im,(index*32,0))
    save(atlas,'terrain_'+zone)
# Roof tiles and exposed timber are rendered at final logical pixel density.
def house(name,w,h):
    im,d=canvas(w,h); front=int(h*.42); bottom=h-10
    d.polygon([(10,front),(w-15,front),(w-9,bottom),(8,bottom)],fill='#23342f')
    d.rectangle((14,front,w-16,bottom-6),fill='#ada282')
    for j in range(100):
        xx=16+(j*31)%(w-34); yy=front+3+(j*17)%max(4,bottom-front-13)
        d.point((xx,yy),fill='#b8ad8c' if j%3 else '#918b70')
    for y in range(front+3,bottom-7,7):d.line((15,y,w-17,y),fill='#a09578')
    for x in [15,w//2-5,w-20]:
        d.rectangle((x,front,x+5,bottom-5),fill='#4c4438');d.line((x+1,front+3,x+1,bottom-8),fill='#76634b')
    # Roof has an asymmetric side face and rows of individual clay tiles.
    d.polygon([(22,12),(w-33,12),(w-4,front+6),(1,front+6)],fill='#182c2e')
    for row,y in enumerate(range(16,front+5,7)):
        left=max(2,22-int((y-12)*.6)); right=min(w-5,w-33+int((y-12)*.75))
        for x in range(left,right,10):
            c=['#344b4d','#3f5655','#293e43'][((x//10)+row)%3]
            d.rectangle((x,y,min(x+8,right),y+5),fill=c)
            d.line((x+1,y,x+7,y),fill='#657875')
            d.line((x+8,y+1,x+8,y+4),fill='#203437')
            d.line((x+2,y+4,min(x+6,right),y+4),fill='#273f40')
            if (x+row*7)%23<4:
                d.line((x+1,y+3,min(x+5,right),y+3),fill='#718261')
                d.point((x+2,y+2),fill='#96a07b')
    d.line((22,11,w-33,11),fill='#889288',width=2)
    d.line((3,front+7,w-5,front+7),fill='#192d2d',width=4)
    d.line((5,front+9,w-7,front+9),fill='#79654b')
    d.rectangle((15,front+10,w-17,front+13),fill='#72745c')
    for x in [26,w-50]:
        d.rectangle((x-3,front+18,x+27,front+47),fill='#524739')
        d.rectangle((x,front+20,x+23,front+43),fill='#b78f55')
        d.rectangle((x+2,front+21,x+21,front+41),fill='#dfb76e')
        for xx in range(x+4,x+22,6):d.line((xx,front+21,xx,front+42),fill='#5c513d')
        d.line((x,front+30,x+23,front+30),fill='#5c513d',width=2)
        d.line((x-4,front+47,x+28,front+47),fill='#c0a176',width=2)
    x=w//2
    d.rectangle((x-12,front+22,x+12,bottom-5),fill='#23312e')
    d.rectangle((x-10,front+24,x+9,bottom-7),fill='#594b39')
    for xx in range(x-8,x+9,5):d.line((xx,front+25,xx,bottom-8),fill='#77634a')
    d.rectangle((x+5,bottom-26,x+7,bottom-23),fill='#c5a865')
    d.rectangle((x-18,bottom-4,x+18,bottom),fill='#7f8370');d.line((x-18,bottom-4,x+18,bottom-4),fill='#b3ac8a')
    d.rectangle((x-22,bottom+1,x+22,bottom+4),fill='#67736a')
    for x in range(11,w-15,10):d.rectangle((x,bottom-8,x+7,bottom-5),fill='#727a6a')
    # Small shutters, a red ward and pots make silhouettes readable without noise.
    d.rectangle((w//2+16,front+20,w//2+21,front+38),fill='#a05e48')
    for yy in range(front+23,front+36,4):d.line((w//2+18,yy,w//2+20,yy+1),fill='#d3b67c')
    for x in [11,w-24]:
        d.ellipse((x,bottom-19,x+12,bottom-6),fill='#755f48')
        d.line((x+2,bottom-18,x+10,bottom-18),fill='#b29a70',width=2)
    if name=='store':
        for x in range(8,w-8,13):
            d.rectangle((x,front+10,x+11,front+19),fill='#a58b60' if (x//13)%2 else '#d2b67b')
        for x in [17,w-39]:
            d.rectangle((x,bottom-12,x+20,bottom+1),fill='#766447');d.line((x,bottom-5,x+20,bottom-5),fill='#bc9a65')
            for dx in [3,9,15]:d.ellipse((x+dx,bottom-16,x+dx+5,bottom-10),fill='#a67751' if x==17 else '#7c9b61')
    save(im,name)
house('cottage',160,136);house('store',128,116)
# Old pagoda-like paper lantern with warm glass and a dark wooden stand.
im,d=canvas(32,48)
d.rectangle((15,1,17,44),fill='#4f4938');d.rectangle((10,43,23,47),fill='#34433b')
d.polygon([(6,7),(26,7),(28,10),(4,10)],fill='#34423e');d.line((6,7,26,7),fill='#9d875a')
d.rounded_rectangle((7,11,25,29),radius=3,fill='#b5793b');d.rectangle((10,12,22,28),fill='#e4b45e');d.rectangle((12,14,20,26),fill='#f0ce82')
for x in [9,15,23]:d.line((x,12,x,28),fill='#b68542')
d.rectangle((6,29,26,32),fill='#544b37');d.line((8,30,24,30),fill='#ab8e51');d.line((15,34,15,39),fill='#b26043')
save(im,'lantern')
# Organic leaf masses, articulated branches, lit leaf clusters and weathered bark.
def detailed_tree(name,seed,autumn=False,pine=False):
    local=random.Random(seed)
    im,d=canvas(64,92)
    d.polygon([(28,42),(37,42),(36,75),(47,85),(37,86),(31,82),(22,88),(16,86),(27,74)],fill='#1e3830')
    for points,width,color in [([(32,80),(33,57),(28,37)],7,'#655c43'), ([(32,62),(17,44),(12,30)],4,'#534f3c'), ([(33,58),(48,41),(51,29)],4,'#736348')]:
        d.line(points,fill=color,width=width)
    d.line((30,52,30,76),fill='#b09a68',width=1)
    for y in range(52,80,5):d.line((32,y,34,y+3),fill='#354b39')
    mask=Image.new('L',(64,92));md=ImageDraw.Draw(mask)
    clusters=[(17,4,45,32),(7,14,39,41),(27,15,59,43),(2,29,32,55),(21,27,61,58),(9,41,42,67),(29,42,56,64)]
    if pine:clusters=[(23,2,40,23),(16,13,47,36),(10,27,54,49),(4,40,61,65)]
    colors=['#344e3a','#3e5c3f','#4f7049','#617e51'] if not autumn else ['#645c3b','#7b7146','#929053','#a69b64']
    for i,box in enumerate(clusters):
        d.ellipse(box,fill=colors[min(3,(len(clusters)-i)//2)])
        md.ellipse(box,fill=255)
    # Pixel clusters follow the canopy silhouette, rather than a flat polygon fill.
    for i in range(300):
        x=local.randrange(3,60);y=local.randrange(4,67)
        if not mask.getpixel((x,y)):continue
        shade=colors[local.randrange(4)]
        if x<35 and y<34 and i%3==0:shade='#92a672' if not autumn else '#c2b67c'
        d.line((x,y,min(x+local.randrange(1,4),61),y),fill=shade)
        if i%4==0:d.point((x,y+1),fill='#283f30' if not autumn else '#5c5a36')
    for x,y in [(9,45),(20,60),(42,56),(54,37)]:
        d.line((x,y,x-1,y+5),fill='#4b6544');d.point((x-1,y+5),fill='#9baa70')
    save(im,name)
detailed_tree('tree',15015)
detailed_tree('tree_autumn',15016,autumn=True)
detailed_tree('tree_pine',15017,pine=True)
# Loose scenery atlas: grass tuft, reeds, pebbles, pots, baskets, firewood, red paper, lotus.
im,d=canvas(32*8,32)
for i in range(8):
    x=i*32
    if i in [0,1]:
        for j in range(7):
            xx=x+4+j*3; top=rng.randrange(4,18) if i else rng.randrange(17,25)
            d.line((xx,29,xx-2,top),fill=['#526e4a','#75865a','#435f44'][j%3])
            if i==1:d.line((xx-2,top,xx-2,top+5),fill='#b1aa7a',width=2)
    elif i==2:
        for xx,yy in [(6,23),(18,27),(24,19)]:
            d.polygon([(x+xx-4,yy),(x+xx,yy-3),(x+xx+5,yy),(x+xx+3,yy+2)],fill='#627462')
            d.line((x+xx-2,yy-1,x+xx+2,yy-1),fill='#829079')
    elif i==3:
        d.ellipse((x+7,12,x+25,28),fill='#504d3e');d.ellipse((x+9,11,x+23,16),fill='#9f8c65');d.ellipse((x+11,12,x+21,15),fill='#2b3d34')
    elif i==4:
        d.rectangle((x+5,17,x+26,28),fill='#8a7853')
        for y in range(18,28,3):d.line((x+6,y,x+25,y),fill='#b29d6e')
        d.arc((x+9,8,x+23,25),180,360,fill='#ae9568',width=2)
    elif i==5:
        for y in [18,23,28]:
            d.line((x+5,y,x+26,y-3),fill='#726047',width=4);d.line((x+5,y-1,x+25,y-4),fill='#9d8258')
    elif i==6:
        d.rectangle((x+13,6,x+18,28),fill='#a5664c')
        for y in [10,14,18,23]:d.line((x+14,y,x+17,y+1),fill='#d9be7e')
    else:
        d.ellipse((x+5,19,x+28,29),fill='#496c53');d.polygon([(x+17,23),(x+25,19),(x+29,23)],fill='#274d49');d.rectangle((x+12,17,x+15,20),fill='#d9bf95')
save(im,'scenery')
# A travelling ritualist: four directions, four gait frames, 32x48 source cells.
im,d=canvas(128,192)
for row in range(4):
    for f in range(4):
        x=f*32;y=row*48;step=[0,1,0,-1][f]
        def sy(v):return v if v<18 else round(18+(v-18)*1.35)
        def rect(box,c):d.rectangle(tuple(v+x if i%2==0 else sy(v)+y for i,v in enumerate(box)),fill=c)
        def poly(points,c):d.polygon([(x+a,y+sy(b)) for a,b in points],fill=c)
        poly([(12,18),(22,18),(26,33),(22,36),(9,35)],'#172f35')
        rect((11,33,14,38+max(0,step)),'#263331');rect((20,33,23,38+max(0,-step)),'#263331')
        rect((10,38,15,39),'#817a60');rect((19,38,24,39),'#817a60')
        poly([(12,18),(17,22),(14,33),(10,32)],'#4e6862');poly([(19,19),(22,19),(25,33),(18,34)],'#314d4d')
        rect((13,25,22,27),'#b89b5c');rect((13,26,15,29),'#d4bf7e')
        rect((8,20,11,28),'#405957');rect((23,20,26,28),'#304a4a')
        rect((8,28,11,31),'#bd9a70');rect((23,28,26,31),'#bd9a70')
        rect((13,9,21,18),'#c6a276');rect((12,8,23,12),'#263b39')
        if row==1:rect((12,9,23,18),'#253a38');rect((14,16,21,18),'#1c302f')
        else:
            rect((13,12,21,16),'#d6b68a')
            if row==0:
                rect((14,13,15,14),'#253d38');rect((20,13,21,14),'#253d38');rect((17,17,19,17),'#8f745a')
            else:rect((13 if row==2 else 21,13,14 if row==2 else 22,14),'#253d38')
        poly([(11,6),(20,4),(25,10),(22,12),(8,12)],'#1c3437')
        rect((10,10,24,11),'#5b7569');rect((16,5,19,9),'#bca566')
        if row==1:poly([(20,11),(25,16+step),(24,24),(21,20)],'#7e5c48')
save(sculpt(im,32,48),'hero')
# Six distinct residents, with shared light direction and proportions.
im,d=canvas(32*6,44)
for i,(robe,hat) in enumerate([('#59674f','#a49f81'),('#4f6f63','#b1b09a'),('#675b49','#4f4940'),('#6b6253','#354c47'),('#5a704f','#b5a06c'),('#496375','#273f45')]):
    x=i*32
    d.ellipse((x+5,38,x+28,43),fill='#223a31')
    d.rectangle((x+11,35,x+14,41),fill='#383f35');d.rectangle((x+20,35,x+23,41),fill='#383f35')
    d.polygon([(x+11,19),(x+23,19),(x+28,35),(x+8,35)],fill=robe)
    d.line((x+17,21,x+15,34),fill=mix(robe,'#c6c4a0',.25),width=2)
    d.rectangle((x+9,22,x+11,29),fill='#b89b75');d.rectangle((x+24,23,x+26,30),fill='#b89b75')
    d.rectangle((x+13,10,x+22,19),fill='#d1b18a');d.rectangle((x+12,7,x+23,11),fill=hat)
    d.point((x+15,14),fill='#2b3d35');d.point((x+21,14),fill='#2b3d35')
    if i==0:d.rectangle((x+15,18,x+21,23),fill='#c5c2a5');d.line((x+7,26,x+7,41),fill='#a49269')
    elif i==1:d.rectangle((x+11,6,x+24,10),fill=hat);d.rectangle((x+24,25,x+28,34),fill='#8c8160')
    elif i==2:d.rectangle((x+13,23,x+23,35),fill='#3e4942');d.line((x+26,25,x+28,36),fill='#b4b8a0',width=2)
    elif i==3:d.rectangle((x+24,26,x+29,34),fill='#d5b36d');d.rectangle((x+25,28,x+28,32),fill='#f0d392')
    elif i==4:d.polygon([(x+7,11),(x+17,3),(x+28,11)],fill=hat);d.line((x+8,11,x+27,11),fill='#d1b679')
    else:d.rectangle((x+12,3,x+23,9),fill=hat);d.rectangle((x+23,25,x+29,33),fill='#b5ac89');d.line((x+26,26,x+26,32),fill='#6a7b6e')
save(sculpt(im,32,44),'villagers')
# All enemy bodies use one twice-density atlas, preserving anatomical cut regions.
source=(ROOT/'godot/scripts/combat/balance.gd').read_text().split('const MONSTERS = {',1)[1].split('\n}',1)[0]
kinds=re.findall(r'^ "([a-z_]+)":',source,re.M)
im,d=canvas(32,48*len(kinds))
for row,kind in enumerate(kinds):
    y=row*48
    skin='#a5aa8d';robe='#3b5651';accent='#b6a26d'
    if kind in ['rakshasa','asura','ryomen_sukuna','brute']:skin='#b68d76';robe='#78534e';accent='#cbb076'
    if kind in ['wraith','lantern','sogenbi']:skin='#9bc5b6';robe='#3d6f71';accent='#b2ddd1'
    if kind in ['bone','archer','ippon_datara']:skin='#c4c1a3';robe='#606556'
    if kind in ['yaksha','kappa']:skin='#739d85';robe='#4b7268';accent='#d2b577'
    def rect(box,c):d.rectangle(tuple(v+(y if i%2 else 0) for i,v in enumerate(box)),fill=c)
    def poly(points,c):d.polygon([(a,y+b) for a,b in points],fill=c)
    poly([(10,15),(23,15),(27,34),(23,38),(8,37),(7,24)],'#203937')
    poly([(11,16),(22,16),(25,35),(9,35)],robe)
    rect((11,18,13,33),mix(robe,'#dde0b7',.25));rect((14,34,22,36),accent)
    rect((7,19,10,34),skin);rect((24,18,27,34),skin)
    rect((10,37,14,46),'#394840');rect((20,37,24,46),'#394840')
    rect((9,45,15,47),'#6c7663');rect((20,45,26,47),'#6c7663')
    poly([(10,3),(22,3),(24,8),(22,15),(11,15),(9,9)],skin)
    rect((11,4,21,5),mix(skin,'#f0d7a5',.3));rect((11,8,14,10),'#263d39');rect((19,8,22,10),'#263d39');rect((14,13,20,14),'#6b6650')
    if kind in ['bone','archer']:
        rect((9,19,24,35),'#263f3b')
        for yy in [20,25,30]:rect((11,yy,22,yy+1),skin)
        rect((16,18,17,36),skin)
    if kind=='hungry_ghost':
        rect((11,14,22,20),'#253d37');rect((15,13,18,21),skin)
        d.ellipse((9,y+22,24,y+36),fill='#a6a67c');rect((15,8,17,10),'#293e33')
    elif kind=='wraith':
        poly([(7,31),(26,31),(28,43),(22,39),(18,47),(13,41),(6,45)],robe)
        rect((11,17,22,33),skin);rect((10,8,13,11),'#d3e5c0');rect((20,8,23,11),'#d3e5c0')
    elif kind=='sogenbi':
        rect((0,0,31,47),(0,0,0,0))
        poly([(8,2),(14,9),(24,0),(23,12),(30,16),(26,35),(19,41),(5,35),(1,23),(7,16)],'#8f624a')
        poly([(12,8),(17,14),(22,8),(22,17),(27,22),(23,33),(9,34),(5,25),(12,19)],'#d1a066')
        rect((9,17,23,29),'#9cb29c');rect((11,21,14,23),'#314b43');rect((19,21,22,23),'#314b43');rect((13,27,20,28),'#586b55')
    elif kind=='kumbhanda':
        d.ellipse((6,y+19,28,y+39),fill='#9b8f9c');rect((14,29,18,32),'#4c4c5c')
        for xx in [9,15,22]:rect((xx,19,xx+2,22),accent)
    elif kind=='rakshasa':
        poly([(6,0),(15,4),(27,0),(24,17),(8,17)],'#685078');rect((11,4,22,14),skin)
        rect((12,10,14,14),'#e0d7ae');rect((20,10,22,14),'#e0d7ae');rect((2,24,4,43),'#a2c799');rect((28,22,30,42),'#a2c799')
    elif kind in ['asura','ryomen_sukuna']:
        rect((1,5,9,15),skin);rect((24,5,31,15),skin)
        for yy in [18,25,31]:rect((0,yy,8,yy+3),skin);rect((25,yy,31,yy+3),skin)
        for yy in [5,16,28]:rect((0,yy,1,yy+12),'#d2dbb9')
        rect((11,19,22,22),accent);rect((14,23,19,30),accent)
    elif kind=='yaksha':
        for xx in [10,15,21]:rect((xx,0,xx+2,6),accent)
        rect((9,5,24,7),accent);rect((11,20,23,31),accent)
        rect((28,5,29,47),'#b1a170');rect((25,1,26,12),'#d8d5a5');rect((31,1,31,12),'#d8d5a5');rect((25,11,31,13),'#d8d5a5')
    elif kind=='kappa':
        rect((8,2,24,5),'#b6d4b8');rect((11,1,22,2),'#6cbdc4');rect((10,11,23,14),'#b9ad6b');rect((11,21,23,33),'#345847')
    elif kind=='chochin':
        rect((0,0,31,47),(0,0,0,0))
        rect((8,2,24,5),'#665a40');d.rounded_rectangle((5,y+6,27,y+33),radius=5,fill='#c8ac73')
        for yy in [11,19,27]:rect((6,yy,26,yy+1),'#8c7654')
        rect((11,13,21,20),'#273b35');rect((14,14,17,18),'#ede1ae');rect((14,26,19,42),'#ae6d6d')
    elif kind=='ippon_datara':
        rect((11,8,22,12),'#383f3c');rect((15,8,18,11),'#e4d7a7');rect((9,36,27,47),'#00000000');rect((15,35,22,47),'#796b50');rect((22,15,31,23),'#a5b0a0')
    elif kind=='jorogumo':
        rect((8,0,24,8),'#2a363e');d.ellipse((6,y+25,27,y+41),fill='#675775')
        for yy in [20,27,34,40]:rect((0,yy,7,yy+2),'#51535c');rect((25,yy,31,yy+2),'#51535c')
    elif kind=='itsumade':
        for side in [0,25]:poly([(side,13),(side+7,18),(side+6,36),(side,31)],'#c8ac64')
        rect((17,35,21,45),'#7c9876');rect((20,42,30,45),'#7c9876')
    elif kind=='daitengu':
        rect((10,2,22,7),'#34414a');rect((12,8,23,15),'#b77660');rect((22,10,29,12),'#b77660')
        poly([(0,14),(8,20),(7,37),(0,32)],'#2d4147');poly([(25,20),(31,14),(31,32),(25,37)],'#2d4147');rect((25,25,31,32),'#9bb5a0')
    elif kind in ['gunner','opera_boss']:
        poly([(4,9),(16,1),(28,9)],'#c5b694');rect((14,7,16,14),'#a56b52');rect((20,26,31,30),'#9da995')
    elif kind=='boss':
        rect((3,0,28,43),'#3a4142');rect((6,4,25,40),'#685b4b');rect((12,11,20,25),'#c1ac70');rect((15,13,17,24),'#96654c')
    elif kind=='well_boss':
        rect((5,0,27,9),'#304c48');rect((10,4,23,15),'#adc4a3');rect((10,9,13,10),'#314b44');rect((20,9,23,10),'#314b44')
        poly([(4,16),(15,20),(27,17),(26,32),(20,37),(27,42),(30,38),(30,46),(19,47),(13,38),(7,33)],'#567f78')
        for yy in [20,25,30]:rect((12,yy,23,yy+1),'#8eab94')
        rect((5,8,8,26),'#d0cfaf');rect((24,7,27,25),'#d0cfaf')
    elif kind=='brute':
        poly([(3,2),(10,6),(25,2),(23,12),(9,12)],'#ac9672');rect((10,23,23,35),'#58674e')
save(sculpt(im,32,48),'enemies')
print('Generated',len(list(OUT.glob('*.png'))),'original 16-bit sheets;',len(kinds),'enemy silhouettes')
# Carved Buddha and stupa silhouettes are independent reusable scene assets.
im,d=canvas(208,192)
d.ellipse((40,1,168,126),outline='#737b61',width=4)
d.ellipse((49,10,159,119),outline='#a3a17a',width=1)
for i in range(16):
    import math
    a=i*math.tau/16;x=104+round(math.cos(a)*60);y=64+round(math.sin(a)*60)
    d.rectangle((x-1,y-1,x+1,y+1),fill='#b6ad80')
d.ellipse((83,17,125,63),fill='#788677');d.ellipse((87,22,121,58),fill='#abb091')
d.polygon([(88,39),(93,55),(104,60),(116,54),(120,39)],fill='#9aab8e')
for y in range(17,29,4):
    for x in range(88+(2 if y%8 else 0),121,5):d.rectangle((x,y,x+2,y+2),fill='#526e66')
d.line((91,40,99,41),fill='#455f55',width=2);d.line((109,41,117,40),fill='#455f55',width=2)
d.line((104,41,102,49,106,49),fill='#748c76');d.line((98,53,110,53),fill='#637e6b')
d.polygon([(84,64),(124,64),(145,114),(162,139),(46,139),(63,114)],fill='#647e6d')
d.polygon([(87,64),(102,70),(76,123),(61,135),(49,134)],fill='#a6b08b')
d.polygon([(103,69),(123,66),(145,114),(153,134),(123,122)],fill='#859b7c')
for i in range(5):d.line((88+i*5,80+i*5,69+i*11,133),fill='#496b60',width=2)
d.line((73,82,64,113,94,122),fill='#b1b795',width=9);d.line((132,82,143,112,112,123),fill='#a4b08a',width=9)
d.ellipse((51,124,111,148),fill='#849c7d');d.ellipse((101,124,159,148),fill='#95a582')
d.line((57,132,103,136,150,132),fill='#b5ba95',width=2)
d.rectangle((20,149,188,174),fill='#596f62');d.rectangle((25,150,183,154),fill='#a3ac83')
for x in range(29,183,16):
    d.polygon([(x,157),(x+7,148),(x+14,157),(x+7,171)],fill='#9aab81')
    d.line((x+7,152,x+7,167),fill='#c0bb91')
d.rectangle((0,175,207,191),fill='#49675e');d.line((1,175,206,175),fill='#929f7b',width=2)
for x in range(6,202,21):d.rectangle((x,179,x+16,188),fill='#658071')
save(im,'buddha')
im,d=canvas(48,96)
d.rectangle((3,79,45,93),fill='#607365');d.line((3,80,45,80),fill='#a4ac8b',width=2)
for level in range(4):
    y=70-level*18; w=36-level*4;left=(48-w)//2
    d.rectangle((left+6,y-12,left+w-6,y+2),fill='#9ca88a')
    d.rectangle((22,y-9,26,y),fill='#425f55')
    d.polygon([(left,y-11),(24,y-22),(left+w,y-11),(left+w-2,y-8),(left+2,y-8)],fill='#3d5c56')
    d.line((left+3,y-11,left+w-3,y-11),fill='#7f9278')
d.line((24,0,24,10),fill='#c0af7c',width=2)
save(im,'stupa')
# Shared village furniture and field borders retain the old collision footprints.
im,d=canvas(32,32)
for x in [3,25]:
    d.polygon([(x,4),(x+2,1),(x+5,4),(x+5,31),(x,31)],fill='#6c7254')
    d.line((x+1,5,x+1,30),fill='#a09a6d')
for y in [11,22]:
    d.rectangle((0,y,31,y+4),fill='#7c7e59');d.line((0,y,31,y),fill='#b0a272')
for x in [5,27]:
    for y in [12,23]:d.point((x,y),fill='#344b3d')
save(im,'fence')
im,d=canvas(40,32)
d.polygon([(2,24),(6,12),(17,3),(30,6),(38,19),(34,29),(12,31)],fill='#4f685e')
d.polygon([(7,14),(17,5),(28,8),(27,14),(15,18)],fill='#97a38a')
d.polygon([(15,19),(29,15),(35,21),(31,27),(10,28)],fill='#6b8272')
d.line((6,25,31,28),fill='#334e47',width=2);d.line((17,7,25,9),fill='#c0c2a0')
for x,y in [(9,21),(13,27),(29,22)]:d.line((x,y,x+3,y),fill='#7a8f60')
save(im,'rock')
im,d=canvas(32,48)
d.rectangle((3,39,29,46),fill='#445e53');d.line((4,39,28,39),fill='#91a081')
d.polygon([(8,9),(12,3),(22,3),(27,9),(26,39),(7,39)],fill='#6e8470')
d.line((10,10,24,10),fill='#a1af8b');d.rectangle((12,14,21,34),fill='#4e6d5d')
for y in [16,20,25,29]:d.line((15,y,19,y+1),fill='#a3af89')
for x,y in [(6,36),(9,39),(24,36)]:d.line((x,y,x+3,y),fill='#5b8057')
save(im,'grave')
im,d=canvas(40,36)
d.rectangle((3,13,37,31),fill='#34493f');d.rounded_rectangle((4,6,36,20),radius=3,fill='#8b7b54')
for y in [8,13,18]:d.line((6,y,34,y),fill='#af9566')
d.rectangle((5,21,35,30),fill='#6b6548');d.line((7,22,33,22),fill='#a28e5e')
for x in [9,29]:d.rectangle((x,7,x+3,30),fill='#486058');d.point((x+1,10),fill='#b4ad7c')
d.rectangle((18,16,23,25),fill='#c4ae70');d.rectangle((20,19,21,22),fill='#4c5743')
save(im,'chest')
im,d=canvas(64,64)
for y,left,right,c in [(51,4,59,'#405e53'),(43,9,54,'#607b65'),(33,15,49,'#3a564e'),(28,19,45,'#78876b')]:
    d.rectangle((left,y,right,y+8),fill=c);d.line((left+1,y,right-1,y),fill='#a6ac82')
for x in [18,42]:
    d.rectangle((x,10,x+4,28),fill='#c4b78d');d.line((x+1,12,x+1,25),fill='#e0d2a5')
    d.polygon([(x,8),(x+2,2),(x+5,7),(x+3,11)],fill='#8dbb9d')
d.rectangle((27,16,37,25),fill='#a59b70');d.line((31,17,31,23),fill='#655f48')
save(im,'altar')
for name in ['bed','workbench']:
    im,d=canvas(80,56 if name=='workbench' else 52)
    if name=='bed':
        d.rectangle((6,8,74,44),fill='#48544a');d.rectangle((10,12,70,40),fill='#b7b699')
        d.rectangle((12,14,27,36),fill='#ded0a3');d.rectangle((30,12,70,40),fill='#526f62')
        for y in [17,25,34]:d.line((32,y,68,y),fill='#7b9679')
        for x in [6,70]:d.rectangle((x,5,x+4,50),fill='#7c7152');d.line((x+1,6,x+1,47),fill='#b29b6c')
    else:
        for x in [10,64]:d.rectangle((x,31,x+6,55),fill='#4d5743')
        d.rectangle((2,16,77,39),fill='#48543f');d.rectangle((4,13,75,31),fill='#93835b')
        for y in [17,23,29]:d.line((5,y,74,y),fill='#b09c6a')
        d.rectangle((15,18,39,27),fill='#d0c193');d.line((18,20,33,25),fill='#8d654a')
        d.rectangle((55,8,59,21),fill='#c5b27c');d.rectangle((55,4,59,8),fill='#a2ceac')
    save(im,name)
# NPC portrait at the farm bridge is the elderly herbalist from the same sprite family.
im=Image.open(OUT/'villagers.png').crop((32,0,64,44));save(im,'npc')
print('Complete 16-bit art pack:',len(list(OUT.glob('*.png'))),'sheets')
