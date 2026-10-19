select 'All seasons (BAA + NBA)' as scope, count(*) as titles,
       round(avg(ppg), 2) as avg_ppg, round(min(ppg), 2) as min_ppg, round(max(ppg), 2) as max_ppg
from {{ ref('stg_scoring_champions') }}

union all

select 'NBA only (1949-50 onward)', count(*),
       round(avg(ppg), 2), round(min(ppg), 2), round(max(ppg), 2)
from {{ ref('stg_scoring_champions') }}
where league = 'NBA'

union all

select 'Post-Wilt (1967-68 onward)', count(*),
       round(avg(ppg), 2), round(min(ppg), 2), round(max(ppg), 2)
from {{ ref('stg_scoring_champions') }}
where season_end_year >= 1968
