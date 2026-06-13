#!/usr/bin/env python3
"""将 Make Me a Hanzi 的 graphics.txt 批量转为项目字库 JSON 格式。

graphics.txt 每行一个 JSON 对象，常见字段：
  character, strokes, medians（可选）

输出格式与 assets/hanzi_dictionary.json 一致：
  [
    {
      "character": "永",
      "convention": "makemeahanzi1024",
      "viewBoxWidth": 1024,
      "viewBoxHeight": 1024,
      "strokes": ["M ...", ...]
    },
    ...
  ]

本机若无 Python，请使用 Dart 版（推荐）：
  dart run tool/convert_mmah_to_dictionary.dart -i graphics.txt -o assets/hanzi_dictionary.json --chars 一,二,永

用法示例：

  # 下载数据（需自行确认仓库路径/许可）
  curl -L -o graphics.txt \\
    https://raw.githubusercontent.com/skishore/makemeahanzi/master/graphics.txt

  # 仅转换指定汉字（推荐：体积小、适合打包进 App）
  python scripts/convert_mmah_to_dictionary.py \\
    -i graphics.txt \\
    -o assets/hanzi_dictionary.json \\
    --chars 一,二,三,永,好

  # 从文件读取要转换的字（每行一字）
  python scripts/convert_mmah_to_dictionary.py \\
    -i graphics.txt -o out.json --chars-file chars.txt

  # 转换全部（约 9000+ 字，输出可达数十 MB）
  python scripts/convert_mmah_to_dictionary.py -i graphics.txt -o assets/hanzi_dictionary.json --all

  # 合并到已有字库（同字覆盖）
  python scripts/convert_mmah_to_dictionary.py \\
    -i graphics.txt -o assets/hanzi_dictionary.json \\
    --chars 永 --merge
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from typing import Any


DEFAULT_CONVENTION = "makemeahanzi1024"
DEFAULT_VIEWBOX = 1024


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="将 Make Me a Hanzi graphics.txt 转为 hanzi_dictionary.json"
    )
    parser.add_argument(
        "-i",
        "--input",
        required=True,
        type=Path,
        help="Make Me a Hanzi graphics.txt 路径",
    )
    parser.add_argument(
        "-o",
        "--output",
        type=Path,
        default=Path("assets/hanzi_dictionary.json"),
        help="输出 JSON 路径（默认 assets/hanzi_dictionary.json）",
    )
    group = parser.add_mutually_exclusive_group()
    group.add_argument(
        "--chars",
        type=str,
        help="仅转换这些汉字，逗号分隔，如：一,二,永",
    )
    group.add_argument(
        "--chars-file",
        type=Path,
        help="每行一个汉字的文本文件",
    )
    group.add_argument(
        "--all",
        action="store_true",
        help="转换 graphics.txt 中的全部汉字（体积较大）",
    )
    parser.add_argument(
        "--merge",
        action="store_true",
        help="与已有输出文件合并；相同汉字以本次转换结果为准",
    )
    parser.add_argument(
        "--include-medians",
        action="store_true",
        help="保留 medians 字段（练字绘制不需要，会显著增大体积）",
    )
    parser.add_argument(
        "--indent",
        type=int,
        default=None,
        metavar="N",
        help="JSON 缩进空格数；省略则紧凑输出",
    )
    parser.add_argument(
        "--progress-every",
        type=int,
        default=500,
        help="每处理多少行打印一次进度（默认 500，0 表示关闭）",
    )
    return parser.parse_args()


def load_char_filter(args: argparse.Namespace) -> set[str] | None:
    if args.all:
        return None
    if args.chars:
        chars = {c.strip() for part in args.chars.split(",") for c in part if c.strip()}
        if not chars:
            raise SystemExit("--chars 未包含有效汉字")
        return chars
    if args.chars_file:
        text = args.chars_file.read_text(encoding="utf-8")
        chars = {line.strip() for line in text.splitlines() if line.strip()}
        if not chars:
            raise SystemExit(f"--chars-file 为空：{args.chars_file}")
        return chars
    raise SystemExit("请指定 --chars、--chars-file 或 --all 之一")


def to_dictionary_entry(
    raw: dict[str, Any],
    *,
    include_medians: bool,
) -> dict[str, Any]:
    character = raw.get("character")
    if not isinstance(character, str) or not character:
        raise ValueError("缺少有效的 character 字段")
    ch = character[0]

    strokes = raw.get("strokes")
    if not isinstance(strokes, list) or not strokes:
        raise ValueError("strokes 必须为非空数组")
    path_list = []
    for stroke in strokes:
        if not isinstance(stroke, str) or not stroke.strip():
            raise ValueError("strokes 元素应为非空字符串")
        path_list.append(stroke.strip())

    entry: dict[str, Any] = {
        "character": ch,
        "convention": DEFAULT_CONVENTION,
        "viewBoxWidth": int(raw.get("viewBoxWidth", DEFAULT_VIEWBOX)),
        "viewBoxHeight": int(raw.get("viewBoxHeight", DEFAULT_VIEWBOX)),
        "strokes": path_list,
    }

    if include_medians and "medians" in raw:
        entry["medians"] = raw["medians"]

    return entry


def read_graphics_txt(
    input_path: Path,
    *,
    char_filter: set[str] | None,
    include_medians: bool,
    progress_every: int,
) -> tuple[dict[str, dict[str, Any]], dict[str, int]]:
    if not input_path.is_file():
        raise SystemExit(f"输入文件不存在：{input_path}")

    found: dict[str, dict[str, Any]] = {}
    stats = {
        "lines_read": 0,
        "lines_skipped_empty": 0,
        "lines_skipped_filter": 0,
        "lines_invalid": 0,
        "duplicates": 0,
    }

    with input_path.open(encoding="utf-8") as f:
        for line_no, line in enumerate(f, 1):
            stripped = line.strip()
            if not stripped or stripped.startswith("#"):
                stats["lines_skipped_empty"] += 1
                continue

            stats["lines_read"] += 1
            if progress_every and stats["lines_read"] % progress_every == 0:
                print(
                    f"  已扫描 {stats['lines_read']} 行，已匹配 {len(found)} 字…",
                    file=sys.stderr,
                )

            try:
                raw = json.loads(stripped)
            except json.JSONDecodeError as exc:
                stats["lines_invalid"] += 1
                print(f"警告：第 {line_no} 行 JSON 无效，已跳过：{exc}", file=sys.stderr)
                continue

            if not isinstance(raw, dict):
                stats["lines_invalid"] += 1
                print(f"警告：第 {line_no} 行根节点不是对象，已跳过", file=sys.stderr)
                continue

            character = raw.get("character")
            if not isinstance(character, str) or not character:
                stats["lines_invalid"] += 1
                print(f"警告：第 {line_no} 行缺少 character，已跳过", file=sys.stderr)
                continue

            ch = character[0]
            if char_filter is not None and ch not in char_filter:
                stats["lines_skipped_filter"] += 1
                continue

            try:
                entry = to_dictionary_entry(raw, include_medians=include_medians)
            except ValueError as exc:
                stats["lines_invalid"] += 1
                print(f"警告：第 {line_no} 行「{ch}」格式错误，已跳过：{exc}", file=sys.stderr)
                continue

            if ch in found:
                stats["duplicates"] += 1
            found[ch] = entry

            if char_filter is not None and len(found) == len(char_filter):
                break

    return found, stats


def load_existing_dictionary(path: Path) -> dict[str, dict[str, Any]]:
    if not path.is_file():
        return {}
    data = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(data, list):
        raise SystemExit(f"已有字库根节点必须是数组：{path}")
    out: dict[str, dict[str, Any]] = {}
    for item in data:
        if not isinstance(item, dict):
            continue
        ch = item.get("character")
        if isinstance(ch, str) and ch:
            out[ch[0]] = item
    return out


def write_dictionary(
    entries: list[dict[str, Any]],
    output_path: Path,
    *,
    indent: int | None,
) -> None:
    output_path.parent.mkdir(parents=True, exist_ok=True)
    if indent is None:
        payload = json.dumps(entries, ensure_ascii=False, separators=(",", ":"))
    else:
        payload = json.dumps(entries, ensure_ascii=False, indent=indent)
    output_path.write_text(payload + "\n", encoding="utf-8")


def main() -> None:
    args = parse_args()
    char_filter = load_char_filter(args)

    print(f"读取：{args.input}", file=sys.stderr)
    if char_filter is None:
        print("模式：转换全部汉字", file=sys.stderr)
    else:
        print(f"模式：仅转换 {len(char_filter)} 个指定汉字", file=sys.stderr)

    found, stats = read_graphics_txt(
        args.input,
        char_filter=char_filter,
        include_medians=args.include_medians,
        progress_every=args.progress_every,
    )

    if char_filter is not None:
        missing = sorted(char_filter - set(found.keys()))
        if missing:
            preview = "、".join(missing[:20])
            suffix = f" 等共 {len(missing)} 字" if len(missing) > 20 else ""
            print(f"警告：graphics.txt 中未找到：{preview}{suffix}", file=sys.stderr)

    merged: dict[str, dict[str, Any]]
    if args.merge:
        existing = load_existing_dictionary(args.output)
        existing.update(found)
        merged = existing
        print(f"合并：原有 {len(existing) - len(found)} 字 + 新增/覆盖 {len(found)} 字", file=sys.stderr)
    else:
        merged = found

    entries = sorted(merged.values(), key=lambda e: ord(e["character"]))
    write_dictionary(entries, args.output, indent=args.indent)

    size_kb = args.output.stat().st_size / 1024
    print(file=sys.stderr)
    print("完成", file=sys.stderr)
    print(f"  输出：{args.output}（{size_kb:.1f} KB，{len(entries)} 字）", file=sys.stderr)
    print(f"  扫描行数：{stats['lines_read']}", file=sys.stderr)
    if stats["lines_skipped_filter"]:
        print(f"  过滤跳过：{stats['lines_skipped_filter']}", file=sys.stderr)
    if stats["lines_invalid"]:
        print(f"  无效行：{stats['lines_invalid']}", file=sys.stderr)
    if stats["duplicates"]:
        print(f"  重复字（后者覆盖）：{stats['duplicates']}", file=sys.stderr)


if __name__ == "__main__":
    main()
