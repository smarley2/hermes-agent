from __future__ import annotations

import re
from pathlib import Path


CODEX_BACKEND_BASE_URL_PATTERN = re.compile(r"https://chatgpt\.com/backend-api/codex(?:[/?#][^\"'\s)]*)?")
_ALLOWED_FILES = {
    Path("hermes_constants.py"),
    Path("tests/test_codex_backend_base_url_constant.py"),
}


def test_codex_backend_base_url_is_defined_in_one_shared_location() -> None:
    repo_root = Path(__file__).resolve().parents[1]
    offenders: list[str] = []

    for path in repo_root.rglob("*"):
        if not path.is_file():
            continue
        relative = path.relative_to(repo_root)
        if relative.parts and relative.parts[0] in {".git", ".venv", "venv", "tests"}:
            continue
        if relative in _ALLOWED_FILES:
            continue
        try:
            text = path.read_text(encoding="utf-8")
        except UnicodeDecodeError:
            continue
        if CODEX_BACKEND_BASE_URL_PATTERN.search(text):
            offenders.append(str(relative))

    assert offenders == []
