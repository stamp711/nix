"""Build a .mobileconfig that installs every font in a directory.

One com.apple.font payload per file, since a payload carries a single font.

Refuses .ttc/.otc collections and reports PostScript name collisions, both of
which Apple leaves undefined rather than rejecting.
"""

import argparse
import plistlib
import struct
import sys
import uuid
from pathlib import Path
from typing import cast

# Same input, same UUIDs, so regenerating a profile is not a diff and
# reinstalling replaces the old one instead of adding a second copy.
NAMESPACE = uuid.UUID("6f5e0d4c-3b2a-5190-8f7e-6d5c4b3a2910")

SFNT_VERSIONS = {b"\x00\x01\x00\x00", b"OTTO", b"true", b"typ1"}
POSTSCRIPT_NAME_ID = 6


class NotAFont(Exception):
    pass


def postscript_name(data: bytes) -> str:
    """Read nameID 6 out of the font's name table."""
    if data[:4] == b"ttcf":
        raise NotAFont("font collection")
    if data[:4] not in SFNT_VERSIONS:
        raise NotAFont("not an sfnt font")

    (table_count,) = cast(tuple[int], struct.unpack(">H", data[4:6]))
    for i in range(table_count):
        record = 12 + i * 16
        tag = data[record : record + 4]
        if tag != b"name":
            continue
        offset, length = cast(
            tuple[int, int], struct.unpack(">II", data[record + 8 : record + 16])
        )
        return _name_record(data[offset : offset + length])
    raise NotAFont("no name table")


def _name_record(table: bytes) -> str:
    count, strings_at = cast(tuple[int, int], struct.unpack(">HH", table[2:6]))
    # Windows records are UTF-16BE, Macintosh ones single-byte; prefer either
    # over the obsolete platforms, and take the first match.
    for i in range(count):
        record = 6 + i * 12
        platform, _, _, name_id, length, offset = cast(
            tuple[int, int, int, int, int, int],
            struct.unpack(">HHHHHH", table[record : record + 12]),
        )
        if name_id != POSTSCRIPT_NAME_ID:
            continue
        raw = table[strings_at + offset : strings_at + offset + length]
        if platform == 3:
            return raw.decode("utf-16-be", "replace")
        if platform == 1:
            return raw.decode("mac-roman", "replace")
    raise NotAFont("no PostScript name")


def font_payload(
    path: Path, data: bytes, ps_name: str, profile_id: str
) -> dict[str, object]:
    payload_id = f"{profile_id}.{ps_name}"
    return {
        "PayloadType": "com.apple.font",
        "PayloadVersion": 1,
        "PayloadIdentifier": payload_id,
        "PayloadUUID": str(uuid.uuid5(NAMESPACE, payload_id)).upper(),
        "PayloadDisplayName": ps_name,
        "Name": path.name,
        "Font": data,
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    _ = parser.add_argument("directory", type=Path)
    _ = parser.add_argument("-o", "--output", type=Path, required=True)
    _ = parser.add_argument("--identifier", default="net.apric.fonts")
    _ = parser.add_argument("--name", default="Fonts")
    args = parser.parse_args()

    # Namespace attributes are Any, so name them once with types here.
    directory = cast(Path, args.directory)
    output = cast(Path, args.output)
    identifier = cast(str, args.identifier)
    display_name = cast(str, args.name)

    payloads: list[dict[str, object]] = []
    seen: dict[str, Path] = {}
    collisions: list[tuple[str, Path, Path]] = []
    skipped: list[tuple[Path, str]] = []

    for path in sorted(directory.rglob("*")):
        if not path.is_file() or path.suffix.lower() not in {
            ".ttf",
            ".otf",
            ".ttc",
            ".otc",
        }:
            continue
        data = path.read_bytes()
        try:
            ps_name = postscript_name(data)
        except NotAFont as why:
            skipped.append((path, str(why)))
            continue
        if ps_name in seen:
            collisions.append((ps_name, seen[ps_name], path))
            continue
        seen[ps_name] = path
        payloads.append(font_payload(path, data, ps_name, identifier))

    for path, why in skipped:
        print(f"skipped {path}: {why}", file=sys.stderr)
    for ps_name, first, second in collisions:
        print(
            f"skipped {second}: PostScript name {ps_name} already taken by {first}",
            file=sys.stderr,
        )

    if not payloads:
        print("no installable fonts found", file=sys.stderr)
        return 1

    profile = {
        "PayloadType": "Configuration",
        "PayloadVersion": 1,
        "PayloadIdentifier": identifier,
        "PayloadUUID": str(uuid.uuid5(NAMESPACE, identifier)).upper(),
        "PayloadDisplayName": display_name,
        "PayloadContent": payloads,
    }
    _ = output.write_bytes(plistlib.dumps(profile))
    print(f"{len(payloads)} fonts -> {output}", file=sys.stderr)
    return 0


if __name__ == "__main__":
    sys.exit(main())
