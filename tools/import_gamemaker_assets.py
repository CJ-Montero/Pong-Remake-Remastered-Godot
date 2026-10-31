"""Copy registered GameMaker assets and generate Godot bitmap fonts/metadata.

Run from any directory with Python 3. Source files are never rewritten.
"""
from pathlib import Path
import hashlib
import json
import re
import shutil
import subprocess

DEST = Path(__file__).resolve().parents[1]
SOURCE = DEST.parent


def load_yy(path):
    # GameMaker serializes JSON with trailing commas.
    return json.loads(re.sub(r",\s*([}\]])", r"\1", path.read_text(encoding="utf-8-sig")))


def write(path, text):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding="utf-8")


def copy(source, target):
    target.parent.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(source, target)
    assert hashlib.sha256(source.read_bytes()).digest() == hashlib.sha256(target.read_bytes()).digest()


def main():
    project = load_yy(SOURCE / "Pong Remake.yyp")
    sprite_data = {}
    imported_fonts = 0
    for resource in project["resources"]:
        path = SOURCE / resource["id"]["path"]
        data = load_yy(path)
        name = data["name"]
        kind = data["resourceType"]
        if kind == "GMSprite":
            frames = data["frames"]
            assert len(frames) == 1, "Animated sprites need explicit frame conversion"
            copy(path.parent / (frames[0]["name"] + ".png"), DEST / "assets/sprites" / (name + ".png"))
            sprite_data[name] = {
                "origin": [data["sequence"]["xorigin"], data["sequence"]["yorigin"]],
                "size": [data["width"], data["height"]],
                "bbox": [data["bbox_left"], data["bbox_top"], data["bbox_right"], data["bbox_bottom"]],
                "collision_kind": data["collisionKind"],
            }
        elif kind == "GMSound":
            original = path.parent / data["soundFile"]
            assert original.read_bytes()[:4] == b"RIFF", "Expected WAV source"
            copy(original, DEST / "assets/audio" / (name + ".wav"))
        elif kind == "GMFont":
            if name == "fnt_creditos":
                # Not referenced by the active game; keeping it would only create noise.
                continue
            font_image = DEST / "assets/fonts" / (name + ".png")
            copy(path.with_suffix(".png"), font_image)
            # Godot BMFont rejects grayscale+alpha PNGs. Expand channels losslessly.
            if font_image.read_bytes()[25] != 6:
                subprocess.run([
                    "ffmpeg", "-v", "error", "-y", "-i", str(path.with_suffix(".png")),
                    "-pix_fmt", "rgba", "-update", "1", str(font_image),
                ], check=True)
            # Read PNG IHDR directly: no Pillow dependency.
            png = path.with_suffix(".png").read_bytes()
            width, height = int.from_bytes(png[16:20], "big"), int.from_bytes(png[20:24], "big")
            line_height = data["lineHeight"]
            glyphs = sorted(data["glyphs"].values(), key=lambda g: g["character"])
            lines = [
                f'info face="{data["fontName"]}" size={line_height} bold=0 italic=0 charset="" unicode=1 stretchH=100 smooth=1 aa=1 padding=0,0,0,0 spacing=0,0 outline=0',
                f'common lineHeight={line_height} base={data["ascender"]} scaleW={width} scaleH={height} pages=1 packed=0',
                f'page id=0 file="{name}.png"',
                f'chars count={len(glyphs)}',
            ]
            for g in glyphs:
                lines.append(f'char id={g["character"]} x={g["x"]} y={g["y"]} width={g["w"]} height={g["h"]} xoffset={g["offset"]} yoffset=0 xadvance={g["shift"]} page=0 chnl=15')
            lines.append("kernings count=0")
            write(DEST / "assets/fonts" / (name + ".fnt"), "\n".join(lines) + "\n")
            imported_fonts += 1
    write(DEST / "assets/sprites/metadata.json", json.dumps(sprite_data, indent=2) + "\n")
    source_files = [SOURCE / "Pong Remake.yyp"]
    for directory in ("objects", "rooms", "sprites", "sounds", "fonts", "notes", "options", "datafiles"):
        source_files.extend(p for p in (SOURCE / directory).rglob("*") if p.is_file())
    manifest = {str(p.relative_to(SOURCE)): hashlib.sha256(p.read_bytes()).hexdigest() for p in sorted(source_files)}
    write(DEST / "docs/source_sha256.json", json.dumps(manifest, indent=2) + "\n")
    print(f"Imported {len(sprite_data)} sprites, 7 WAV files and {imported_fonts} bitmap fonts; hashed {len(manifest)} source files.")


if __name__ == "__main__":
    main()
