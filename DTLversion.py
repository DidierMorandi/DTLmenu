from __future__ import annotations

import argparse
import hashlib
import json
import re
import subprocess
import tempfile
from datetime import datetime
from pathlib import Path


VERSION_FILE = ".dtl_version"
ROLLBACK_FILE_PREFIX = "DTLversion_rollback_"
VERSION_RE = re.compile(r"^v?(\d+)\.(\d+)(?:\.(\d+))?$")
ASSIGNMENT_RE = re.compile(r'^(?P<name>[A-Z0-9_]*VERSION)\s*=\s*"(?P<value>[^"]+)"', re.MULTILINE)


PROJECT_FILES = {
    "DTLknowsWhy": [("shared/version.py", "DTLKNOWSWHY_VERSION")],
    "DTLsaysWhat": [("DTLsaysWhat.py", "APP_VERSION")],
    "GitDTL": [("GitDTL.py", "APP_VERSION")],
    "GitHubMenu": [("GitHubMenu.py", "APP_VERSION")],
    "DTLaudit": [("DTLaudit.py", "VERSION")],
    "DTL4u": [("DTL4u.py", "APP_VERSION")],
    "DTLarchive": [("DTLarchive.py", "APP_VERSION")],
}


def parse_version(value: str) -> tuple[int, int, int] | None:
    cleaned = value.strip()
    if cleaned.startswith("v"):
        cleaned = cleaned[1:]
    cleaned = cleaned.replace("-", ".")
    match = VERSION_RE.match(cleaned)
    if not match:
        return None
    major, minor, patch = match.groups()
    return int(major), int(minor), int(patch or 0)


def version_key(version: tuple[int, int, int]) -> tuple[int, int, int]:
    return version


def canonical(version: tuple[int, int, int]) -> str:
    return f"{version[0]}.{version[1]}.{version[2]}"


def display(version: tuple[int, int, int]) -> str:
    return f"v{version[0]}.{version[1]}-{version[2]}"


def run_git(project_dir: Path, args: list[str]) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        ["git", *args],
        cwd=project_dir,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
    )


def rollback_path(project_dir: Path, project_name: str) -> Path:
    key = hashlib.sha1(str(project_dir.resolve()).encode("utf-8")).hexdigest()
    return Path(tempfile.gettempdir()) / f"{ROLLBACK_FILE_PREFIX}{project_name}_{key}.json"


def latest_git_version(project_dir: Path) -> tuple[str, tuple[int, int, int]] | None:
    run_git(project_dir, ["fetch", "--tags", "--quiet"])
    result = run_git(project_dir, ["tag", "--sort=-creatordate"])
    if result.returncode != 0:
        return None
    candidates = []
    for tag in result.stdout.splitlines():
        version = parse_version(tag)
        if version is not None:
            candidates.append((tag, version))
    if not candidates:
        return None
    return max(candidates, key=lambda item: version_key(item[1]))


def read_state(project_dir: Path) -> dict:
    path = project_dir / VERSION_FILE
    if not path.exists():
        return {}
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return {}


def write_state(project_dir: Path, project_name: str, version: tuple[int, int, int], base_tag: str | None) -> None:
    state = {
        "project": project_name,
        "version": canonical(version),
        "display_version": display(version),
        "base_tag": base_tag,
        "updated_at": datetime.now().isoformat(timespec="seconds"),
    }
    (project_dir / VERSION_FILE).write_text(json.dumps(state, indent=2) + "\n", encoding="utf-8")


def write_pending_state(project_dir: Path, project_name: str, version: tuple[int, int, int], base_tag: str | None) -> None:
    state = {
        "project": project_name,
        "version": canonical(version),
        "display_version": display(version),
        "base_tag": base_tag,
        "pending": True,
        "updated_at": datetime.now().isoformat(timespec="seconds"),
    }
    (project_dir / VERSION_FILE).write_text(json.dumps(state, indent=2) + "\n", encoding="utf-8")


def current_source_version(project_dir: Path, project_name: str) -> tuple[int, int, int] | None:
    for relative_path, constant_name in PROJECT_FILES.get(project_name, []):
        path = project_dir / relative_path
        if not path.exists():
            continue
        text = path.read_text(encoding="utf-8")
        match = re.search(rf'^{re.escape(constant_name)}\s*=\s*"([^"]+)"', text, re.MULTILINE)
        if match:
            version = parse_version(match.group(1))
            if version is not None:
                return version
    return None


def replace_constant(path: Path, constant_name: str, value: str) -> None:
    text = path.read_text(encoding="utf-8")
    pattern = re.compile(rf'^{re.escape(constant_name)}\s*=\s*"[^"]+"', re.MULTILINE)
    replacement = f'{constant_name} = "{value}"'
    if pattern.search(text):
        text = pattern.sub(replacement, text, count=1)
    else:
        text = text.replace("\n\n", f"\n{replacement}\n\n", 1)
    path.write_text(text, encoding="utf-8")


def update_sources(project_dir: Path, project_name: str, version: tuple[int, int, int]) -> None:
    display_version = display(version)
    for relative_path, constant_name in PROJECT_FILES.get(project_name, []):
        path = project_dir / relative_path
        if path.exists():
            replace_constant(path, constant_name, display_version)


def tracked_paths(project_dir: Path, project_name: str) -> list[Path]:
    paths = [project_dir / VERSION_FILE]
    for relative_path, _constant_name in PROJECT_FILES.get(project_name, []):
        paths.append(project_dir / relative_path)
    return paths


def create_rollback(project_dir: Path, project_name: str) -> None:
    entries = []
    for path in tracked_paths(project_dir, project_name):
        entry = {
            "path": str(path.relative_to(project_dir)),
            "exists": path.exists(),
            "content": path.read_text(encoding="utf-8") if path.exists() else None,
        }
        entries.append(entry)
    payload = {
        "project": project_name,
        "created_at": datetime.now().isoformat(timespec="seconds"),
        "entries": entries,
    }
    rollback_path(project_dir, project_name).write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")


def restore_rollback(project_dir: Path, project_name: str) -> None:
    backup_path = rollback_path(project_dir, project_name)
    if not backup_path.exists():
        return
    payload = json.loads(backup_path.read_text(encoding="utf-8"))
    if payload.get("project") != project_name:
        raise SystemExit(f"Rollback refuse : le fichier concerne {payload.get('project')}")
    for entry in payload.get("entries", []):
        path = project_dir / entry["path"]
        if entry.get("exists"):
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(entry.get("content") or "", encoding="utf-8")
        elif path.exists():
            path.unlink()
    backup_path.unlink()


def commit_transaction(project_dir: Path, project_name: str) -> str:
    state = read_state(project_dir)
    version = parse_version(str(state.get("version", "")))
    if version is None:
        raise SystemExit("Aucune version en attente a valider.")
    write_state(project_dir, project_name, version, state.get("base_tag"))
    backup_path = rollback_path(project_dir, project_name)
    if backup_path.exists():
        backup_path.unlink()
    return display(version)


def next_version(project_dir: Path, project_name: str) -> tuple[tuple[int, int, int], str | None]:
    state = read_state(project_dir)
    state_version = parse_version(str(state.get("version", "")))
    source_version = current_source_version(project_dir, project_name)
    tag_info = latest_git_version(project_dir)
    tag_name = tag_info[0] if tag_info else None
    tag_version = tag_info[1] if tag_info else None

    base = max(
        [version for version in [state_version, source_version, tag_version] if version is not None],
        default=(1, 0, 0),
        key=version_key,
    )

    patch_base = base
    if tag_version is not None and tag_name != state.get("base_tag") and version_key(tag_version) >= version_key(base):
        patch_base = tag_version

    return (patch_base[0], patch_base[1], patch_base[2] + 1), tag_name


def begin(project_dir: Path, project_name: str) -> str:
    project_dir = project_dir.resolve()
    if project_name not in PROJECT_FILES:
        raise SystemExit(f"Projet non configure pour DTLversion : {project_name}")
    create_rollback(project_dir, project_name)
    version, base_tag = next_version(project_dir, project_name)
    write_state(project_dir, project_name, version, base_tag)
    update_sources(project_dir, project_name, version)
    return display(version)


def bump(project_dir: Path, project_name: str) -> str:
    version = begin(project_dir, project_name)
    commit_transaction(project_dir.resolve(), project_name)
    return version


def main() -> None:
    parser = argparse.ArgumentParser(description="Versioning DEC pour la suite DTL")
    parser.add_argument("command", choices=["begin", "commit", "rollback", "bump"])
    parser.add_argument("project_dir")
    parser.add_argument("project_name")
    args = parser.parse_args()
    project_dir = Path(args.project_dir).resolve()
    if args.command == "begin":
        print(begin(project_dir, args.project_name))
    elif args.command == "commit":
        print(commit_transaction(project_dir, args.project_name))
    elif args.command == "rollback":
        restore_rollback(project_dir, args.project_name)
    else:
        print(bump(project_dir, args.project_name))


if __name__ == "__main__":
    main()
