#!/usr/bin/env python3
"""Fail when public repository content or Git history exposes private metadata."""

from __future__ import annotations

import re
import subprocess
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent
SELF = Path(__file__).resolve().relative_to(ROOT).as_posix()
PUBLIC_AUTHOR = "CocaDeveloper"
NOREPLY_SUFFIXES = ("@users.noreply.github.com", "@noreply.github.com")
ALLOWED_EMAIL_DOMAINS = {"example.com", "example.org", "example.invalid", "users.noreply.github.com"}
SENSITIVE_SUFFIXES = {
    ".cer",
    ".crt",
    ".key",
    ".mobileprovision",
    ".p12",
    ".p8",
    ".pem",
    ".provisionprofile",
}

EMAIL = re.compile(r"(?<![\w.+-])([\w.+-]+@([A-Za-z][A-Za-z0-9.-]*\.[A-Za-z]{2,}))(?![\w.-])")
PRIVATE_HOME = re.compile(r"(?:/Users|/home)/([A-Za-z0-9._-]+)|[A-Za-z]:\\Users\\([A-Za-z0-9._-]+)")
ALLOWED_HOME_NAMES = {"runner", "shared", "user", "username"}
TEAM_LITERAL = re.compile(r"(?:DEVELOPMENT_TEAM|TeamIdentifier)\s*[=:]\s*([A-Z0-9]{10})\b")
ALLOWED_TEAM_PLACEHOLDERS = {"XXXXXXXXXX", "YOURTEAMID", "TEAMIDHERE"}
PRIVATE_MATERIAL = re.compile(
    r"-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----"
    r"|\b(?:ghp_|github_pat_)[A-Za-z0-9_]{20,}"
    r"|\bsk-[A-Za-z0-9_-]{20,}"
    r"|\bAKIA[0-9A-Z]{16}\b"
)

ASSISTANT_NAMES = r"(?:codex|openai|chatgpt|claude|copilot)"
AUTHORSHIP_TRACES = re.compile(
    rf"\bvibe[ -]?cod(?:e|ing)\b"
    rf"|\bai[- ]generated\b"
    rf"|\b(?:generated|written|built|made|created)\s+(?:by|with|using)\s+{ASSISTANT_NAMES}\b"
    rf"|\bco-authored-by:.*{ASSISTANT_NAMES}",
    re.IGNORECASE,
)


def git(*args: str) -> bytes:
    return subprocess.check_output(["git", *args], cwd=ROOT)


def tracked_files() -> list[str]:
    return [item for item in git("ls-files", "-z").decode().split("\0") if item]


def is_public_identity(name: str, email: str) -> bool:
    lowered_name = name.casefold()
    lowered_email = email.casefold()
    if lowered_name == PUBLIC_AUTHOR.casefold() and lowered_email.endswith(NOREPLY_SUFFIXES):
        return True
    if lowered_name in {"github", "github actions"} or lowered_name.endswith("[bot]"):
        return lowered_email.endswith(NOREPLY_SUFFIXES) or lowered_email == "noreply@github.com"
    return False


def main() -> int:
    findings: list[tuple[str, str]] = []

    for relative in tracked_files():
        path = ROOT / relative
        if not path.exists():
            continue
        lowered_name = path.name.casefold()
        if path.suffix.casefold() in SENSITIVE_SUFFIXES or lowered_name == ".env" or lowered_name.startswith(".env."):
            findings.append(("sensitive file type", relative))

        data = path.read_bytes()
        if b"\x00" in data[:8192]:
            if b"/Users/" in data or b"-----BEGIN " in data:
                findings.append(("private metadata in binary", relative))
            continue

        text = data.decode("utf-8", errors="replace")
        if relative != SELF and AUTHORSHIP_TRACES.search(text):
            findings.append(("development-assistant attribution", relative))

        for _, domain in EMAIL.findall(text):
            if domain.casefold() not in ALLOWED_EMAIL_DOMAINS:
                findings.append(("public email address", relative))
                break

        for match in PRIVATE_HOME.finditer(text):
            home_name = (match.group(1) or match.group(2)).casefold()
            if home_name not in ALLOWED_HOME_NAMES:
                findings.append(("local home path", relative))
                break

        if any(match.group(1) not in ALLOWED_TEAM_PLACEHOLDERS for match in TEAM_LITERAL.finditer(text)):
            findings.append(("literal Apple team identifier", relative))
        if PRIVATE_MATERIAL.search(text):
            findings.append(("credential or private-key material", relative))

    raw_history = git(
        "log",
        "--all",
        "--format=%H%x00%an%x00%ae%x00%cn%x00%ce%x00%B%x1e",
    ).decode("utf-8", errors="replace")
    for record in raw_history.split("\x1e"):
        parts = record.strip("\n\x00").split("\x00", 5)
        if len(parts) != 6:
            continue
        commit, author_name, author_email, committer_name, committer_email, message = parts
        short_commit = commit[:12]
        if not is_public_identity(author_name, author_email) or not is_public_identity(committer_name, committer_email):
            findings.append(("non-public Git identity", short_commit))
        if AUTHORSHIP_TRACES.search(message):
            findings.append(("development-assistant attribution in commit", short_commit))

    if findings:
        print("Public repository audit failed:", file=sys.stderr)
        for kind, location in sorted(set(findings)):
            print(f"- {kind}: {location}", file=sys.stderr)
        return 1

    print(f"Public repository audit passed: {len(tracked_files())} tracked files and Git history checked.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
