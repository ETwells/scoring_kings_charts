select
    season, 
    season_end_year,
    league,
    player,
    team,
    ppg,
    (season_end_year // 10) * 10 as decade_start,
    cast((season_end_year // 10) * 10 as varchar) || 's' as decade
from {{ ref('nba_scoring_champions') }}