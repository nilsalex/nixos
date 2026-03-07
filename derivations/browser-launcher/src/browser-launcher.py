#!/usr/bin/env python3
import argparse
import json
import os
import subprocess
import sys
from pathlib import Path

import requests

CONFIG_DIR = Path.home() / ".config" / "browser-launcher"
CONFIG_FILE = CONFIG_DIR / "config.json"
MEMORY_FILE = CONFIG_DIR / "memory.json"
MEMORY_LIMIT = 100


def load_config():
    if not CONFIG_FILE.exists():
        print(f"Error: Config file not found at {CONFIG_FILE}", file=sys.stderr)
        print("Create it with:", file=sys.stderr)
        print('  {"api_url": "https://...", "api_key": "..."}', file=sys.stderr)
        sys.exit(1)
    with open(CONFIG_FILE) as f:
        return json.load(f)


def load_memory():
    if not MEMORY_FILE.exists():
        return []
    with open(MEMORY_FILE) as f:
        return json.load(f)


def save_memory(memory):
    CONFIG_DIR.mkdir(parents=True, exist_ok=True)
    with open(MEMORY_FILE, "w") as f:
        json.dump(memory, f, indent=2)


def build_prompt(memory, query):
    examples = ""
    if memory:
        entries = memory[:MEMORY_LIMIT]
        for entry in entries:
            desc = f" ({entry['description']})" if entry.get("description") else ""
            examples += f"- {entry['name']}{desc} -> {entry['url']}\n"

    prompt = f"""You are a browser URL assistant. Given a user query, return ONLY the URL they want to open.

User's known shortcuts:
{examples}
Query: {query}

Return ONLY the URL, nothing else. If unsure, make a reasonable guess based on the query."""
    return prompt


def call_llm(config, query, memory):
    prompt = build_prompt(memory, query)

    try:
        response = requests.post(
            config["api_url"],
            headers={
                "x-api-key": config["api_key"],
                "Content-Type": "application/json",
                "anthropic-version": "2023-06-01",
            },
            json={
                "model": "claude-sonnet-4-6",
                "max_tokens": 256,
                "messages": [{"role": "user", "content": prompt}],
            },
            timeout=30,
        )
        response.raise_for_status()
        url = response.json()["choices"][0]["message"]["content"].strip()
        return url
    except Exception as e:
        print(f"LLM API error: {e}", file=sys.stderr)
        return f"https://www.google.com/search?q={query}"


def bemenu_prompt():
    result = subprocess.run(
        ["bemenu", "-i", "-p", "Open:"],
        input="",
        capture_output=True,
        text=True,
    )
    return result.stdout.strip() if result.returncode == 0 else None


def open_browser(url):
    subprocess.run(["xdg-open", url])


def cmd_launch(args):
    query = args.query if args.query else bemenu_prompt()
    if not query:
        return

    config = load_config()
    memory = load_memory()
    url = call_llm(config, query, memory)
    print(f"Opening: {url}")
    open_browser(url)


def cmd_teach(args):
    memory = load_memory()

    entry = {"name": args.name, "url": args.url}
    if args.description:
        entry["description"] = args.description

    for i, e in enumerate(memory):
        if e["name"] == args.name:
            memory[i] = entry
            save_memory(memory)
            print(f"Updated: {args.name} -> {args.url}")
            return

    memory.append(entry)
    save_memory(memory)
    print(f"Added: {args.name} -> {args.url}")


def cmd_list(args):
    memory = load_memory()
    if not memory:
        print("No entries in memory.")
        return
    for entry in memory:
        desc = f" ({entry['description']})" if entry.get("description") else ""
        print(f"{entry['name']}{desc} -> {entry['url']}")


def cmd_delete(args):
    memory = load_memory()
    new_memory = [e for e in memory if e["name"] != args.name]
    if len(new_memory) == len(memory):
        print(f"Entry '{args.name}' not found.")
        return
    save_memory(new_memory)
    print(f"Deleted: {args.name}")


def main():
    parser = argparse.ArgumentParser(description="Browser launcher with LLM")
    subparsers = parser.add_subparsers(dest="command")

    launch_parser = subparsers.add_parser("launch", help="Launch browser (default)")
    launch_parser.add_argument("query", nargs="?", help="Query (opens bemenu if not provided)")
    launch_parser.set_defaults(func=cmd_launch)

    teach_parser = subparsers.add_parser("teach", help="Teach a new shortcut")
    teach_parser.add_argument("name", help="Shortcut name")
    teach_parser.add_argument("url", help="URL")
    teach_parser.add_argument("-d", "--description", help="Description")
    teach_parser.set_defaults(func=cmd_teach)

    list_parser = subparsers.add_parser("list", help="List shortcuts")
    list_parser.set_defaults(func=cmd_list)

    delete_parser = subparsers.add_parser("delete", help="Delete a shortcut")
    delete_parser.add_argument("name", help="Shortcut name")
    delete_parser.set_defaults(func=cmd_delete)

    args = parser.parse_args()

    if args.command is None:
        args.query = None
        cmd_launch(args)
    else:
        args.func(args)


if __name__ == "__main__":
    main()
