# Bojana Sosic

## Projekat se bavi pregledom fudbalske sezone 2024/25

## Podaci se dobijaju koriscenjenjem SQL koncepata


## Model fact_card

Jedan red u fact_card je jedan karton (zuti, drugi zuti ili crveni)
Tabela je povezana sa 4 dimenzije, dim_player preko player_id, dim_team preko team_id, dim_referee preko referee_id i deam_date preko date_key.
Kartoni imaju svoju tabelu cinjenica jer se na jednoj utakmici moze dati vise kartona, pa se ne mogu smestiti u isti red jedne utakmice. Kada je svaki karton u zasebnom redu, jednostavnije je brojanje, koliko redova toliko kartona, bilo da gledamo po sudiji, klubu igracu ili datumu.