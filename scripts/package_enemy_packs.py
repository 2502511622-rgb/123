"""Export five self-contained 64px enemy art packs, without Godot import caches."""
from pathlib import Path
import json
import zipfile

root = Path(__file__).resolve().parents[1]
source = root / "godot/assets/enemy_packs"
output = root / "artifacts/enemy-packs"
output.mkdir(parents=True, exist_ok=True)
for pack in ("drowned", "skeleton", "tengu", "hungry", "rakshasa"):
    folder = source / pack
    manifest = json.loads((folder / "manifest.json").read_text())
    assert manifest["cell_size"] == [64, 64]
    with zipfile.ZipFile(output / f"{pack}.zip", "w", zipfile.ZIP_DEFLATED) as archive:
        for path in sorted(folder.rglob("*")):
            if path.is_file() and path.suffix in (".png", ".json", ".md"):
                archive.write(path, Path(pack) / path.relative_to(folder))
        archive.writestr(f"{pack}/README.txt", (
            "YinGui World modular enemy pack v0.25\n"
            "All cells: 64 x 64 RGBA, shared 24-color palette, nearest filtering.\n"
            "Root: (32,61). Left/right refer to the authored unmirrored character.\n"
            "parts/: body, head, left/right whole arms and legs; no cut-up fragments.\n"
            "stumps/: four shoulder/thigh overlays plus neck overlay, separate layers.\n"
            "residual.png: body + head only, no arms or legs.\n"
            "idle.png: 4 frames; walk.png: 8 frames; hit.png: 3 frames.\n"
            "blood/: drop, stain and splash; each uses the same 64px cell convention.\n"
            "atlas.png and manifest.json describe all cells and anatomical pivots.\n"
            "Animations are baked from the same transforms as the game's modular rig.\n"
            "Runtime uses separate Sprite2D limbs, not complete-frame substitutions.\n"
            "Art: generated for this project, then normalized and palette-indexed.\n"
        ))
    with zipfile.ZipFile(output / f"{pack}.zip") as archive:
        assert archive.testzip() is None
        print(pack, len(archive.namelist()), "files", (output / f"{pack}.zip").stat().st_size, "bytes")
