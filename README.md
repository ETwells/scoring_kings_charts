# NBA scoring champions with dbt, DuckDB and dbt Charts

A small sports data project: a dataset of every NBA/BAA scoring champion, a few tested dbt models, and a dashboard defined as YAML with dbt Charts. Everything runs from one local DuckDB file, with no server and no cloud account.

## What it answers

What is the average points per game of all scoring title winners?

| Scope | Titles | Avg PPG |
|---|---|---|
| All seasons (BAA + NBA) | 80 | 31.07 |
| NBA only (1949-50 onward) | 77 | 31.33 |
| Post-Wilt (1967-68 onward) | 59 | 31.21 |

The post-Wilt average is higher than the all-seasons one mostly because that scope also drops the low-scoring early years (the 14 pre-1968 titles not won by Wilt Chamberlain average 26.29), not because of Wilt himself. Without his 7 seasons, the other 73 titles still average 30.27.

## Project layout

```
nba_scoring_dbt/
├── dbt_project.yml              # dbt project config (seed types, materializations)
├── profiles.yml                 # DuckDB connection, lives in the project folder
├── dbt_charts.yml               # dbt Charts data source (points at nba.duckdb)
├── seeds/
│   └── nba_scoring_champions.csv    # 80 rows, 1946-47 to 2025-26
├── models/
│   ├── schema.yml                   # descriptions and data tests
│   ├── staging/
│   │   └── stg_scoring_champions.sql    # typed rows + decade columns (view)
│   └── marts/
│       ├── mart_avg_ppg_overall.sql     # average PPG across three scopes (table)
│       ├── mart_avg_ppg_by_decade.sql   # average PPG per decade (table)
│       └── mart_title_winners.sql       # titles and average PPG per player (table)
├── charts/
│   └── scoring_champions.yml        # the dashboard
└── renders/
    └── dashboard.png                # exported dashboard image
```

## The data

`seeds/nba_scoring_champions.csv` has one row per season:

| Column | Meaning |
|---|---|
| `season` | e.g. `1961-62` |
| `season_end_year` | e.g. `1962` |
| `league` | `BAA` (1946-49) or `NBA` |
| `player` | Scoring champion |
| `team` | Team abbreviation |
| `ppg` | Points per game that season |

Source: Basketball-Reference year-by-year PPG leaders. The ABA is excluded. Check the CSV against the source before you publish numbers from it.

## Requirements

- A recent Python 3 (built and tested with 3.13)
- No separate DuckDB install is needed. The `dbt-duckdb` package brings the engine.

## Setup

```bash
# 1. Create and activate a virtual environment
python3 -m venv .venv
source .venv/bin/activate

# 2. Install dbt with the DuckDB adapter
python -m pip install dbt-core dbt-duckdb

# 3. Install dbt Charts
python -m pip install dbt-charts      # or: uv tool install dbt-charts
```

Check you are using the venv's dbt and not a global one:

```bash
which dbt        # should point inside .venv/
```

If it doesn't, run `hash -r` and check again. A global dbt without the DuckDB adapter fails with `Could not find adapter type duckdb!`.

## Build the data

```bash
dbt debug --profiles-dir .      # checks the connection
dbt build --profiles-dir .      # loads the seed, builds models, runs tests
```

`--profiles-dir .` tells dbt to use the `profiles.yml` in this folder. A successful build creates `nba.duckdb` and runs 11 data tests (uniqueness and not-null checks on the seed and marts, plus an accepted-values check on `league`).

Inspect results without leaving the terminal:

```bash
dbt show --profiles-dir . --inline "select * from {{ ref('mart_avg_ppg_overall') }}"
```

## Models

- **`stg_scoring_champions`** (view): casts the seed and adds `decade_start` and `decade`. It uses integer division (`//`) so 2026 becomes `2020s`. Plain `/` gives a float in DuckDB and would put 2026 in a "2030s" bucket.
- **`mart_avg_ppg_overall`** (table): average, minimum and maximum PPG across the three scopes in the table above.
- **`mart_avg_ppg_by_decade`** (table): titles and average PPG per decade.
- **`mart_title_winners`** (table): titles, average and best winning PPG, and first and last title per player.

## Dashboard

The dashboard lives in `charts/scoring_champions.yml` and reads from the DuckDB file configured in `dbt_charts.yml`:

```yaml
sources:
  nba:
    type: duckdb
    path: ./nba.duckdb
```

It has four charts:

| Chart | Type | Shows |
|---|---|---|
| Winning PPG by season | line | The whole run of champions' scoring |
| Average winning PPG by decade | bar | Era comparison, sorted chronologically |
| Scoring titles (3 or more) | bar | Who won the most titles |
| Average PPG of scoring title winners | table | The three headline scopes |

Validate, then view it:

```bash
dct validate charts/scoring_champions.yml
dct serve
```

Open the address `dct serve` prints. Export an image for an article or a README:

```bash
mkdir -p renders
dct render charts/scoring_champions.yml --format png -o renders/dashboard.png
```

Other formats: `svg`, `html`, `pdf`. To test a query without building a chart:

```bash
dct query nba 'SELECT * FROM main.mart_avg_ppg_overall'
```

## Troubleshooting

- **`Could not find adapter type duckdb!`**: the global dbt is running. Activate the venv, run `hash -r`, then reinstall with `python -m pip install dbt-core dbt-duckdb`.
- **Database is locked**: DuckDB allows one writer per file. Stop `dct serve` before running `dbt build`.
- **Decades look wrong** (a 2030s bucket): a `/` crept in where `//` should be.
- **Bars in the wrong order**: the decade chart needs `sort: { by: decade, order: asc }`. Without it, bars sort by value.
- **Table shows one decimal**: set `format: number_full` on the column under `style.columns`.
- **Dashboard shows no data or a wrong source**: check that the `source:` name in the chart file matches the name in `dbt_charts.yml` exactly. A misspelled source name can quietly fall back to an empty in-memory database.
- **Root-level `subtitle` rejected**: boards accept `title` only at the top. Use `subtitle` on individual charts.

## Suggested `.gitignore`

```
.venv/
target/
logs/
nba.duckdb
.user.yml
```

`nba.duckdb` is rebuilt by `dbt build`, so it doesn't need to be in version control.

## Data notes

- The league was the BAA until 1948-49 and the NBA from 1949-50. The "NBA only" scope starts there.
- Counting is by season, so a player with several consecutive titles counts once per season.
