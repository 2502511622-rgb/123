"""Build the downloadable Godot source ZIP without caches or personal saves."""
from pathlib import Path
import zipfile
root=Path(__file__).resolve().parents[1]
paths=[root/'README.md']
paths.extend(p for folder in ['godot','scripts','docs'] for p in (root/folder).rglob('*') if p.is_file() and '.godot' not in p.parts and '__pycache__' not in p.parts)
output=root/'mossfield-godot.zip'
with zipfile.ZipFile(output,'w',zipfile.ZIP_DEFLATED) as archive:
 for path in sorted(paths):archive.write(path,Path('mossfield')/path.relative_to(root))
with zipfile.ZipFile(output) as archive:
 assert archive.testzip() is None
 assert 'mossfield/godot/project.godot' in archive.namelist()
 assert not any('/.godot/' in n or 'farm-save.json' in n for n in archive.namelist())
 print('Verified package:',len(archive.namelist()),'files,',output.stat().st_size,'bytes')
