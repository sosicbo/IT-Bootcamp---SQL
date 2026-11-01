USE bootcamp.nothern_star;

CREATE SCHEMA IF NOT EXISTS bootcamp.sandbox;
USE bootcamp.sandbox;

CREATE OR REPLACE TABLE dim_date AS
SELECT CAST(DATE_FORMAT(d, 'yyyyMMdd') AS INT) AS date_key,
       d                                       AS full_date,
       DATE_FORMAT(d, 'EEEE')                  AS weekday_name,
       DAYOFWEEK(d) IN (1, 7)                  AS is_weekend,
       CASE WHEN MONTH(d) >= 7 THEN CONCAT(YEAR(d), '/', SUBSTRING(CAST(YEAR(d) + 1 AS STRING), 3, 2))
            ELSE CONCAT(YEAR(d) - 1, '/', SUBSTRING(CAST(YEAR(d) AS STRING), 3, 2))
       END                                     AS season
FROM (SELECT EXPLODE(SEQUENCE(DATE'2023-07-01', DATE'2025-06-30', INTERVAL 1 DAY)) AS d);

CREATE OR REPLACE TABLE dim_player AS
SELECT
player_id,
first_name,
last_name,
position,
nationality
FROM bootcamp.nothern_star.players
UNION ALL
SELECT -1, 'Nepoznat', 'igrac', NULL, NULL;

CREATE OR REPLACE TABLE dim_referee AS
SELECT referee_id, referee_name
FROM bootcamp.nothern_star.referees

CREATE OR REPLACE TABLE fact_card AS
SELECT 
e.event_id,
e.match_id,
CAST(DATE_FORMAT(m.kickoff_ts, 'yyyyMMdd') AS INT) AS date_key,
e.team_id,
CASE WHEN p.player_id IS NULL THEN -1 ELSE e.player_id END as player_id,
m.referee_id,
e.event_type AS card_type
FROM bootcamp.nothern_star.match_events e
JOIN bootcamp.nothern_star.matches m ON m.match_id=e.match_id
LEFT JOIN bootcamp.nothern_star.players p ON p.player_id=e.player_id
WHERE e.event_type IN ('yellow_card', 'second_yellow', 'red_card');

--2
SELECT COUNT (*) FROM fact_card; --2678
SELECT COUNT(*) FROM bootcamp.nothern_star.match_events e  WHERE e.event_type IN ('yellow_card', 'second_yellow', 'red_card');--2678

--3
SELECT COUNT(*) AS karton_nep_igraca
FROM fact_card WHERE player_id=-1;--2

--4
--Jedan red u fact_card je jedan karton (zuti, drugi zuti ili crveni)
--Tabela je povezana sa 4 dimenzije, dim_player preko player_id, dim_team preko team_id, dim_referee preko referee_id i deam_date preko date_key
--Kartoni imaju svoju tabelu cinjenica jer se na jednoj utakmici moze dati vise kartona, ap se ne mogu smestiti u isti red jedne utakmice. Kada je svaki karton u zasebnom redu, jednostavnije je brojanje, koliko redova toliko kartona, bilo da gledamo po sudiji,klubu igracu ili datumu.

