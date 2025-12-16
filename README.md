## Lab 5 : Agrégation, groupements et analyses


## Script SQL
```
USE bibliotheque;

-- Nombre total d’abonnés
SELECT COUNT(*) AS total_abonnes
FROM abonne;

-- Moyenne de prêts par abonné
SELECT AVG(nb) AS moyenne_emprunts
FROM (
    SELECT COUNT(*) AS nb
    FROM emprunt
    GROUP BY abonne_id
) AS sous;

-- ===============================
-- GROUP BY
-- ===============================

-- Nombre d’emprunts par abonné
SELECT abonne_id, COUNT(*) AS nbre_emprunts
FROM emprunt
GROUP BY abonne_id;

-- Nombre d’ouvrages par auteur
SELECT auteur_id, COUNT(*) AS total_ouvrages
FROM ouvrage
GROUP BY auteur_id;

-- ===============================
-- HAVING
-- ===============================

-- Abonnés ayant au moins 3 emprunts
SELECT abonne_id, COUNT(*) AS nbre_emprunts
FROM emprunt
GROUP BY abonne_id
HAVING COUNT(*) >= 3;

-- Auteurs avec plus de 5 ouvrages
SELECT auteur_id, COUNT(*) AS total_ouvrages
FROM ouvrage
GROUP BY auteur_id
HAVING COUNT(*) > 5;

-- ===============================
-- Jointures + agrégats
-- ===============================

-- Nom de l’abonné + nombre d’emprunts
SELECT a.nom, COUNT(e.ouvrage_id) AS emprunts
FROM abonne a
LEFT JOIN emprunt e ON e.abonne_id = a.id
GROUP BY a.id, a.nom;

-- Nom de l’auteur + total d’emprunts de ses ouvrages
SELECT au.nom, COUNT(e.ouvrage_id) AS total_emprunts
FROM auteur au
JOIN ouvrage o ON o.auteur_id = au.id
LEFT JOIN emprunt e ON e.ouvrage_id = o.id
GROUP BY au.id, au.nom;

-- ===============================
-- Analyses avancées
-- ===============================

-- Pourcentage d’ouvrages empruntés
SELECT 
  ROUND(
    COUNT(CASE WHEN e.ouvrage_id IS NOT NULL THEN 1 END) * 100
    / COUNT(DISTINCT o.id), 2
  ) AS pct_ouvrages_empruntes
FROM ouvrage o
LEFT JOIN emprunt e ON e.ouvrage_id = o.id;

-- Top 3 abonnés les plus actifs
SELECT a.nom, COUNT(*) AS nbre_emprunts
FROM abonne a
JOIN emprunt e ON e.abonne_id = a.id
GROUP BY a.id, a.nom
ORDER BY nbre_emprunts DESC
LIMIT 3;

-- ===============================
-- Sous-requêtes / CTE
-- ===============================

WITH stats AS (
    SELECT o.auteur_id,
           COUNT(e.ouvrage_id) AS emprunts,
           COUNT(DISTINCT o.id) AS ouvrages
    FROM ouvrage o
    LEFT JOIN emprunt e ON e.ouvrage_id = o.id
    GROUP BY o.auteur_id
)
SELECT auteur_id,
       emprunts / ouvrages AS moyenne_emprunts
FROM stats
WHERE emprunts / ouvrages > 2;

-- ===============================
-- Exercices pratiques
-- ===============================

-- Moyenne d’emprunts par jour de la semaine
SELECT DAYOFWEEK(date_debut) AS jour_semaine,
       COUNT(*) AS total
FROM emprunt
GROUP BY DAYOFWEEK(date_debut);

-- Total d’emprunts par mois (année 2025)
SELECT MONTH(date_debut) AS mois,
       COUNT(*) AS total
FROM emprunt
WHERE YEAR(date_debut) = 2025
GROUP BY MONTH(date_debut);

-- Ouvrages jamais empruntés
SELECT COUNT(*) AS ouvrages_jamais_empruntes
FROM ouvrage o
LEFT JOIN emprunt e ON e.ouvrage_id = o.id
WHERE e.ouvrage_id IS NULL;


```
# resultat du lab : 

```
total_abonnes
8
moyenne_emprunts
1.6000
abonne_id	nbre_emprunts
1	1
3	1
6	3
7	1
12	2
auteur_id	total_ouvrages
1	7
2	5
3	6
abonne_id	nbre_emprunts
6	3
auteur_id	total_ouvrages
1	7
3	6
nom	emprunts
Salma Laouy	1
Hiba Ouirouane	0
Asma Laouy	1
Karim	0
Samir	3
Karim	1
Karim	2
Lucie	0
nom	total_emprunts
Victor Hugo	3
Albert Camus	0
J.K. Rowling	5
pct_ouvrages_empruntes
44.44
nom	nbre_emprunts
Samir	3
Karim	2
Asma Laouy	1
jour_semaine	total
1	4
4	1
5	2
6	1
mois	total
6	2
12	6
ouvrages_jamais_empruntes
16
 
```
## Script SQL de l'exercice:
```
USE bibliotheque;

-- ======================================
-- CTE 1 : Extraire les emprunts de 2025 avec année et mois
-- ======================================
WITH emprunts_2025 AS (
    SELECT 
        e.abonne_id,
        e.ouvrage_id,
        YEAR(e.date_debut) AS annee,
        MONTH(e.date_debut) AS mois
    FROM emprunt e
    WHERE YEAR(e.date_debut) = 2025
),

-- ======================================
-- CTE 2 : Calcul des indicateurs de base par mois
-- ======================================
indicateurs_base AS (
    SELECT 
        annee,
        mois,
        COUNT(*) AS total_emprunts,
        COUNT(DISTINCT abonne_id) AS abonnes_actifs,
        ROUND(COUNT(*) / COUNT(DISTINCT abonne_id), 2) AS moyenne_par_abonne
    FROM emprunts_2025
    GROUP BY annee, mois
),

-- ======================================
-- CTE 3 : Comptage des emprunts par ouvrage et par mois
-- ======================================
emprunts_ouvrages AS (
    SELECT 
        annee,
        mois,
        ouvrage_id,
        COUNT(*) AS nb_emprunts
    FROM emprunts_2025
    GROUP BY annee, mois, ouvrage_id
),

-- ======================================
-- CTE 4 : Classement des ouvrages par mois
-- ======================================
top_ouvrages AS (
    SELECT 
        eo.annee,
        eo.mois,
        eo.ouvrage_id,
        eo.nb_emprunts,
        ROW_NUMBER() OVER (PARTITION BY eo.annee, eo.mois ORDER BY eo.nb_emprunts DESC) AS rang
    FROM emprunts_ouvrages eo
),

-- ======================================
-- CTE 5 : Ouvrages top 3 par mois avec titres
-- ======================================
top3_ouvrages AS (
    SELECT 
        t.annee,
        t.mois,
        GROUP_CONCAT(o.titre ORDER BY t.rang ASC SEPARATOR ', ') AS top_3_ouvrages
    FROM top_ouvrages t
    JOIN ouvrage o ON o.id = t.ouvrage_id
    WHERE t.rang <= 3
    GROUP BY t.annee, t.mois
),

-- ======================================
-- CTE 6 : Pourcentage d’ouvrages empruntés
-- ======================================
pct_ouvrages AS (
    SELECT 
        e.annee,
        e.mois,
        ROUND(COUNT(DISTINCT e.ouvrage_id) * 100 / (SELECT COUNT(*) FROM ouvrage), 2) AS pct_empruntes
    FROM emprunts_2025 e
    GROUP BY e.annee, e.mois
)

-- ======================================
-- Requête finale : rapport mensuel complet
-- ======================================
SELECT 
    ib.annee,
    ib.mois,
    COALESCE(ib.total_emprunts, 0) AS total_emprunts,
    COALESCE(ib.abonnes_actifs, 0) AS abonnes_actifs,
    COALESCE(ib.moyenne_par_abonne, 0) AS moyenne_par_abonne,
    COALESCE(po.pct_empruntes, 0) AS pct_ouvrages_empruntes,
    COALESCE(t3.top_3_ouvrages, '') AS top_3_ouvrages
FROM indicateurs_base ib
LEFT JOIN pct_ouvrages po 
    ON ib.annee = po.annee AND ib.mois = po.mois
LEFT JOIN top3_ouvrages t3
    ON ib.annee = t3.annee AND ib.mois = t3.mois
ORDER BY ib.annee, ib.mois;


```

# resultat de l'exercice:
```
annee	mois	total_emprunts	abonnes_actifs	moyenne_par_abonne	pct_ouvrages_empruntes	top_3_ouvrages
2025	6	2	2	1.00	5.56	Harry Potter … l'‚cole des sorciers
2025	12	6	4	1.50	11.11	Les Mis‚rables, Harry Potter … l'‚cole des sorciers


```
## Capture d’écran  
![image alt](https://github.com/laouysalma/Tp5MySQL/blob/main/Ex1.jpg?raw=true)

