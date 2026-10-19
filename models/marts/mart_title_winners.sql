select
    player,
    count(*)           as titles,
    round(avg(ppg), 2) as avg_title_ppg,
    round(max(ppg), 2) as best_title_ppg,
    min(season)        as first_title,
    max(season)        as last_title
from {{ ref('stg_scoring_champions') }}
group by player
order by titles desc, avg_title_ppg desc