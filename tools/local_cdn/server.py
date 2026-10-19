from __future__ import annotations

import argparse
import http.server
import socketserver
from pathlib import Path


class Handler(http.server.SimpleHTTPRequestHandler):
    # PCK/WASM 使用明确 MIME，避免小游戏宿主把二进制内容当成文本处理。
    extensions_map = {
        **http.server.SimpleHTTPRequestHandler.extensions_map,
        ".pck": "application/octet-stream",
        ".json": "application/json; charset=utf-8",
        ".wasm": "application/wasm",
    }

    def end_headers(self) -> None:
        self.send_header("Cache-Control", "no-cache")
        super().end_headers()


def main() -> None:
    # 这是开发验证用的静态 CDN，不包含上传、鉴权或生产缓存策略。
    parser = argparse.ArgumentParser(description="Local static CDN for PCK update tests")
    parser.add_argument("--root", default=".", help="Directory to publish")
    parser.add_argument("--host", default="127.0.0.1")
    parser.add_argument("--port", type=int, default=8080)
    args = parser.parse_args()

    root = Path(args.root).resolve()
    if not root.is_dir():
        raise SystemExit(f"CDN root does not exist: {root}")

    handler = lambda *handler_args, **handler_kwargs: Handler(
        *handler_args,
        directory=str(root),
        **handler_kwargs,
    )
    with socketserver.ThreadingTCPServer((args.host, args.port), handler) as server:
        print(f"Serving {root} at http://{args.host}:{args.port}")
        server.serve_forever()


if __name__ == "__main__":
    main()
