#!/usr/bin/env python3
"""Claude Code PreToolUse(Bash) hook: deny commands that name ~/.aws.

Credentials in ~/.aws should never be read, listed or grepped by an agent.
The aws CLI reading its own config is unaffected; only commands that name the
directory are denied. Fails open on malformed input.
"""
import json
import re
import sys

AWS_DIR = re.compile(r"(~|\$HOME|\$\{HOME\}|/home/[^/\s]+|/root)/\.aws(/|\b)")


def main():
    data = json.load(sys.stdin)
    cmd = (data.get("tool_input") or {}).get("command") or ""
    if AWS_DIR.search(cmd):
        print(json.dumps({"hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "deny",
            "permissionDecisionReason": "This command names the AWS credentials directory (~/.aws). "
            "Don't read, list or grep it; use the aws CLI (e.g. `aws sts get-caller-identity --profile X`)."}}))


if __name__ == "__main__":
    try:
        main()
    except Exception:
        pass
    sys.exit(0)
