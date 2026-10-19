select decade, decade_start, count(*) as titles, round(avg(ppg), 2) as avg_ppg
from {{ ref('stg_scoring_champions') }}
group by decade, decade_start
order by decade_start