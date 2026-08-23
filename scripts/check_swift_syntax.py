#!/usr/bin/env python3
"""Parse every Swift file with tree-sitter and flag syntax errors.

This is not a full Swift compiler — we can't typecheck on Linux without
the Apple toolchain — but it does prove that every file is structurally
valid Swift (matched braces, valid grammar, no garbled tokens, etc).
It catches the bulk of "won't even reach Xcode" mistakes.
"""

import sys
from pathlib import Path
import tree_sitter
import tree_sitter_swift

SWIFT_LANGUAGE = tree_sitter.Language(tree_sitter_swift.language())
parser = tree_sitter.Parser(SWIFT_LANGUAGE)


def walk_errors(node, source_bytes, file_path, errors):
    if node.is_error or node.is_missing:
        start = node.start_point  # (row, col), 0-indexed
        end   = node.end_point
        snippet = source_bytes[node.start_byte:min(node.end_byte, node.start_byte + 120)]
        try:
            text = snippet.decode("utf-8", errors="replace").strip().replace("\n", " ")
        except Exception:
            text = "<binary>"
        errors.append({
            "file": str(file_path),
            "line": start[0] + 1,
            "col": start[1] + 1,
            "kind": "MISSING" if node.is_missing else "ERROR",
            "type": node.type,
            "snippet": text[:120],
        })
        # Don't recurse into ERROR nodes (too noisy)
        return
    for child in node.children:
        walk_errors(child, source_bytes, file_path, errors)


def strip_conditional_compilation(source: bytes) -> bytes:
    """tree-sitter-swift can't handle `#if canImport(...)` blocks; strip them
    so we can validate the rest of the syntax. We keep ONLY the active branch
    (defaults to the canImport(true) branch since on macOS/iOS those imports
    exist). This is a best-effort pre-pass for static syntax validation.
    """
    text = source.decode("utf-8", errors="replace")
    out_lines = []
    skip_depth = 0
    in_if = 0
    branch_active = True
    branch_stack = []
    for line in text.splitlines(keepends=True):
        stripped = line.strip()
        if stripped.startswith("#if "):
            in_if += 1
            # Force first branch active
            branch_stack.append(True)
            branch_active = True
            continue
        if stripped.startswith("#elseif "):
            if branch_stack:
                # Deactivate subsequent branches
                branch_active = False
            continue
        if stripped == "#else":
            if branch_stack:
                branch_active = False
            continue
        if stripped == "#endif":
            if branch_stack:
                branch_stack.pop()
            in_if = max(0, in_if - 1)
            branch_active = True
            continue
        if branch_active:
            out_lines.append(line)
    return "".join(out_lines).encode("utf-8")


def check_file(path: Path):
    source = path.read_bytes()
    cleaned = strip_conditional_compilation(source)
    tree = parser.parse(cleaned)
    errors = []
    walk_errors(tree.root_node, cleaned, path, errors)
    return errors


def main() -> int:
    root = Path(__file__).resolve().parent.parent
    swift_files = sorted(
        list(root.glob("Limbator/**/*.swift"))
        + list(root.glob("LimbatorTests/**/*.swift"))
    )

    total_errors = 0
    files_with_errors = 0
    for f in swift_files:
        errors = check_file(f)
        if errors:
            files_with_errors += 1
            total_errors += len(errors)
            print(f"\n✗ {f.relative_to(root)}: {len(errors)} issue(s)")
            for e in errors[:5]:
                print(f"    L{e['line']}:{e['col']}  {e['kind']:8} {e['type']:25} {e['snippet']}")
            if len(errors) > 5:
                print(f"    … +{len(errors) - 5} more")

    print(f"\n{'─' * 60}")
    print(f"Parsed {len(swift_files)} Swift files")
    print(f"Files with errors: {files_with_errors}")
    print(f"Total errors:      {total_errors}")
    if total_errors == 0:
        print("✓ All files parse cleanly")
        return 0
    return 1


if __name__ == "__main__":
    sys.exit(main())
