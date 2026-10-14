"""Original eight-second fictional rural night ambience; Python standard library only."""
from pathlib import Path
import math,random,wave,struct
path=Path(__file__).resolve().parents[1]/'godot/assets/ambience.wav'
sample_rate=22050
rng=random.Random(37)
frames=bytearray()
wind=0.0
for i in range(sample_rate*8):
 t=i/sample_rate
 wind=wind*.985+rng.uniform(-1,1)*.015
 fade=min(1,t/.25,(8-t)/.25)
 tone=.13*math.sin(2*math.pi*146.83*t)+.07*math.sin(2*math.pi*220*t)
 pulse=max(0,1-(t%2)/.9)
 chime=.2*math.sin(2*math.pi*587.33*t)*pulse*math.exp(-(t%2)*4)
 value=(wind*.4+tone*.35+chime)*fade
 frames+=struct.pack('<h',int(max(-1,min(1,value))*32767))
with wave.open(str(path),'wb') as output:
 output.setparams((1,2,sample_rate,0,'NONE','not compressed'))
 output.writeframes(frames)
print('Generated original ambient loop')
