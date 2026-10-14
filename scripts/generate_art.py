"""Generate original Yintian pixel assets. No external art or dependencies at runtime."""
from pathlib import Path
from PIL import Image, ImageDraw
import random
OUT = Path(__file__).resolve().parents[1] / 'godot/assets'
OUT.mkdir(parents=True, exist_ok=True)
rng=random.Random(42)
def image(w,h):
 im=Image.new('RGBA',(w,h));return im,ImageDraw.Draw(im)
def save(im,name):im.save(OUT/name)
# Tiles: eight grass variants, dry soil, wet soil, path, animated water frames.
im,d=image(16*16,16)
for i in range(16):
 x=i*16
 color='#7e8c69' if i<8 else ['#a27449','#74563d','#d9bd88','#679baf','#6fa4b5','#6697aa','#a9bb74','#759457'][i-8]
 d.rectangle((x,0,x+15,15),fill=color)
 if i<8:
  for j in range(7):
   a=x+rng.randrange(1,14);b=rng.randrange(2,14);d.line((a,b,a+1,b-2),fill=rng.choice(['#72825d','#8c9975','#82916b']))
 elif i in (8,9):
  for y in (3,7,11):d.line((x+2,y,x+13,y),fill='#88603f' if i==8 else '#654a36')
  d.point((x+4,14),fill='#b68956' if i==8 else '#85654c')
 elif i==10:
  for j in range(12):d.point((x+rng.randrange(16),rng.randrange(16)),fill=rng.choice(['#cdb27c','#e2c99a','#c5aa75']))
 elif i in (11,12,13):
  shift=i-11;d.line((x+2+shift,4,x+7+shift,4),fill='#9bc4c7');d.line((x+8-shift,11,x+13-shift,11),fill='#82b4bd')
 elif i==15:
  d.line((x,0,x+15,0),fill='#7c985c');d.line((x,0,x,15),fill='#7c985c')
  for j in range(6):
   a=x+rng.randrange(2,14);b=rng.randrange(3,14);d.line((a,b,a+1,b-2),fill=rng.choice(['#6f8c51','#819e5e']))
 elif i==14:
  for j in range(3):
   a=x+3+j*4;b=4+j*3;d.rectangle((a,b,a+1,b+1),fill='#eed49c');d.point((a+1,b),fill='#bd8058')
save(im,'tiles.png')
# A cottage: timber, plaster, layered terracotta roof, climbing vines.
im,d=image(80,68)
d.rectangle((5,21,73,59),fill='#74543b');d.rectangle((8,23,70,56),fill='#edc995')
for x in (8,38,68):d.rectangle((x,22,x+3,56),fill='#9a7049')
d.rectangle((5,52,73,60),fill='#b48a57')
for y in range(24,52,7):d.line((9,y,69,y),fill='#dab580')
for y in range(5,27):
 inset=max(0,(25-y)//2);d.line((3+inset,y,76-inset,y),fill=['#414c50','#536061','#647071','#485455'][y%4])
d.rectangle((2,25,77,28),fill='#794e39');d.rectangle((60,1,67,16),fill='#b8a38c');d.rectangle((59,1,68,3),fill='#867c70')
for x in (17,53):
 d.rectangle((x-2,33,x+13,47),fill='#956d48');d.rectangle((x,34,x+11,44),fill='#8bb3ae');d.line((x+5,34,x+5,44),fill='#e8c490');d.line((x,39,x+11,39),fill='#e8c490');d.rectangle((x-3,46,x+14,49),fill='#ba8450')
d.rectangle((34,36,46,59),fill='#604f3a');d.rectangle((36,38,44,56),fill='#916c48');d.point((43,47),fill='#dfbc70');d.rectangle((30,60,50,63),fill='#c4ad86');d.rectangle((28,64,52,66),fill='#d1bb90')
for x,y in [(9,43),(11,47),(7,39),(71,46),(69,49)]:d.rectangle((x,y,x+3,y+3),fill='#6d9253');d.point((x+1,y),fill='#a6b764')
# Small alternating tile seams, eave shade, aged plaster and foundation stones.
for y in (8,14,20):
 for x in range(10+(3 if y==14 else 0),71,7):
  d.line((x,y,x,y+3),fill='#39474b');d.point((x+1,y),fill='#7d8981')
d.line((5,29,73,29),fill='#4c4b3c');d.line((8,51,70,51),fill='#b19a70')
for x,y in [(13,30),(60,31),(23,49),(55,50)]:d.line((x,y,x+3,y),fill='#c2a475')
for x in range(6,72,8):d.rectangle((x,58,x+5,60),fill='#908675')
save(im,'cottage.png')
# General store with awning and produce crates.
im,d=image(64,58)
d.rectangle((6,17,57,49),fill='#d9b78a');d.rectangle((4,46,59,51),fill='#9d7850')
for y in range(18,46,5):d.line((7,y,56,y),fill='#c7a276')
for y in range(2,19):
 inset=max(0,(17-y)//2);d.line((2+inset,y,61-inset,y),fill=['#414c50','#536061','#647071'][y%3])
d.rectangle((1,17,62,20),fill='#465f53');d.rectangle((24,23,38,50),fill='#725b44');d.rectangle((27,26,35,40),fill='#8fb6b0')
for x in (9,43):d.rectangle((x,24,x+10,35),fill='#8ab0aa');d.line((x+5,24,x+5,35),fill='#ebd2a6')
for x in range(3,60,7):d.rectangle((x,20,x+6,25),fill='#dfb67e' if x%2 else '#f2ddad')
for x in (5,44):
 d.rectangle((x,43,x+14,53),fill='#a57b4d');d.line((x,48,x+14,48),fill='#d5a36a')
 for j in range(3):d.ellipse((x+2+j*4,41,x+5+j*4,45),fill='#bd7048' if x==5 else '#a1ad5b')
save(im,'store.png')
# Clustered canopy with stepped silhouette, bark and restrained highlights.
im,d=image(32,46)
d.polygon([(12,23),(19,23),(18,38),(23,43),(17,44),(15,41),(10,44),(8,43),(13,38)],fill='#384b3e')
d.rectangle((14,25,17,41),fill='#795d43');d.line((16,28,16,39),fill='#a08255')
clusters=[((4,17,28,34),'#344f43'),((2,12,29,28),'#41684b'),((5,7,26,26),'#507c50'),((9,3,22,20),'#5e8c56'),((3,15,15,26),'#5b8552'),((13,9,27,23),'#648d55'),((8,6,19,16),'#739b5b')]
for (x0,y0,x1,y1),color in clusters:
 d.polygon([(x0+3,y0),(x1-3,y0),(x1,y0+3),(x1,y1-3),(x1-3,y1),(x0+3,y1),(x0,y1-3),(x0,y0+3)],fill=color)
for x,y in [(10,7),(15,5),(20,11),(6,17),(12,21),(23,18),(8,26)]:
 d.line((x,y,x+3,y),fill='#97b76c');d.point((x-1,y+1),fill='#7fa662')
for x,y in [(18,27),(6,24),(24,24),(10,30)]:d.line((x,y,x+3,y),fill='#304e40')
save(im,'tree.png')
# Fence, chest, rock and flowers packed separately.
im,d=image(16,16);d.rectangle((1,2,3,15),fill='#b28a58');d.rectangle((12,2,14,15),fill='#b28a58');d.rectangle((0,5,15,7),fill='#d4b079');d.rectangle((0,10,15,12),fill='#cca56a');d.point((2,5),fill='#775e41');d.point((13,10),fill='#775e41');save(im,'fence.png')
im,d=image(20,18);d.rectangle((1,5,18,15),fill='#865e3d');d.rectangle((2,2,17,8),fill='#bc8a53');d.line((2,5,17,5),fill='#d2a166');d.rectangle((3,8,16,14),fill='#a77a48');d.rectangle((8,6,10,11),fill='#e2bb65');save(im,'chest.png')
im,d=image(20,16);d.polygon([(1,12),(3,5),(8,1),(15,3),(19,9),(17,14),(4,15)],fill='#858b7d');d.polygon([(3,6),(8,2),(14,4),(13,7),(7,8)],fill='#aeb29a');d.line((5,13,16,13),fill='#656f66');save(im,'rock.png')
# Four-direction farmer animation; four frames per direction.
im,d=image(64,80)
for row in range(4):
 for frame in range(4):
  x=frame*16;y=row*20;step=[0,1,0,-1][frame]
  def r(box,c):d.rectangle(tuple(v+(x if i%2==0 else y) for i,v in enumerate(box)),fill=c)
  r((5,15,7,18+max(step,0)),'#5a4c42');r((9,15,11,18+max(-step,0)),'#5a4c42');r((4,10,12,15),'#696a4c');r((5,10,6,14),'#c5ad74');r((3,11,4,14),'#d6a576');r((12,11,13,14),'#d6a576')
  r((5,5,11,10),'#edc18c');r((4,4,12,6),'#815536')
  if row==1:r((5,5,11,9),'#815536')
  elif row==0:r((6,7,6,7),'#41483a');r((10,7,10,7),'#41483a')
  else:r((5 if row==2 else 11,7,5 if row==2 else 11,7),'#41483a')
  r((4,1,12,4),'#393f49');r((3,4,13,5),'#4c5360');r((5,2,11,2),'#e9ca86');r((4,3,12,3),'#44484b')
save(im,'farmer.png')
# NPC in a green dress.
im,d=image(16,22)
d.rectangle((5,17,7,20),fill='#785746');d.rectangle((9,17,11,20),fill='#785746');d.polygon([(6,9),(11,9),(14,17),(3,17)],fill='#789767');d.rectangle((4,10,5,14),fill='#e0b78b');d.rectangle((12,10,13,14),fill='#e0b78b');d.rectangle((4,3,12,10),fill='#815a42');d.rectangle((5,5,11,10),fill='#ecc599');d.rectangle((4,2,12,5),fill='#a4764f');d.point((6,7),fill='#45493b');d.point((10,7),fill='#45493b');d.rectangle((10,2,12,3),fill='#e2b46c');save(im,'npc.png')
# Chicken frames.
im,d=image(32,16)
for frame in range(2):
 x=frame*16;d.rectangle((x+3,6,x+11,11),fill='#f1e3b7');d.rectangle((x+7,3,x+12,8),fill='#fff0cc');d.rectangle((x+8,2,x+11,3),fill='#bf6e50');d.rectangle((x+12,5,x+14,6),fill='#d4a45e');d.point((x+11,4),fill='#414b3d');d.rectangle((x+2,5,x+4,7),fill='#e1c994');d.line((x+5,12,x+5+frame,14),fill='#bc8c4d');d.line((x+10,12,x+10-frame,14),fill='#bc8c4d')
save(im,'chicken.png')
# Yin crops: candle millet, copper vine, spirit gourd, speaking rice.
im,d=image(96,64)
for row,color in enumerate(['#80b9a1','#a89755','#879c62','#c7c09b']):
 for stage in range(6):
  x=stage*16;y=row*16
  if stage==0:d.rectangle((x+7,y+12,x+9,y+13),fill='#b4a27d');continue
  h=min(9,stage*2);d.rectangle((x+7,y+12-h,x+8,y+13),fill='#526346');d.rectangle((x+3,y+10-h,x+6,y+12-h),fill='#819366');d.rectangle((x+9,y+8-h,x+12,y+10-h),fill='#657c56')
  if stage>=3:
   if row==0:
    d.rectangle((x+6,y+3,x+9,y+9),fill='#b4b886');d.rectangle((x+7,y+1,x+8,y+4),fill='#78c5bb');d.point((x+8,y),fill='#b5e3c3')
   elif row==1:
    for cx,cy in [(4,8),(10,6),(8,12)]:
     d.rectangle((x+cx,y+cy,x+cx+3,y+cy+3),fill=color);d.point((x+cx+1,y+cy+1),fill='#556141')
   elif row==2:
    d.rectangle((x+5,y+6,x+10,y+9),fill=color);d.rectangle((x+4,y+10,x+11,y+14),fill=color);d.rectangle((x+6,y+11,x+9,y+13),fill='#465744');d.point((x+6,y+12),fill='#b8c49b')
   else:
    for cx in (4,7,10):d.line((x+cx,y+3,x+cx+1,y+13),fill=color);d.rectangle((x+cx-1,y+4,x+cx+1,y+7),fill='#d3c8a3')
  if stage==5:d.point((x+13,y+3),fill='#83cabd')
save(im,'crops.png')
# Toolbar icons.
im,d=image(96,16)
d.line((3,13,11,3),fill='#b59461',width=2);d.rectangle((8,2,14,4),fill='#86958e');d.rectangle((11,4,14,6),fill='#86958e')
d.rectangle((20,3,28,13),fill='#d6bd83');d.rectangle((22,5,26,9),fill='#799452');d.line((24,6,24,11),fill='#547344')
d.rectangle((35,5,43,12),fill='#7eabb4');d.rectangle((37,3,42,5),outline='#527e8b');d.line((43,7,47,4),fill='#7eabb4',width=2);d.rectangle((34,7,35,10),fill='#a6c8cd')
d.rectangle((53,7,59,12),fill='#e3cea1');d.rectangle((55,4,56,7),fill='#5e884b');d.rectangle((51,3,54,5),fill='#739956');d.rectangle((57,2,60,4),fill='#739956')
d.line((68,13,75,3),fill='#aa865b',width=2);d.polygon([(73,2),(79,2),(80,7),(75,6)],fill='#b7c0ad');d.line((74,3,79,3),fill='#edf0cf')
d.line((84,13,90,4),fill='#aa865b',width=2);d.line((84,3,94,6),fill='#b7c0ad',width=2);d.point((84,4),fill='#e9e5c5')
save(im,'tools.png')


# Corpses, spirit silhouettes, ritual altar, tablets and paper lantern.
im,d=image(16,72)
for row in range(3):
 y=row*24
 if row==0:
  d.rectangle((4,y+7,12,y+18),fill='#50666a');d.rectangle((5,y+2,11,y+8),fill='#a9b7a2');d.rectangle((4,y+1,12,y+3),fill='#43505b');d.point((6,y+5),fill='#705c55');d.point((10,y+5),fill='#705c55');d.rectangle((2,y+9,4,y+15),fill='#768b79');d.rectangle((12,y+9,14,y+15),fill='#768b79');d.rectangle((6,y+18,7,y+22),fill='#4c534c');d.rectangle((10,y+18,11,y+22),fill='#4c534c')
 elif row==1:
  d.rectangle((5,y+3,11,y+9),fill='#c4c0a2');d.rectangle((4,y+4,12,y+7),fill='#c4c0a2');d.rectangle((5,y+5,7,y+6),fill='#414b46');d.rectangle((9,y+5,11,y+6),fill='#414b46');d.line((8,y+9,8,y+17),fill='#b1ad90');d.line((4,y+11,12,y+11),fill='#b1ad90');d.line((5,y+14,11,y+14),fill='#b1ad90');d.line((4,y+11,2,y+16),fill='#b1ad90');d.line((12,y+11,14,y+16),fill='#b1ad90');d.line((8,y+17,4,y+22),fill='#b1ad90');d.line((8,y+17,12,y+22),fill='#b1ad90')
 else:
  d.rectangle((2,y+2,14,y+22),fill='#423f49');d.rectangle((3,y+4,13,y+20),fill='#63534f');d.line((5,y+4,5,y+20),fill='#81715b');d.line((11,y+4,11,y+20),fill='#81715b');d.rectangle((6,y+6,10,y+12),fill='#b49a69');d.line((8,y+7,8,y+11),fill='#985a4e');d.rectangle((0,y+10,2,y+18),fill='#707060');d.rectangle((14,y+10,15,y+18),fill='#707060')
save(im,'enemies.png')
im,d=image(16,60)
for row in range(3):
 y=row*20
 if row<2:
  d.rectangle((5,y+2,11,y+8),fill='#a5b39b' if row==0 else '#c5bea0');d.rectangle((4,y+8,12,y+16),fill='#607578' if row==0 else '#a6a88a');d.rectangle((5,y+17,7,y+19),fill='#687165');d.rectangle((9,y+17,11,y+19),fill='#687165');d.point((6,y+5),fill='#48594f');d.point((10,y+5),fill='#48594f');d.rectangle((6,y+9,9,y+12),fill='#c2b686')
 else:
  d.rectangle((5,y+6,11,y+11),fill='#b3b7a0');d.rectangle((4,y+11,12,y+18),fill='#565f57');d.rectangle((6,y+3,10,y+6),fill='#525c54');d.rectangle((2,y+12,4,y+17),fill='#b99c65');d.point((6,y+9),fill='#4d5b4e');d.point((10,y+9),fill='#4d5b4e')
save(im,'spirits.png')
im,d=image(32,32);d.rectangle((2,24,29,29),fill='#6e7168');d.rectangle((6,16,25,24),fill='#4d5c59');d.rectangle((9,10,22,15),fill='#665f54');d.rectangle((10,4,12,10),fill='#c7b895');d.rectangle((20,4,22,10),fill='#c7b895');d.rectangle((10,1,12,4),fill='#89c5ab');d.rectangle((20,1,22,4),fill='#c38970');d.line((15,5,15,12),fill='#b1a682');save(im,'altar.png')
im,d=image(16,24);d.rectangle((3,8,13,21),fill='#797e6c');d.rectangle((4,3,12,8),fill='#8e947f');d.rectangle((6,7,10,17),fill='#646b5f');d.line((8,8,8,15),fill='#b7b59a');d.rectangle((1,20,15,23),fill='#626d61');save(im,'grave.png')
im,d=image(16,24);d.rectangle((7,0,8,22),fill='#6e6650');d.rectangle((3,3,12,12),fill='#b09d6b');d.rectangle((5,4,10,11),fill='#ccbb84');d.line((7,5,7,10),fill='#955f51');d.rectangle((5,2,10,3),fill='#776a53');d.rectangle((5,12,10,13),fill='#776a53');save(im,'lantern.png')
im,d=image(24,14);d.rectangle((2,3,21,11),fill='#72634f');d.rectangle((3,4,20,10),fill='#9da28a');d.rectangle((6,5,9,8),fill='#d0c8a2');d.rectangle((14,5,16,8),fill='#4f6158');save(im,'remains.png')

# Dedicated indoor furniture rather than reusing shipping crates.
im,d=image(40,26)
d.rectangle((2,5,37,22),fill='#443f35');d.rectangle((3,6,36,19),fill='#a38356')
d.rectangle((5,7,34,17),fill='#ced0b1');d.rectangle((6,8,12,15),fill='#ebe0bf')
d.rectangle((15,7,34,17),fill='#697f70');d.line((16,9,33,9),fill='#94aa89')
d.rectangle((2,2,4,25),fill='#795c43');d.rectangle((35,3,37,25),fill='#795c43')
save(im,'bed.png')
im,d=image(40,28)
d.rectangle((4,17,7,27),fill='#564938');d.rectangle((32,17,35,27),fill='#564938')
d.rectangle((1,7,38,19),fill='#5c4936');d.rectangle((2,6,37,15),fill='#a88b60');d.line((3,7,36,7),fill='#d1b181')
d.rectangle((8,8,19,13),fill='#e7d5a4');d.line((10,9,16,12),fill='#9b5f46')
d.rectangle((26,4,28,11),fill='#dac294');d.rectangle((26,2,28,4),fill='#8fc7b6');d.rectangle((24,11,30,13),fill='#595b49')
save(im,'workbench.png')
# Bag icons share the crop silhouettes; materials have distinct pixel shapes.
im,d=image(256,16)
crops=Image.open(OUT/'crops.png')
for index in range(8):
 x=index*16
 if index<4:
  d.rectangle((x+3,3,x+12,14),fill='#d3bc89');d.line((x+4,4,x+11,4),fill='#f0deaf')
  crop=crops.crop((80,index*16,96,index*16+16)).resize((8,8),Image.Resampling.NEAREST)
  im.alpha_composite(crop,(x+4,5))
 else:im.alpha_composite(crops.crop((80,(index-4)*16,96,(index-4)*16+16)),(x,0))
for index in range(8,16):
 x=index*16
 if index==8:
  d.rectangle((x+5,2,x+10,4),fill='#bba275');d.rectangle((x+3,5,x+12,13),fill='#839e92');d.rectangle((x+5,6,x+10,9),fill='#b3cab2')
 elif index==9:
  d.rectangle((x+4,1,x+11,14),fill='#e3c687');d.line((x+7,3,x+7,11),fill='#a65b49');d.line((x+5,6,x+10,6),fill='#a65b49')
 elif index==10:
  d.line((x+3,12,x+12,3),fill='#d7cfb1',width=3)
  for a,b in [(2,11),(4,13),(11,2),(13,4)]:d.rectangle((x+a,b,x+a+1,b+1),fill='#d7cfb1')
 elif index==11:
  d.polygon([(x+2,13),(x+4,8),(x+8,6),(x+13,12)],fill='#8a8f86');d.line((x+4,11,x+10,11),fill='#b5b6a0')
 elif index==12:
  d.polygon([(x+2,10),(x+10,2),(x+14,5),(x+6,14)],fill='#9a7450');d.line((x+5,11,x+12,4),fill='#c1a16e');d.line((x+3,11,x+6,14),fill='#644d3c')
 elif index==13:
  d.polygon([(x+2,12),(x+3,6),(x+7,2),(x+12,4),(x+14,10),(x+10,13)],fill='#939e91');d.line((x+5,5,x+10,4),fill='#c3c8af')
 elif index==14:
  d.rectangle((x+4,3,x+11,12),fill='#e3c184');d.line((x+7,4,x+7,10),fill='#a96753');d.line((x+3,2,x+12,2),fill='#5b6656');d.rectangle((x+7,13,x+8,15),fill='#d3a05e')
 else:
  d.rectangle((x+5,3,x+10,13),fill='#788880');d.polygon([(x+5,3),(x+7,1),(x+10,3)],fill='#adb39c');d.line((x+7,5,x+7,11),fill='#d4c092')
save(im,'items.png')
print('Generated original Yintian artwork:',len(list(OUT.glob('*.png'))),'sheets')
