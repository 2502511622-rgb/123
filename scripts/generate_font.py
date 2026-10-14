"""Optional: subset an installed Noto Sans CJK font for this game's Chinese UI.
Usage: python scripts/generate_font.py /path/to/NotoSansCJK-Regular.ttc
Requires fonttools. Keep the original OFL notice with the generated font.
"""
from pathlib import Path
import sys
from fontTools import subset
from fontTools.ttLib import TTFont
root=Path(__file__).resolve().parents[1]
source=Path(sys.argv[1])
text=''.join(p.read_text() for p in (root/'godot').rglob('*') if p.suffix in ('.gd','.tres'))
text += ''.join(chr(i) for i in range(32,127))+'青苔牧场晴雨春日自动存档0123456789×—→：。！'
font=TTFont(str(source),fontNumber=2 if source.suffix=='.ttc' else -1)
options=subset.Options();options.name_IDs=['*'];options.name_legacy=True;options.name_languages=['*']
s=subset.Subsetter(options=options);s.populate(text=text);s.subset(font)
rename={1:'Mossfield UI',2:'Regular',3:'MossfieldUI-Regular-0.2',4:'Mossfield UI Regular',6:'MossfieldUI-Regular',16:'Mossfield UI',17:'Regular',18:'Mossfield UI Regular'}
for name in font['name'].names:
 if name.nameID in rename:
  name.string=rename[name.nameID].encode(name.getEncoding())
font.save(root/'godot/assets/mossfield-font.ttf')
print('Generated renamed OFL subset font')
