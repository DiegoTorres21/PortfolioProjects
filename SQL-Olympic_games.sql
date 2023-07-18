/*

Consultas a la base de datos histórica de los juegos olímpicos.

*/

/* 1. Cuántos juegos olímpicos se han llevado a cabo? */

SELECT COUNT(DISTINCT(games)) AS Total_number_of_olympic_game
FROM olympics_history


/* 2. Lista de todos las ediciones que se han llevado a cabo */

SELECT DISTINCT(year), season, city
FROM olympics_history
ORDER BY year


/* 3. Número total de naciones que participaron en cada edición de los juegos */

WITH subset AS(
	SELECT oh.games, ohnr.region 
	FROM olympics_history AS oh
	JOIN olympics_history_noc_regions AS ohnr
	ON oh.noc = ohnr.noc
	ORDER BY games)


SELECT games, COUNT(DISTINCT region) AS num_participating_nations
FROM subset
GROUP BY games


/* 4. En qué años se presentaron las ediciones con el mayor y menor número de paises participando en los juegos olímpicos.


Lo que hice al principio: */
WITH subset AS (
	SELECT oh.games, ohnr.region
	FROM olympics_history AS oh
	JOIN olympics_history_noc_regions AS ohnr ON oh.noc = ohnr.noc
	ORDER BY games
),
subset2 AS (	SELECT games, COUNT(DISTINCT region) AS num_participating_nations
	FROM subset
	GROUP BY games)


SELECT games, num_participating_nations
FROM subset2
WHERE num_participating_nations = (SELECT MAX(num_participating_nations) FROM subset2) or
num_participating_nations = (SELECT Min(num_participating_nations) FROM subset2);


/* Después de analizar el resultado esperado: */

WITH subset AS (
	SELECT oh.games, ohnr.region
	FROM olympics_history AS oh
	JOIN olympics_history_noc_regions AS ohnr ON oh.noc = ohnr.noc
	ORDER BY games
),
subset2 AS (	SELECT games, COUNT(DISTINCT region) AS num_participating_nations
	FROM subset
	GROUP BY games)

SELECT
	CONCAT(
	(SELECT games FROM subset2 WHERE num_participating_nations = (SELECT MIN(num_participating_nations) FROM subset2)), 
' - ', 
(SELECT MIN(num_participating_nations) FROM subset2)
	) AS lowest,
CONCAT(
(SELECT games FROM subset2 WHERE num_participating_nations = (SELECT MAX(num_participating_nations) FROM subset2)),
' - ',
(SELECT MAX(num_participating_nations) FROM subset2)
) AS highest;


/* 5. Qué paises han participado en todos los juegos olímpicos? */

WITH subset AS (SELECT oh.games, ohnr.region
			FROM olympics_history AS oh
			JOIN olympics_history_noc_regions AS ohnr ON oh.noc = ohnr.noc
			ORDER BY games), 

subset2 AS(
	SELECT region, COUNT (DISTINCT games) AS num_participations
	FROM subset
	GROUP BY region
	ORDER BY num_participations DESC)

SELECT region AS country, num_participations
	FROM subset2
	WHERE num_participations = (SELECT COUNT(DISTINCT(games)) FROM olympics_history)


/* 6. Deportes que fueron practicados en todos los juegos olímpicos de verano */

WITH subset AS(
SELECT COUNT(DISTINCT games)
FROM olympics_history
WHERE season = 'Summer'),
subset2 AS(SELECT sport, COUNT(DISTINCT games) AS number_of_games_played, season
FROM olympics_history
WHERE season = 'Summer'
GROUP BY sport, season)


SELECT sport, number_of_games_played, (SELECT * FROM subset) AS total_summer_games_played
	FROM subset2
	WHERE number_of_games_played = (SELECT* FROM subset)
	
	
/* 7. Qué deportes se practicaron en solo una edición? */

WITH subset AS(
SELECT COUNT(DISTINCT games)
FROM olympics_history),
subset2 AS(SELECT sport, COUNT(DISTINCT games) AS number_of_games_played
FROM olympics_history
GROUP BY sport)


SELECT * FROM subset2
WHERE number_of_games_played = 1
ORDER BY number_of_games_played DESC


/* 8. Número total de deportes practicados en cada edición */

SELECT games, COUNT(DISTINCT sport) AS number_of_sports_played
	FROM olympics_history
	GROUP BY games
	ORDER BY number_of_sports_played DESC
	
	
/* 9. Atletas de mayor edad en ganar una medalla de oro. */

WITH subset AS(
	SELECT name, age, medal, sex, games, sport, city, event
		FROM olympics_history
		WHERE medal = 'Gold' AND age <> 'NA'
		ORDER BY age DESC)


	SELECT name AS Athlete, age, medal, sex, games, sport, city, event
		FROM subset
		WHERE age = (SELECT DISTINCT FIRST_VALUE(age) OVER(ORDER BY age DESC) AS Oldest FROM subset)


/* 10. Proporción de atletas hombres y mujeres que han participado en los juegos olímpicos  */

SELECT 
    SUM(CASE WHEN sex = 'F' THEN 1 ELSE 0 END) AS female_count,
	SUM(CASE WHEN sex = 'M' THEN 1 ELSE 0 END) AS male_count,
    CONCAT('1 : ',ROUND(SUM(CASE WHEN sex = 'M' THEN 1 ELSE 0 END)::numeric / SUM(CASE WHEN sex = 'F' THEN 1 ELSE 0 END)::numeric, 2)) AS ratio
FROM olympics_history;


/* 11. Top 5 de atletas con la mayor cantidad de medallas de oro. */

WITH subset AS(
SELECT name, COUNT(*) AS gold_medals_count
FROM olympics_history
WHERE medal = 'Gold'
GROUP BY name
ORDER BY gold_medals_count DESC),


	subset2 AS(
	SELECT *, DENSE_RANK() OVER(ORDER BY gold_medals_count DESC) AS rnk
		FROM subset)
	
SELECT *
FROM subset2
WHERE rnk <= 5


/* 12. Top 5 de atletas con la mayor cantidad de medallas (oro/plata/bronce). */

WITH subset AS(
SELECT name, team, COUNT(*) AS total_medals
FROM olympics_history
WHERE medal <> 'NA'
GROUP BY name, team
ORDER BY total_medals DESC),


	subset2 AS(
	SELECT *, DENSE_RANK() OVER(ORDER BY total_medals DESC) AS rnk
		FROM subset
	)
	
SELECT *
FROM subset2
WHERE rnk <= 5


/* 13. Top 5 de paises con la mayor cantidad de medallas ganadas. */

WITH subset AS(
	SELECT ohnr.region AS country, medal
	FROM olympics_history AS oh
	JOIN olympics_history_noc_regions AS ohnr
	ON oh.noc = ohnr.noc
	),
	
	subset2 AS(
	SELECT country, COUNT(*) AS total_medals
	FROM subset
	WHERE medal <> 'NA'
	GROUP BY country
	ORDER BY total_medals DESC
	),
	
	subset3 AS(
	SELECT *, DENSE_RANK() OVER(ORDER BY total_medals DESC) AS rnk		FROM subset2
	)
	
SELECT *
FROM subset3
WHERE rnk <= 5


/* 14. Total de medallas de oro, plata y bronce ganadas por cada país.

Using SUM and CASE WHEN: */

WITH subset AS(
	SELECT ohnr.region AS country, medal
	FROM olympics_history AS oh
	JOIN olympics_history_noc_regions AS ohnr
	ON oh.noc = ohnr.noc
	),
	
	subset2 AS(SELECT country, 
	SUM(CASE WHEN medal = 'Gold' THEN 1 ELSE 0 END) AS gold_medals,
	SUM(CASE WHEN medal = 'Silver' THEN 1 ELSE 0 END) AS silver_medals,
	SUM(CASE WHEN medal = 'Bronze' THEN 1 ELSE 0 END) AS bronze_medals
	FROM subset
	GROUP BY country)
	


	
	SELECT *, (gold_medals + silver_medals + bronze_medals) AS total_medals
	FROM subset2
	ORDER BY gold_medals DESC, silver_medals DESC, bronze_medals DESC


/* Using CROSSTAB: */
SELECT country, COALESCE(gold, 0) as gold, COALESCE(silver, 0) as silver, COALESCE(bronze, 0) as bronze
	FROM crosstab('SELECT ohnr.region AS country, medal, COUNT(1) AS total_medals
			FROM olympics_history AS oh
			JOIN olympics_history_noc_regions AS ohnr
			ON oh.noc = ohnr.noc
			WHERE medal <> ''NA''
			GROUP BY ohnr.region, medal
			ORDER BY ohnr.region, medal',
			
			'values (''Bronze''), (''Gold''), (''Silver'') ')
			
		AS RESULT(country varchar, bronze bigint, gold bigint, silver bigint)
	ORDER BY gold DESC, silver DESC, bronze DESC


/* 15. Medallas de oro, plata y bronce ganadas por país en cada uno de los juegos olímpicos*/

SELECT SUBSTRING(games,1,POSITION(' - ' IN games)-1) AS games
			, country
			, coalesce(gold, 0) as gold
			, coalesce(silver, 0) as silver
			, coalesce(bronze, 0) as bronze
		FROM CROSSTAB('SELECT concat(games, '' - '', nr.region) as games
					, nr.region as country, medal
					, count(1) as total_medals
					FROM olympics_history oh
					JOIN olympics_history_noc_regions nr ON nr.noc = oh.noc
					where medal <> ''NA''
					GROUP BY games,nr.region,medal
					order BY games,medal',
				'values (''Bronze''), (''Gold''), (''Silver'')')
		AS FINAL_RESULT(games text, country text, bronze bigint, gold bigint, silver bigint)


/* 16. Pais que ganó el mayor número de medallas de oro, plata y bronze por cada una de las ediciones de los juegos olímpicos. */

WITH subset AS(	
	SELECT SUBSTRING(games,1,POSITION(' - ' IN games)-1) AS games
			, country
			, coalesce(gold, 0) as gold
			, coalesce(silver, 0) as silver
			, coalesce(bronze, 0) as bronze
		FROM CROSSTAB('SELECT concat(games, '' - '', nr.region) as games
					, nr.region as country, medal
					, count(1) as total_medals
					FROM olympics_history oh
					JOIN olympics_history_noc_regions nr ON nr.noc = oh.noc
					where medal <> ''NA''
					GROUP BY games,nr.region,medal
					order BY games,medal',
				'values (''Bronze''), (''Gold''), (''Silver'')')
		AS FINAL_RESULT(games text, country text, bronze bigint, gold bigint, silver bigint))
	
SELECT DISTINCT games, 
CONCAT(FIRST_VALUE(country) OVER(PARTITION BY games ORDER BY gold DESC), ' - ', FIRST_VALUE(gold) OVER(PARTITION BY games ORDER BY gold DESC )) AS most_gold,
CONCAT(FIRST_VALUE(country) OVER(PARTITION BY games ORDER BY silver DESC), ' - ', FIRST_VALUE(silver) OVER(PARTITION BY games ORDER BY silver DESC )) AS most_silver,
CONCAT(FIRST_VALUE(country) OVER(PARTITION BY games ORDER BY bronze DESC), ' - ', FIRST_VALUE(bronze) OVER(PARTITION BY games ORDER BY bronze DESC )) AS most_bronze


FROM subset
ORDER BY games


/* 17. Pais que ganó el mayor número de medallas de oro, plata, bronze y total de medallas por cada una de las ediciones de los juegos olímpicos. */

WITH subset AS(	
	SELECT SUBSTRING(games,1,POSITION(' - ' IN games)-1) AS games
			, country
			, coalesce(gold, 0) as gold
			, coalesce(silver, 0) as silver
			, coalesce(bronze, 0) as bronze		
			
		FROM CROSSTAB('SELECT concat(games, '' - '', nr.region) as games
					, nr.region as country, medal
					, count(1) as total_medals
					FROM olympics_history oh
					JOIN olympics_history_noc_regions nr ON nr.noc = oh.noc
					where medal <> ''NA''
					GROUP BY games,nr.region,medal
					order BY games,medal',
				'values (''Bronze''), (''Gold''), (''Silver'')')
		AS FINAL_RESULT(games text, country text, bronze bigint, gold bigint, silver bigint)),
		
	subset2 AS(
	SELECT *, (gold+silver+bronze) AS total_medals_by_country
	FROM subset)


SELECT DISTINCT games, 
CONCAT(FIRST_VALUE(country) OVER(PARTITION BY games ORDER BY gold DESC), ' - ', FIRST_VALUE(gold) OVER(PARTITION BY games ORDER BY gold DESC )) AS most_gold,
CONCAT(FIRST_VALUE(country) OVER(PARTITION BY games ORDER BY silver DESC), ' - ', FIRST_VALUE(silver) OVER(PARTITION BY games ORDER BY silver DESC )) AS most_silver,
CONCAT(FIRST_VALUE(country) OVER(PARTITION BY games ORDER BY bronze DESC), ' - ', FIRST_VALUE(bronze) OVER(PARTITION BY games ORDER BY bronze DESC )) AS most_bronze,
CONCAT(FIRST_VALUE(country) OVER(PARTITION BY games ORDER BY total_medals_by_country DESC), ' - ', FIRST_VALUE(total_medals_by_country) OVER(PARTITION BY games ORDER BY total_medals_by_country DESC )) AS most_medals
FROM subset2
ORDER BY games


/* 18. Qué paises nunca han ganado una medalla de oro pero han ganado alguna de plata o de bronze? */

WITH subset AS(
SELECT country, COALESCE(gold, 0) as gold, COALESCE(silver, 0) as silver, COALESCE(bronze, 0) as bronze
	FROM crosstab('SELECT ohnr.region AS country, medal, COUNT(1) AS total_medals
			FROM olympics_history AS oh
			JOIN olympics_history_noc_regions AS ohnr
			ON oh.noc = ohnr.noc
			WHERE medal <> ''NA''
			GROUP BY ohnr.region, medal
			ORDER BY ohnr.region, medal',
			
			'values (''Bronze''), (''Gold''), (''Silver'') ')
			
		AS RESULT(country varchar, bronze bigint, gold bigint, silver bigint)
	ORDER BY gold DESC, silver DESC, bronze DESC)
	
	
	SELECT *
	FROM subset
	WHERE gold = 0 AND (silver <> 0 OR bronze <> 0)
	ORDER BY gold desc, silver desc, bronze desc


/* 19. En qué deporte Colombia ha ganado el mayor número de medallas */

WITH subset AS(
SELECT ohnr.region AS country, medal, sport
			FROM olympics_history AS oh
			JOIN olympics_history_noc_regions AS ohnr
			ON oh.noc = ohnr.noc
			WHERE medal <> 'NA')


SELECT sport, COUNT(medal) AS medals
FROM subset
WHERE country = 'Colombia'
GROUP BY sport
ORDER BY medals DESC
LIMIT 1


/* 20. Medallas ganadas por Colombia en Ciclismo. */

WITH subset AS(
SELECT games, ohnr.region AS country, medal, sport
			FROM olympics_history AS oh
			JOIN olympics_history_noc_regions AS ohnr
			ON oh.noc = ohnr.noc
			WHERE medal <> 'NA')

SELECT country, sport, games, COUNT(medal) AS total_medals
FROM subset
WHERE country = 'Colombia' AND sport = 'Cycling'
GROUP BY country, sport, games
ORDER BY total_medals DESC
