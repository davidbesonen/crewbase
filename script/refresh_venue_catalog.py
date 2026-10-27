#!/usr/bin/env python3
"""Build the public U.S. venue snapshot. Requires duckdb with its httpfs extension."""
import argparse
import json
import re
import unicodedata
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
VENUE_CATEGORIES = {
    "music_venue", "stadium_arena", "theatre_venue", "performing_arts_venue",
    "fairgrounds", "football_stadium", "baseball_stadium", "jazz_and_blues_venue",
    "soccer_stadium", "hockey_arena", "stadium", "basketball_stadium", "arena",
    "amphitheater", "dinner_theater", "rugby_stadium", "opera_and_ballet",
}
NAME_PATTERN = r"amphitheat|auditorium|concert hall|music hall|house of blues"
EXTRA_CATEGORIES = {"park", "national_park", "historic_site", "event_space", "event_venue", "community_center", "convention_center", "cultural_center", "university", "arts_and_entertainment"}


def download(release):
    import duckdb
    connection = duckdb.connect()
    connection.execute("INSTALL httpfs; LOAD httpfs; SET s3_region='us-west-2'; SET threads=4; SET memory_limit='1GB';")
    query = """
      SELECT id, names.primary AS name, addresses[1] AS address,
             taxonomy.primary AS category, taxonomy.hierarchy AS hierarchy,
             bbox.xmin AS longitude, bbox.ymin AS latitude, sources
      FROM read_parquet(?)
      WHERE bbox.xmin BETWEEN -180 AND -65 AND bbox.ymin BETWEEN 18 AND 72
        AND addresses[1].country = 'US'
        AND (operating_status IS NULL OR operating_status NOT IN ('permanently_closed', 'closed'))
        AND (regexp_matches(array_to_string(taxonomy.hierarchy, '/'),
          'music_venue|concert_hall|amphitheat|performing_arts_venue|theater|theatre|stadium|arena|opera_house|jazz_club|blues_club|rock_club|fairground|festival_ground')
          OR regexp_matches(lower(names.primary), ?))
    """
    path = f"s3://overturemaps-us-west-2/release/{release}/theme=places/type=place/*"
    records = connection.execute(query, [path, NAME_PATTERN]).fetchall()
    columns = [column[0] for column in connection.description]
    return [dict(zip(columns, record)) for record in records]


def normalized(value):
    ascii_value = unicodedata.normalize("NFKD", value).encode("ascii", "ignore").decode()
    return re.sub(r"[^a-z0-9]", "", ascii_value.lower())


def build(records):
    venues = {}
    for record in records:
        address = record.get("address") or {}
        name = (record.get("name") or "").strip()
        category = record.get("category") or ""
        if category not in VENUE_CATEGORIES and not (category in EXTRA_CATEGORIES and re.search(NAME_PATTERN, name, re.I)):
            continue
        if category in {"movie_theater", "drive_in_theater", "home_theater_systems_stores"}:
            continue
        sources = [source for source in record["sources"] if source["property"] == ""]
        confidence = max((source.get("confidence") or 0 for source in sources), default=0)
        # Require a plausible physical location, not an event page or a loose city tag.
        if confidence < .85 or not address.get("locality") or not address.get("region"):
            continue
        if not address.get("freeform") and confidence < .95:
            continue
        if not name or address.get("country") != "US":
            continue
        key = (normalized(name), round(record["latitude"], 3), round(record["longitude"], 3))
        row = {
            "source_key": "overture/" + record["id"], "name": name,
            "address": address.get("freeform"), "city": address["locality"],
            "state": address["region"], "postal_code": address.get("postcode"),
            "country": "US", "category": category,
            "latitude": round(record["latitude"], 7), "longitude": round(record["longitude"], 7),
            "licenses": sorted({source["license"] for source in record["sources"]}),
        }
        if key not in venues or confidence > venues[key][0]:
            venues[key] = (confidence, row)
    return sorted((row for _, row in venues.values()), key=lambda row: row["source_key"])


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--release", default="2026-10-21.0")
    parser.add_argument("--from-json", nargs="+", help="Reuse previously downloaded raw Overture extracts")
    args = parser.parse_args()
    if args.from_json:
        records = {row["id"]: row for path in args.from_json for row in json.loads(Path(path).read_text())}.values()
    else:
        records = download(args.release)
    rows = build(records)
    if len(rows) < 10000:
        raise SystemExit("Unexpectedly small catalog; existing snapshot left intact")
    target = ROOT / "public/data/us-venues.json"
    target.write_text("[\n" + ",\n".join(json.dumps(row, ensure_ascii=False) for row in rows) + "\n]\n")
    print(f"Wrote {len(rows):,} venues from Overture {args.release} to {target}")
