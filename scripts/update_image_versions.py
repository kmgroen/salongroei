#!/usr/bin/env python3
"""
Update Image Versions Script

Automatically increments version numbers in src/utils/imageVersion.ts
after regenerating images (infographics, etc.)

Usage:
    python3 scripts/update_image_versions.py --increment infographics
    python3 scripts/update_image_versions.py --increment all
    python3 scripts/update_image_versions.py --set /images/infographics/no-shows.png 5
"""

import re
import sys
from pathlib import Path
from typing import Dict


def read_image_versions(file_path: Path) -> Dict[str, int]:
    """Parse imageVersion.ts and extract current versions"""
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Extract IMAGE_VERSIONS object
    pattern = r"'(/images/[^']+)':\s*(\d+)"
    matches = re.findall(pattern, content)

    return {path: int(version) for path, version in matches}


def write_image_versions(file_path: Path, versions: Dict[str, int]) -> None:
    """Write updated versions back to imageVersion.ts"""
    # Read current file
    with open(file_path, 'r', encoding='utf-8') as f:
        lines = f.readlines()

    # Find and update IMAGE_VERSIONS object
    new_lines = []
    in_versions_block = False

    for line in lines:
        if 'export const IMAGE_VERSIONS' in line:
            in_versions_block = True
            new_lines.append(line)
        elif in_versions_block and line.strip() == '};':
            in_versions_block = False
            new_lines.append(line)
        elif in_versions_block and "'/images/" in line:
            # Extract path from line
            path_match = re.search(r"'(/images/[^']+)'", line)
            if path_match:
                path = path_match.group(1)
                if path in versions:
                    # Replace version number
                    new_line = re.sub(r':\s*\d+', f': {versions[path]}', line)
                    new_lines.append(new_line)
                else:
                    new_lines.append(line)
            else:
                new_lines.append(line)
        else:
            new_lines.append(line)

    # Write back
    with open(file_path, 'w', encoding='utf-8') as f:
        f.writelines(new_lines)


def increment_versions(versions: Dict[str, int], prefix: str) -> Dict[str, int]:
    """Increment version numbers for paths matching prefix"""
    updated = versions.copy()
    count = 0

    for path in updated:
        if prefix == 'all' or path.startswith(prefix):
            updated[path] += 1
            count += 1

    print(f"✅ Incremented {count} image version(s)")
    return updated


def set_version(versions: Dict[str, int], path: str, version: int) -> Dict[str, int]:
    """Set specific version for a path"""
    updated = versions.copy()

    if path in updated:
        old_version = updated[path]
        updated[path] = version
        print(f"✅ Updated {path}: v{old_version} → v{version}")
    else:
        print(f"❌ Path not found: {path}")
        print(f"Available paths:")
        for p in sorted(updated.keys()):
            print(f"   {p}")

    return updated


def main():
    """Main entry point"""
    import argparse

    parser = argparse.ArgumentParser(
        description="Update image versions in imageVersion.ts"
    )
    parser.add_argument(
        '--increment',
        help='Increment versions for paths (e.g., "/images/infographics/" or "all")'
    )
    parser.add_argument(
        '--set',
        nargs=2,
        metavar=('PATH', 'VERSION'),
        help='Set specific version for a path'
    )

    args = parser.parse_args()

    # Path to imageVersion.ts
    project_root = Path(__file__).parent.parent
    version_file = project_root / 'src' / 'utils' / 'imageVersion.ts'

    if not version_file.exists():
        print(f"❌ Error: {version_file} not found")
        sys.exit(1)

    # Read current versions
    print(f"📖 Reading versions from {version_file}")
    versions = read_image_versions(version_file)
    print(f"   Found {len(versions)} image(s)")

    # Process commands
    updated = False

    if args.increment:
        versions = increment_versions(versions, args.increment)
        updated = True

    if args.set:
        path, version_str = args.set
        try:
            version = int(version_str)
            versions = set_version(versions, path, version)
            updated = True
        except ValueError:
            print(f"❌ Error: Invalid version number '{version_str}'")
            sys.exit(1)

    if not updated:
        print("❌ No action specified. Use --increment or --set")
        parser.print_help()
        sys.exit(1)

    # Write back
    print(f"💾 Writing updated versions to {version_file}")
    write_image_versions(version_file, versions)
    print(f"✨ Done!")


if __name__ == "__main__":
    main()
