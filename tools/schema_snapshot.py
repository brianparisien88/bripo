"""
Write docs/schema-snapshot.json from the live Supabase public schema.

Deterministic, no LLM. Run after a migration, or in CI, to catch doc drift.
Calls the `schema_catalog()` RPC (defined in the init migration) — grant is to
`anon`, so only the publishable key is needed (schema *shape* is not sensitive;
the data behind it is RLS-locked).

Env: SUPABASE_URL, SUPABASE_PUBLISHABLE_KEY
"""
from __future__ import annotations

import json
import os
import pathlib
import sys

import requests

OUT = pathlib.Path(__file__).resolve().parent.parent / "docs" / "schema-snapshot.json"


def main() -> None:
    url = os.environ.get("SUPABASE_URL") or sys.exit("SUPABASE_URL not set")
    key = os.environ.get("SUPABASE_PUBLISHABLE_KEY") or sys.exit("SUPABASE_PUBLISHABLE_KEY not set")
    r = requests.post(
        f"{url.rstrip('/')}/rest/v1/rpc/schema_catalog",
        headers={"apikey": key, "Authorization": f"Bearer {key}",
                 "Content-Type": "application/json"},
        json={}, timeout=30,
    )
    r.raise_for_status()
    catalog = r.json()
    OUT.parent.mkdir(exist_ok=True)
    OUT.write_text(json.dumps(catalog, indent=2, sort_keys=True) + "\n")
    print(f"wrote docs/schema-snapshot.json — {len(catalog)} tables, "
          f"{sum(len(v) for v in catalog.values())} columns")


if __name__ == "__main__":
    main()
