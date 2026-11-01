USE bootcamp.nothern_star;

--1
WITH po_klubu AS(
    SELECT t.team_id,t.team_name,
    SUM(CASE WHEN m.home_team_id=t.team_id THEN m.home_goals ELSE m.away_goals END) AS golovi_kluba
    FROM matches m
    JOIN teams t ON t.team_id IN (m.home_team_id, m.away_team_id)
    WHERE m.season='2024/25' AND m.status='played'
    GROUP BY t.team_id,t.team_name
)
SELECT team_name, golovi_kluba
,SUM(golovi_kluba) OVER () as golovi_lige
,ROUND(100*golovi_kluba/SUM(golovi_kluba) OVER (),2) AS udeo_pct
, DENSE_RANK() OVER (ORDER BY golovi_kluba DESC) as dense_rnk
FROM po_klubu
QUALIFY dense_rnk=1;
--Kingsbridge City	83	1092	7.6	1

--2
WITH po_stadionu (
SELECT stadium_id, COUNT(attendance) as utakmice_sa_posetom
, ROUND(AVG(attendance)) AS prosecna_poseta
FROM matches 
WHERE season='2024/25' and status='played'
GROUP BY stadium_id
)
SELECT RANK() OVER (ORDER BY p.prosecna_poseta DESC) as rang
, s.stadium_id, s.stadium_name, p.prosecna_poseta
FROM po_stadionu p
JOIN stadiums s ON s.stadium_id=p.stadium_id
QUALIFY rang<=3
ORDER BY rang;

/*rang	stadium_id	stadium_name	prosecna_poseta
1	1	Harbourside Park	44074
2	4	Kingsbridge Stadium	37968
3	2	Northport Arena	36250*/

--3
SELECT t.team_name, p.first_name, p.last_name, m.kickoff_ts, e.minute
FROM match_events e
JOIN matches m ON m.match_id=e.match_id
JOIN teams t ON t.team_id=e.team_id
JOIN players p ON p.player_id=e.player_id
WHERE m.season='2024/25' AND m.status='played' AND e.event_type IN ('goal', 'penalty_goal')
QUALIFY ROW_NUMBER() OVER(PARTITION BY e.team_id
                        ORDER BY m.kickoff_ts DESC, e.minute DESC, e.event_id DESC) =1
ORDER BY m.kickoff_ts, e.minute;  
--Elmsworth Wanderers	Marko	Stanković	2025-05-03T15:00:00.000+00:00	27     

--4
SELECT m.kickoff_ts, m.attendance,
m.attendance - LAG(m.attendance) OVER (ORDER BY m.kickoff_ts) as promena
FROM matches m
JOIN teams t ON t.team_id=m.home_team_id
WHERE t.team_name='Northport United' AND m.season='2024/25' AND m.status='played'
ORDER BY promena NULLS LAST;
--2024-11-10T16:30:00.000+00:00	39152	-10267

--5

CREATE OR REPLACE VIEW bootcamp.nothern_star.team_matches AS
    WITH sides AS (
        SELECT 
            match_id, season, matchday, kickoff_ts,
            home_team_id AS team_id, away_team_id AS opponent_id, 'home' AS
            venue,
            home_goals AS goals_for, away_goals AS goals_against
        FROM bootcamp.nothern_star.matches WHERE status = 'played'
        UNION ALL
        SELECT 
            match_id, season, matchday, kickoff_ts,
            away_team_id, home_team_id, 'away',
            away_goals, home_goals
        FROM bootcamp.nothern_star.matches WHERE status = 'played'
)
SELECT 
    *,
    CASE WHEN goals_for > goals_against THEN 'W'
         WHEN goals_for = goals_against THEN 'D' 
         ELSE 'L' 
    END AS result,
    CASE WHEN goals_for > goals_against THEN 3
         WHEN goals_for = goals_against THEN 1 
         ELSE 0 
    END AS points
FROM sides;

WITH bod AS ( SELECT tm.kickoff_ts,
ROW_NUMBER() OVER (ORDER BY tm.kickoff_ts) AS utakmica_br,
SUM(tm.points) OVER (ORDER BY tm.kickoff_ts
                    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS ukupno
FROM team_matches tm
JOIN teams t ON t.team_id=tm.team_id
WHERE t.team_name='Northport City' AND tm.season='2024/25')

SELECT * FROM bod
WHERE ukupno>50
ORDER BY utakmica_br
LIMIT 1;
--2025-01-12T16:30:00.000+00:00	21	51