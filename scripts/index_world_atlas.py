"""Update measured world-prop regions; all generated original pixels are retained."""
from pathlib import Path
from atlas_regions import grid_regions
root=Path(__file__).resolve().parents[1]
names='cottage store tree tree_pine tree_autumn rock grave lantern fence chest altar stupa buddha workbench bed sign reeds fern cabbage torii well shrine fallen_gate brazier'.split()
regions=grid_regions(root/'godot/assets/world22/props.png',6,4)
path=root/'godot/scripts/art/world_art.gd';source=path.read_text();begin=source.index('const REGIONS =');end=source.index('const SIZES =',begin)
block='const REGIONS = {\n'+',\n'.join('\t"%s": Rect2(%s)'%(name,','.join(map(str,region))) for name,region in zip(names,regions))+'\n}\n'
path.write_text(source[:begin]+block+source[end:]);print('Indexed',len(regions),'world props')
