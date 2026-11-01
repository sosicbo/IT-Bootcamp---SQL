USE bootcamp.nothern_star;
--1. Колико утакмица је одиграно у фебруару 2025? --40
SELECT COUNT(*)
--match_id, MONTH(m.kickoff_ts),YEAR(m.kickoff_ts)
FROM matches m
WHERE m.status='played' AND MONTH(m.kickoff_ts)=2 AND YEAR(m.kickoff_ts)='2025'; 

--2. Који стадион има највећи капацитет, а који је највећи стадион неког клуба?
SELECT s.stadium_id, s.stadium_name, s.capacity 
FROM stadiums s
ORDER BY s.capacity DESC NULLS LAST
LIMIT 1;
--22	National Stadium	80000 -ima najveci kapacitet

SELECT
t.team_id, t.team_name, s.stadium_id, s.stadium_name
, s.capacity 
FROM teams t
JOIN stadiums s ON s.stadium_id=t.stadium_id
ORDER BY s.capacity DESC
LIMIT 1;
--1	Northport United	1	Harbourside Park	52000
--INNER JOIN om je uzet samo stadijum koji ima tim

$0
--3. Колико играча у лиги има српско држављанство (nationality = 'Serbia')?--Serbia
SELECT COUNT(DISTINCT p.player_id) as br
FROM players p
JOIN player_match_stats ps ON ps.player_id=p.player_id
WHERE p.nationality='Serbia'; --39
--dodat INNER JOIN player_match_stats koji ucestvovali u ligi

--4. Колико утакмица је завршено резултатом 1:1?
SELECT 
COUNT(*)
FROM matches m
WHERE home_goals=1 AND away_goals=1
AND m.status='played';--94

--5. Колика је просечна посета по сезони?
SELECT m.season
, ROUND(AVG(m.attendance),2) AS prosecna_posecenost_sezona
FROM matches m
WHERE m.status='played'
GROUP BY m.season;
--2023/24	24276.2
--2024/25	24199.49

--6. Колико голова је дато из пенала по сезони?--penalty_goal
SELECT m.season
, COUNT(e.event_type) as br_penala
FROM matches m
JOIN match_events e ON e.match_id=m.match_id 
WHERE m.status='played' AND e.event_type='penalty_goal'
GROUP BY m.season;
--2023/24	104
--2024/25	109

--7. Колико различитих играча је дало бар један гол у сезони 2024/25?
SELECT COUNT(DISTINCT e.player_id)
FROM match_events e
JOIN matches m ON e.match_id=m.match_id 
WHERE m.season='2024/25' AND m.status='played' AND e.event_type IN ('goal','penalty_goal');--308
--nisam uzimala own_goal
--INNER JOIN om se izbacuju igraci bez golova

--8. Који судија је највише пута судио утакмице клуба Northport United?
SELECT 
r.referee_id, r.referee_name
, COUNT(m.match_id) as br_meceva
FROM matches m
JOIN referees r ON m.referee_id=r.referee_id
WHERE m.status='played'
AND m.home_team_id IN (SELECT team_id FROM teams WHERE team_name='Northport United') OR m.away_team_id IN (SELECT team_id FROM teams WHERE team_name='Northport United')
GROUP BY r.referee_id, r.referee_name
ORDER BY br_meceva DESC
LIMIT 1; --Peter Lindgren	9
--Dodat je referee_id u group by jer moze da se desi da ima vise sudija sa istim imenom

--9. Који судија је у сезони 2024/25 имао највећи удео утакмица у којима је досуђен бар један
--пенал, дат или промашен?
SELECT 
r.referee_id, r.referee_name
, COUNT(DISTINCT m.match_id) as br_mec
, COUNT(DISTINCT CASE WHEN e.event_id IS NOT NULL THEN m.match_id END) as br_mec_sa_penalom
, ROUND(100*COUNT(DISTINCT CASE WHEN e.event_id IS NOT NULL THEN m.match_id END)/COUNT(DISTINCT m.match_id),2)  as prct
FROM matches m
LEFT JOIN match_events e ON e.match_id=m.match_id AND e.event_type IN ('penalty_miss','penalty_goal')
JOIN referees r ON m.referee_id=r.referee_id
WHERE m.status='played' AND m.season='2024/25'
GROUP BY r.referee_id, r.referee_name
ORDER BY prct DESC
LIMIT 1;
--Peter Lindgren 	45 posto
--Dodat uslov za DISTINCT kao resenje sa sto manje izmena-jer se u slucaju veceg broja penala uzima se samo jedan mec u prebrojavanje

--10. Који тренер је освојио највише бодова у утакмицама у којима је његов тим губио на
--полувремену? Рачунајте и домаће и гостујуће утакмице.

CREATE OR REPLACE VIEW team_matches AS
    WITH sides AS (
        SELECT 
            match_id, season, matchday, kickoff_ts,
            home_team_id AS team_id, away_team_id AS opponent_id, 'home' AS
            venue,
            home_goals AS goals_for, away_goals AS goals_against
        FROM matches WHERE status = 'played'
        UNION ALL
        SELECT 
            match_id, season, matchday, kickoff_ts,
            away_team_id, home_team_id, 'away',
            away_goals, home_goals
        FROM matches WHERE status = 'played'
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

WITH utakmice AS(
    SELECT tm.team_id, tm.kickoff_ts, tm.points,
    CASE WHEN tm.venue='home' THEN m.home_goals_ht ELSE m.away_goals_ht END AS ht_dati,
    CASE WHEN tm.venue='home' THEN m.away_goals_ht ELSE m.home_goals_ht END AS ht_primljeni
    FROM team_matches tm
    JOIN matches m ON m.match_id=tm.match_id
)
SELECT ms.spell_id,ms.manager_name,
COUNT(*) as br_utakmica_gubljene_na_poluvremenu
, SUM(u.points) as bodovi
FROM utakmice u
JOIN manager_spells ms ON ms.team_id=u.team_id
AND DATE(u.kickoff_ts) BETWEEN ms.start_date AND COALESCE(ms.end_date, '9999-12-31')
WHERE u.ht_dati<u.ht_primljeni
GROUP BY ms.spell_id,ms.manager_name
ORDER BY bodovi DESC
LIMIT 1; --6	Zoran Tošić	16	18

--koriscen view tim mecevi
--dodat id kod trenera u slucaju da imaju vise sa istim imenom
--sabirani su svi bodovi gde je gubljeno na poluvrmenu, bez obzira da li je na kraju pobedio ili izgubio




















