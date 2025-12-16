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
