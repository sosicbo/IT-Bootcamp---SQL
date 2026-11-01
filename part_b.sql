
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
SELECT
MONTH(kickoff_ts) as mesec
,COUNT(*) as br_mec
,SUM(home_goals+away_goals) AS golovi
, ROUND(AVG(home_goals+away_goals),2) AS prosek_utakmica
FROM matches
WHERE season='2024/25' AND status='played'
GROUP BY MONTH(kickoff_ts)
ORDER BY prosek_utakmica DESC;--avgust najvise: 8	28	99	3.54

--3. Публика: просечна посета и попуњеност по стадиону; утакмице без податка о посети и утакмица без публике.

SELECT 
s.stadium_id, s.stadium_name,
COUNT(*) as br_mec
,ROUND(AVG(m.attendance)) AS prosek,
ROUND(AVG(100 * m.attendance / s.capacity), 1) AS popunjenost_pct
FROM matches m
JOIN stadiums s ON m.stadium_id   = s.stadium_id
WHERE m.season = '2024/25' AND m.status = 'played'
GROUP BY s.stadium_id, s.stadium_name
ORDER BY popunjenost_pct DESC;
--Elmsworth Lane	19	21746	90.6

SELECT COUNT(*) - COUNT(m.attendance) AS bez_podatka
, COUNT_IF(m.attendance=0) AS bez_publike
FROM matches m
JOIN stadiums s ON m.stadium_id   = s.stadium_id
WHERE m.season = '2024/25' AND m.status = 'played';
--9	0

--4. Судије: за сваког судију број утакмица и картони по утакмици.
WITH kartoni AS(
SELECT m.match_id, m.referee_id,
COUNT(e.event_id) AS kartoni
FROM matches m
LEFT JOIN match_events e ON e.match_id = m.match_id  AND e.event_type IN ('yellow_card', 'second_yellow', 'red_card')
WHERE m.status='played' AND m.season='2024/25'
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
--Peter Lindgren	20	85	4.25

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
WHERE m.season = '2024/25' AND e.event_type IN ('goal', 'penalty_goal') 
GROUP BY p.player_id, p.first_name, p.last_name
ORDER BY golovi DESC
LIMIT 5;

/*first_name	last_name	golovi
Pablo	Fernández	9
Filip	Petrović	7
Eirik	Solberg	7
Lucas	Pereira	7
Mikkel	Nielsen	6
*/

--6
--1.provera:dogadjaji sa nepostojecim igracem
SELECT e.event_id, e.match_id, e.player_id, e.event_type
FROM match_events e
LEFT JOIN players p ON p.player_id=e.player_id
WHERE e.player_id IS NOT NULL AND p.player_id IS NULL;
--event_id	match_id	player_id	event_type
--1024	1071	99999	yellow_card
--1634	1111	99999	yellow_card

SELECT e.event_id, e.match_id, e.player_id, e.event_type
FROM match_events e
LEFT JOIN players p ON p.player_id=e.player_id
JOIN matches m ON e.match_id  = m.match_id
WHERE e.player_id IS NOT NULL AND p.player_id IS NULL AND m.season = '2024/25';
--ali nije relevantno za sezonu 2024/25

--2.rezultat se ne slaze sa dogadjajima
SELECT m.match_id, m.home_goals+ m.away_goals as br_golova_mec
, COUNT(e.event_id) as br_golova_dogadja
FROM matches m
LEFT JOIN match_events e ON e.match_id=m.match_id AND e.event_type IN ('goal', 'penalty_goal', 'own_goal')
WHERE m.season='2024/25' AND m.status='played'
GROUP BY m.match_id, m.home_goals, m.away_goals
HAVING m.home_goals+ m.away_goals <> COUNT(e.event_id);
--2227	4	3 

--3.postoje 9 utakmica bez podataka o posecenosti
SELECT COUNT(*) - COUNT(m.attendance) AS bez_podatka
FROM matches m
JOIN stadiums s ON m.stadium_id   = s.stadium_id
WHERE m.season = '2024/25' AND m.status = 'played';



