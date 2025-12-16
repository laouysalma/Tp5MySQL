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
