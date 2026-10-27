# U.S. venue catalog and tour shows

Tour shows require a city and date. A blank name is saved as the city; a blank
end date means the start date only. Number Of Shows defaults to 1, with 1/2/3
presets and Other for 1–100 performances. It describes performances at a stop,
not additional days. Set an end date explicitly for a multi-day stop. Counts
appear in staffing labels, show cards, and the project's show total. Crew
coverage and booking dates still use the stop's explicit dates.

Show Time is a separate optional, venue-local performance start time. It appears
on show cards, crew-by-show columns, and show labels in linked postings and
staffing forms. It does not change crew work hours, booked offer terms, or the
show date. Blank times stay unspecified; clearing the field removes the time.

Crew matrix columns sharing a city and date show distinct performance times.
When times are missing or identical, columns also show their show titles.
Identical/default titles receive stable Show 1 / Show 2 labels within that
city/date group, including when filtering the matrix to one show.

`VenueCatalogEntry` is the national public directory. It is separate from
company-owned `Venue` records. Autocomplete works in tour show entry, saved
venues, production briefs, and the older setup-reuse tour stop flow. Selecting
a public venue fills location details; selecting one for a production brief or
reused setup creates or reuses that company's saved copy. Private contacts and
arrival instructions are never returned by public catalog search. Catalog
updates do not rewrite companies' saved venue details or booked terms.

The bundled `public/data/us-venues.json` snapshot is derived from Overture
Places release 2026-10-21.0. It filters U.S. performance venues and concert
landmarks, excludes cinemas and retail stores, applies source-confidence and
location completeness checks, and deduplicates nearby equivalent names.
It is broad national coverage, not a guarantee of every venue. Names, addresses,
and operating status can lag reality; users may edit details or enter venues
manually. Attribution and data license texts are publicly accessible under
`public/data/`; each JSON record retains its source license identifiers.

## Refreshing

Install Python's `duckdb` package in a development environment, then run:

```sh
python3 script/refresh_venue_catalog.py --release 2026-10-21.0
bin/rails venues:import
```

The script requires network access to Overture's public S3 bucket and DuckDB's
`httpfs` extension. This is an offline maintenance operation, not a request-time
dependency. Review the output's state coverage and representative major venues,
and update the release/date in the notice when refreshing. Keep source license
texts and notices with the snapshot. A small/failed extract leaves the snapshot
intact. No automatic refresh schedule is configured.

The import upserts in batches using stable Overture identifiers; it does not
delete public entries already referenced by saved company venues. A changed
snapshot refreshes public search details only. Render's startup imports the
bundled snapshot after migrations, so runtime search needs no map API key,
third-party network request, or paid map subscription. Local installs can run
`bin/rails venues:import`; fresh seeds import it too.
