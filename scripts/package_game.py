"""Build the downloadable Yintian Godot source ZIP without caches or personal saves."""
from pathlib import Path
import zipfile
root=Path(__file__).resolve().parents[1]
paths=[root/'README.md']
paths.extend(p for folder in ['godot','scripts','docs','artifacts'] for p in (root/folder).rglob('*') if p.is_file() and '.godot' not in p.parts and '__pycache__' not in p.parts)
output=root/'yintian-godot.zip'
with zipfile.ZipFile(output,'w',zipfile.ZIP_DEFLATED) as archive:
 for path in sorted(paths):archive.write(path,Path('yintian')/path.relative_to(root))
with zipfile.ZipFile(output) as archive:
 assert archive.testzip() is None
 assert 'yintian/godot/project.godot' in archive.namelist()
 assert all('yintian/artifacts/enemy-packs/'+pack+'.zip' in archive.namelist() for pack in ['drowned','skeleton','tengu','hungry','rakshasa'])
 assert not any('/.godot/' in n or 'farm-save.json' in n for n in archive.namelist())
 assert output.stat().st_size < 100 * 1024 * 1024, 'Engineering ZIP exceeds GitHub single-file limit'
 print('Verified package:',len(archive.namelist()),'files,',output.stat().st_size,'bytes')
