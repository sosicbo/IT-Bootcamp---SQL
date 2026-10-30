--2
WITH po_stadionu (
SELECT stadium_id, COUNT(attendance) as utakmice_sa_posetom
, ROUND(AVG(attendance)) AS prosecna_poseta
FROM matches 
WHERE season='2024/25' and status='played'
GROUP BY stadium_id
)
SELECT RANK() OVER (ORDER BY p.prosecna_poseta DESC) as rang
, s.stadium_id, s.stadium_name
FROM po_stadionu p
JOIN stadiums s ON s.stadium_id=p.stadium_id
QUALIFY rang<=3
ORDER BY rang;
