
--Део Б - извештај о сезони 2024/25
--1. Преглед сезоне: број утакмица и голова, просечан број голова по утакмици, удео победа домаћина, нерешених и победа гостију.

USE bootcamp.nothern_star;

SELECT season,
COUNT(*) as br_utakmice
, SUM(home_goals+away_goals) AS golovi
, ROUND(AVG(home_goals+away_goals),2) AS prosek_golova
, ROUND(100*COUNT_IF(home_goals>away_goals)/ COUNT(*)) AS pobede_domacin
, ROUND(100*COUNT_IF(home_goals=away_goals)/ COUNT(*)) AS nereseno
, ROUND(100*COUNT_IF(home_goals<away_goals)/ COUNT(*)) AS pobeda_gost
FROM matches
WHERE status='played'
GROUP BY season
HAVING season='2024/25';
--season	br_utakmice	golovi	prosek_golova	pobede_domacin	nereseno	pobeda_gost
--2024/25	380	1092	2.87	41	25	34


--2. По месецима: број утакмица и голова по месецима, и просечан број голова по утакмици у сваком месецу. Који месец се издваја?

WITH timovi AS (
  SELECT season, home_team_id AS team_id, 'home' AS venue, home_goals AS dati, away_goals AS primljeni, kickoff_ts, match_id
  FROM matches WHERE status = 'played' AND season='2024/25'
  UNION ALL
  SELECT season, away_team_id, 'away', away_goals, home_goals, kickoff_ts, match_id
  FROM matches WHERE status = 'played' AND season='2024/25')

SELECT 
MONTH(t.kickoff_ts) as mesec
, COUNT(distinct match_id) AS utakmice
,SUM(dati) AS golovi
FROM timovi t
GROUP BY MONTH(t.kickoff_ts)
--ORDER BY mesec desc;
ORDER BY golovi desc;-- u decembru najvise --145

/*mesec	utakmice	golovi
12	52	145
1	51	137
4	40	124
2	40	119
3	40	113
10	30	102
8	28	99
11	37	96
5	30	79
9	32	78*/

WITH timovi AS (
  SELECT season, home_team_id AS team_id, 'home' AS venue, home_goals AS dati, away_goals AS primljeni, kickoff_ts, match_id
  FROM matches WHERE status = 'played' AND season='2024/25'
  UNION ALL
  SELECT season, away_team_id, 'away', away_goals, home_goals, kickoff_ts, match_id
  FROM matches WHERE status = 'played' AND season='2024/25')

SELECT
MONTH(t.kickoff_ts) as mesec
, ROUND(AVG(dati),2) as prosek
FROM timovi t
GROUP BY MONTH(t.kickoff_ts)
ORDER BY prosek desc; --8	1.77 u avgustu najvise

--3. Публика: просечна посета и попуњеност по стадиону; утакмице без податка о посети и утакмица без публике.

SELECT ROUND(AVG(m.attendance)) AS prosek,
       ROUND(AVG(100 * m.attendance / s.capacity), 1) AS popunjenost_pct,
       COUNT(*) - COUNT(m.attendance) AS bez_podatka
FROM matches m
JOIN stadiums s ON m.stadium_id   = s.stadium_id
WHERE m.season = '2024/25' AND m.status = 'played';

--prosek	popunjenost_pct	bez_podatka
--24199	85.7	9

--4. Судије: за сваког судију број утакмица и картони по утакмици.
WITH kartoni AS(
SELECT m.match_id, m.referee_id,
COUNT(e.event_id) AS kartoni
FROM matches m
LEFT JOIN match_events e ON e.match_id = m.match_id  AND e.event_type IN ('yellow_card', 'second_yellow', 'red_card')
WHERE m.status='played'
GROUP BY m.match_id, m.referee_id
)
SELECT r.referee_id, r.referee_name 
,COUNT(*) as br_utakmica
, SUM(k.kartoni) as sum_kartoni
, ROUND(AVG(k.kartoni),2) as kartoni_po_utakmici
FROM kartoni k
JOIN referees r On k.referee_id=r.referee_id
GROUP BY r.referee_id, r.referee_name 
ORDER BY sum_kartoni DESC;
--Henrik Dahl	40	165	4.13

--5. Играчи: пет најбољих стрелаца и пет најбољих асистената.
SELECT p.first_name, p.last_name, COUNT(*) AS golovi
FROM match_events e
JOIN matches m ON e.match_id  = m.match_id
JOIN players p ON e.player_id = p.player_id
JOIN teams   t ON e.team_id   = t.team_id
WHERE m.season = '2024/25' AND e.event_type IN ('goal', 'penalty_goal')
GROUP BY p.player_id, p.first_name, p.last_name
ORDER BY golovi DESC
LIMIT 5;
/*
first_name	last_name	golovi
Mattéo	O'Brien	34
Leo	Marsh	32
José	Muñoz	24
Marko	Stanković	17
Leo	Marsh	16
*/

SELECT p.first_name, p.last_name, COUNT(*) AS golovi
FROM match_events e
JOIN matches m ON e.match_id  = m.match_id
JOIN players p ON e.related_player_id = p.player_id
JOIN teams   t ON e.team_id   = t.team_id
WHERE m.season = '2024/25' AND e.event_type IN ('goal', 'penalty_goal') AND t.team_name = 'Kingsbridge City'
GROUP BY p.player_id, p.first_name, p.last_name
ORDER BY golovi DESC
LIMIT 5;

/*first_name	last_name	golovi
Filip	Petrović	7
Takumi	Yamamoto	5
Vinícius	Santos	5
Raphaël	Moreau	4
Aaron	Shaw	3
*/





