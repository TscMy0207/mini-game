from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path


def sha256(path: Path) -> str:
    # 分块计算摘要，避免大 PCK 在构建时一次性占用大量内存。
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def main() -> None:
    # Manifest 是 CDN 的索引文件，运行时据此定位并校验每个内容包。
    parser = argparse.ArgumentParser(description="Build a versioned content manifest")
    parser.add_argument("root", type=Path, help="Published CDN root")
    parser.add_argument("--platform", default="all")
    parser.add_argument("--version", required=True)
    parser.add_argument("--framework-version", default="0.1.0")
    parser.add_argument("--engine-version", default="4.7.2")
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()

    root = args.root.resolve()
    packs = []
    for path in sorted(root.rglob("*.pck")):
        relative = path.relative_to(root).as_posix()
        packs.append({
            "id": path.stem,
            "version": args.version,
            "url": relative,
            "size": path.stat().st_size,
            "sha256": sha256(path),
        })

    manifest = {
        "schema": 1,
        "app_version": args.version,
        "framework_version": args.framework_version,
        "engine_version": args.engine_version,
        "platform": args.platform,
        "packs": packs,
    }
    output = args.output or root / "manifest.json"
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(manifest, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(f"Wrote {output} with {len(packs)} pack(s)")


if __name__ == "__main__":
    main()
