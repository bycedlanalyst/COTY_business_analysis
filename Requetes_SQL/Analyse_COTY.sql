--OBJECTIF DU PROJET
--Construire une analyse de marché et un système analytique simulé permettant d’analyser la
--performance commerciale (sell-in / sell-out), les promotions et les opportunités business.

/* =====================================================
   1. CREATION BASE & SCHEMA
===================================================== */
CREATE DATABASE IF NOT EXISTS PROJET_COTY;
USE DATABASE PROJET_COTY;
CREATE SCHEMA IF NOT EXISTS ANALYSE;
USE SCHEMA ANALYSE;

/* =====================================================
   2. DIMENSION PRODUITS
===================================================== */
CREATE OR REPLACE TABLE DIM_PRODUCTS (
    PRODUCT_ID      INT               NOT NULL,    -- Identifiant unique du produit
    PRODUCT_NAME    VARCHAR           NOT NULL,    -- Nom du produit
    BRAND           VARCHAR,                       -- Marque (Coty ou concurrent)
    CATEGORY        VARCHAR,                       -- Catégorie (Parfum, Makeup, Skincare)
    PRICE           NUMBER(10,2),                  -- Prix du produit
    LAUNCH_DATE     DATE,                          -- Date de lancement
    CONSTRAINT PK_PRODUCTS PRIMARY KEY (PRODUCT_ID)
);

/* =====================================================
   3. DIMENSION MAGASINS
===================================================== */
CREATE OR REPLACE TABLE DIM_STORES (
    STORE_ID        INT               NOT NULL,    -- Identifiant unique du magasin
    STORE_NAME      VARCHAR           NOT NULL,    -- Nom du magasin
    REGION          VARCHAR,                       -- Région géographique
    STORE_TYPE      VARCHAR,                       -- Type (Hypermarket, Online, Parfumerie...)
    CONSTRAINT PK_STORES PRIMARY KEY (STORE_ID)
);

/* =====================================================
   4. DIMENSION PROMOTIONS
===================================================== */
CREATE OR REPLACE TABLE DIM_PROMOTIONS (
    PROMO_ID         INT              NOT NULL,    -- Identifiant unique de la promotion
    PRODUCT_ID       INT              NOT NULL,    -- Produit concerné
    START_DATE       DATE,                         -- Date de début
    END_DATE         DATE,                         -- Date de fin
    DISCOUNT_PERCENT NUMBER(5,2),                  -- Pourcentage de réduction ex: 15.50
    CONSTRAINT PK_PROMOTIONS PRIMARY KEY (PROMO_ID),
    CONSTRAINT FK_PROMO_PRODUCT FOREIGN KEY (PRODUCT_ID) REFERENCES DIM_PRODUCTS(PRODUCT_ID)
);

/* =====================================================
   5. TABLE DE FAITS - VENTES
===================================================== */
CREATE OR REPLACE TABLE FACT_SALES (
    SALE_ID         INT               NOT NULL,    -- Identifiant unique de la vente
    DATE            DATE              NOT NULL,    -- Date de la transaction
    PRODUCT_ID      INT               NOT NULL,    -- Référence au produit
    STORE_ID        INT               NOT NULL,    -- Référence au magasin
    PROMO_ID        INT,                           -- Référence promotion (NULL si aucune)
    UNITS_SOLD      INT,                           -- Quantité vendue
    REVENUE         NUMBER(15,2),                  -- Chiffre d'affaires généré
    CONSTRAINT PK_SALES    PRIMARY KEY (SALE_ID),
    CONSTRAINT FK_PRODUCT  FOREIGN KEY (PRODUCT_ID) REFERENCES DIM_PRODUCTS(PRODUCT_ID),
    CONSTRAINT FK_STORE    FOREIGN KEY (STORE_ID)   REFERENCES DIM_STORES(STORE_ID),
    CONSTRAINT FK_PROMO    FOREIGN KEY (PROMO_ID)   REFERENCES DIM_PROMOTIONS(PROMO_ID)
);

/* =====================================================
   6. DIMENSION MARCHE
===================================================== */
CREATE OR REPLACE TABLE DIM_MARKET (
    YEAR          INT,                             -- Année
    CATEGORY      VARCHAR,                         -- Catégorie
    MARKET_SIZE   NUMBER(15,2),                    -- Taille du marché
    GROWTH_RATE   NUMBER(5,2)                      -- Taux de croissance ex: 3.75
);


SELECT * FROM FACT_SALES;
SELECT * FROM DIM_PRODUCTS;
SELECT * FROM DIM_PROMOTIONS;
SELECT * FROM DIM_MARKET;
SELECT * FROM DIM_STORES;


ALTER TABLE DIM_STORES

ALTER TABLE PROJET_COTY.ANALYSE.DIM_STORES 
ALTER COLUMN STORE_ID SET DATA TYPE INTEGER;

DROP TABLE DIM_STORES;


--Chiffre d'affaires mensuel
SELECT 
    DATE_TRUNC('MONTH', DATE)    AS MOIS,
    SUM(REVENUE)                 AS CA_MENSUEL
FROM PROJET_COTY.ANALYSE.FACT_SALES
GROUP BY DATE_TRUNC('MONTH', DATE)
ORDER BY MOIS DESC;
--Top 10 des meilleurs produits en fonction du Brand, du CA ,de la categorie et du total Vendu:
SELECT 
    p.PRODUCT_NAME,
    p.BRAND,
    p.CATEGORY,
    ROUND(SUM(f.REVENUE), 2)     AS CA_TOTAL,
    SUM(f.UNITS_SOLD)            AS TOTAL_UNITES_VENDUES
FROM PROJET_COTY.ANALYSE.FACT_SALES f
JOIN PROJET_COTY.ANALYSE.DIM_PRODUCTS p ON f.PRODUCT_ID = p.PRODUCT_ID
GROUP BY p.PRODUCT_NAME, p.BRAND, p.CATEGORY
ORDER BY CA_TOTAL DESC
LIMIT 10;



--Top produits par catégorie :
SELECT 
    p.CATEGORY,
    p.PRODUCT_NAME,
    p.BRAND,
    ROUND(SUM(f.REVENUE), 2)     AS CA_TOTAL
FROM PROJET_COTY.ANALYSE.FACT_SALES f
JOIN PROJET_COTY.ANALYSE.DIM_PRODUCTS p ON f.PRODUCT_ID = p.PRODUCT_ID
GROUP BY p.CATEGORY, p.PRODUCT_NAME, p.BRAND
ORDER BY p.CATEGORY, CA_TOTAL DESC;


--Impact des promotions par produit :
SELECT 
    pr.PRODUCT_NAME,
    pr.BRAND,
    pr.CATEGORY,
    p.DISCOUNT_PERCENT               AS REMISE_PERCENT,
    COUNT(f.SALE_ID)                 AS NB_VENTES,
    SUM(f.UNITS_SOLD)                AS TOTAL_UNITES_VENDUES,
    ROUND(SUM(f.REVENUE), 2)         AS CA_TOTAL
FROM PROJET_COTY.ANALYSE.FACT_SALES f
JOIN PROJET_COTY.ANALYSE.DIM_PROMOTIONS p  ON f.PROMO_ID  = p.PROMO_ID
JOIN PROJET_COTY.ANALYSE.DIM_PRODUCTS  pr ON f.PRODUCT_ID = pr.PRODUCT_ID
GROUP BY pr.PRODUCT_NAME, pr.BRAND, pr.CATEGORY, p.DISCOUNT_PERCENT
ORDER BY CA_TOTAL DESC;


--Performance par région et par catégorie de produit :
SELECT 
    s.REGION,
    p.CATEGORY,
    COUNT(f.SALE_ID)                 AS NB_VENTES,
    SUM(f.UNITS_SOLD)                AS TOTAL_UNITES_VENDUES,
    ROUND(SUM(f.REVENUE), 2)         AS CA_TOTAL
FROM PROJET_COTY.ANALYSE.FACT_SALES f
JOIN PROJET_COTY.ANALYSE.DIM_STORES  s ON f.STORE_ID  = s.STORE_ID
JOIN PROJET_COTY.ANALYSE.DIM_PRODUCTS p ON f.PRODUCT_ID = p.PRODUCT_ID
GROUP BY s.REGION, p.CATEGORY
ORDER BY s.REGION, CA_TOTAL DESC;

--Performance par région et par type de magasin :
SELECT 
    s.REGION,
    s.STORE_TYPE,
    COUNT(f.SALE_ID)                 AS NB_VENTES,
    SUM(f.UNITS_SOLD)                AS TOTAL_UNITES_VENDUES,
    ROUND(SUM(f.REVENUE), 2)         AS CA_TOTAL
FROM PROJET_COTY.ANALYSE.FACT_SALES f
JOIN PROJET_COTY.ANALYSE.DIM_STORES s ON f.STORE_ID = s.STORE_ID
GROUP BY s.REGION, s.STORE_TYPE
ORDER BY s.REGION, CA_TOTAL DESC;

--Évolution du marché beauté en France
SELECT 
    TO_CHAR(DATE, 'YYYY')        AS ANNEE,
    p.CATEGORY,
    ROUND(SUM(f.REVENUE), 2)     AS CA_TOTAL,
    SUM(f.UNITS_SOLD)            AS UNITES_VENDUES
FROM PROJET_COTY.ANALYSE.FACT_SALES f
JOIN PROJET_COTY.ANALYSE.DIM_PRODUCTS p ON f.PRODUCT_ID = p.PRODUCT_ID
GROUP BY ANNEE, p.CATEGORY
ORDER BY ANNEE, CA_TOTAL DESC;


--Impact des promotions par segment
SELECT 
    p.CATEGORY,
    CASE 
        WHEN f.PROMO_ID IS NOT NULL THEN 'Avec Promotion'
        ELSE 'Sans Promotion'
    END                              AS STATUT_PROMO,
    ROUND(AVG(f.UNITS_SOLD), 2)      AS MOY_UNITES_VENDUES,
    ROUND(AVG(f.REVENUE), 2)         AS CA_MOYEN
FROM PROJET_COTY.ANALYSE.FACT_SALES f
JOIN PROJET_COTY.ANALYSE.DIM_PRODUCTS p ON f.PRODUCT_ID = p.PRODUCT_ID
GROUP BY p.CATEGORY, STATUT_PROMO
ORDER BY p.CATEGORY;


--Performance régionale — où COTY peut progresser
SELECT 
    s.REGION,
    p.BRAND,
    ROUND(SUM(f.REVENUE), 2)         AS CA_TOTAL,
    ROUND(SUM(f.REVENUE) * 100.0 / SUM(SUM(f.REVENUE)) OVER (PARTITION BY s.REGION), 2) AS PART_MARCHE_REGION_PCT
FROM PROJET_COTY.ANALYSE.FACT_SALES f
JOIN PROJET_COTY.ANALYSE.DIM_STORES   s ON f.STORE_ID   = s.STORE_ID
JOIN PROJET_COTY.ANALYSE.DIM_PRODUCTS p ON f.PRODUCT_ID = p.PRODUCT_ID
GROUP BY s.REGION, p.BRAND
ORDER BY s.REGION, CA_TOTAL DESC;


--Performance COTY vs concurrents dans le temps
SELECT 
    TO_CHAR(f.DATE, 'YYYY-MM')       AS MOIS,
    p.BRAND,
    ROUND(SUM(f.REVENUE), 2)         AS CA_MENSUEL
FROM PROJET_COTY.ANALYSE.FACT_SALES f
JOIN PROJET_COTY.ANALYSE.DIM_PRODUCTS p ON f.PRODUCT_ID = p.PRODUCT_ID
GROUP BY MOIS, p.BRAND
ORDER BY MOIS, CA_MENSUEL DESC;


--Taux de croissance par catégorie
SELECT 
    p.CATEGORY,
    TO_CHAR(f.DATE, 'YYYY')          AS ANNEE,
    ROUND(SUM(f.REVENUE), 2)         AS CA_TOTAL,
    ROUND(
        (SUM(f.REVENUE) - LAG(SUM(f.REVENUE)) OVER (PARTITION BY p.CATEGORY ORDER BY TO_CHAR(f.DATE, 'YYYY')))
        * 100.0 / NULLIF(LAG(SUM(f.REVENUE)) OVER (PARTITION BY p.CATEGORY ORDER BY TO_CHAR(f.DATE, 'YYYY')), 0)
    , 2)                             AS CROISSANCE_PCT
FROM PROJET_COTY.ANALYSE.FACT_SALES f
JOIN PROJET_COTY.ANALYSE.DIM_PRODUCTS p ON f.PRODUCT_ID = p.PRODUCT_ID
GROUP BY p.CATEGORY, ANNEE
ORDER BY p.CATEGORY, ANNEE;


--Taux de Croissance mensuelle
SELECT 
    p.CATEGORY,
    TO_CHAR(f.DATE, 'YYYY-MM')       AS MOIS,
    ROUND(SUM(f.REVENUE), 2)         AS CA_MENSUEL,
    ROUND(
        (SUM(f.REVENUE) - LAG(SUM(f.REVENUE)) OVER (PARTITION BY p.CATEGORY ORDER BY TO_CHAR(f.DATE, 'YYYY-MM')))
        * 100.0 / NULLIF(LAG(SUM(f.REVENUE)) OVER (PARTITION BY p.CATEGORY ORDER BY TO_CHAR(f.DATE, 'YYYY-MM')), 0)
    , 2)                             AS CROISSANCE_VS_MOIS_PRECEDENT_PCT
FROM PROJET_COTY.ANALYSE.FACT_SALES f
JOIN PROJET_COTY.ANALYSE.DIM_PRODUCTS p ON f.PRODUCT_ID = p.PRODUCT_ID
GROUP BY p.CATEGORY, MOIS
ORDER BY p.CATEGORY, MOIS;

--Taux de Croissance par trimestre
SELECT 
    p.CATEGORY,
    QUARTER(f.DATE)                  AS TRIMESTRE,
    ROUND(SUM(f.REVENUE), 2)         AS CA_TRIMESTRIEL,
    ROUND(
        (SUM(f.REVENUE) - LAG(SUM(f.REVENUE)) OVER (PARTITION BY p.CATEGORY ORDER BY QUARTER(f.DATE)))
        * 100.0 / NULLIF(LAG(SUM(f.REVENUE)) OVER (PARTITION BY p.CATEGORY ORDER BY QUARTER(f.DATE)), 0)
    , 2)                             AS EVOLUTION_VS_TRIM_PRECEDENT_PCT
FROM PROJET_COTY.ANALYSE.FACT_SALES f
JOIN PROJET_COTY.ANALYSE.DIM_PRODUCTS p ON f.PRODUCT_ID = p.PRODUCT_ID
GROUP BY p.CATEGORY, TRIMESTRE
ORDER BY p.CATEGORY, TRIMESTRE;


--KPI Cards
SELECT 
    COUNT(DISTINCT f.SALE_ID)        AS TOTAL_VENTES,
    SUM(f.UNITS_SOLD)                AS TOTAL_UNITES,
    ROUND(SUM(f.REVENUE), 2)         AS CA_TOTAL,
    ROUND(AVG(f.REVENUE), 2)         AS PANIER_MOYEN,
    COUNT(DISTINCT f.PRODUCT_ID)     AS NB_PRODUITS_ACTIFS,
    COUNT(DISTINCT f.STORE_ID)       AS NB_MAGASINS_ACTIFS
FROM PROJET_COTY.ANALYSE.FACT_SALES f;

--Parts de marché globales par marque
SELECT 
    p.BRAND,
    ROUND(SUM(f.REVENUE), 2)         AS CA_TOTAL,
    ROUND(SUM(f.REVENUE) * 100.0 / SUM(SUM(f.REVENUE)) OVER (), 2) AS PART_MARCHE_PCT
FROM PROJET_COTY.ANALYSE.FACT_SALES f
JOIN PROJET_COTY.ANALYSE.DIM_PRODUCTS p ON f.PRODUCT_ID = p.PRODUCT_ID
GROUP BY p.BRAND
ORDER BY CA_TOTAL DESC;


--Impact des promotions par produit
SELECT 
    pr.PRODUCT_NAME,
    pr.BRAND,
    pr.CATEGORY,
    p.DISCOUNT_PERCENT               AS REMISE_PERCENT,
    COUNT(f.SALE_ID)                 AS NB_VENTES,
    SUM(f.UNITS_SOLD)                AS TOTAL_UNITES_VENDUES,
    ROUND(SUM(f.REVENUE), 2)         AS CA_TOTAL
FROM PROJET_COTY.ANALYSE.FACT_SALES f
JOIN PROJET_COTY.ANALYSE.DIM_PROMOTIONS p  ON f.PROMO_ID  = p.PROMO_ID
JOIN PROJET_COTY.ANALYSE.DIM_PRODUCTS  pr ON f.PRODUCT_ID = pr.PRODUCT_ID
GROUP BY pr.PRODUCT_NAME, pr.BRAND, pr.CATEGORY, p.DISCOUNT_PERCENT
ORDER BY CA_TOTAL DESC;*

--CA par canal de distribution
SELECT 
    s.STORE_TYPE,
    COUNT(f.SALE_ID)                 AS NB_VENTES,
    ROUND(SUM(f.REVENUE), 2)         AS CA_TOTAL,
    ROUND(SUM(f.REVENUE) * 100.0 / SUM(SUM(f.REVENUE)) OVER (), 2) AS PART_PCT
FROM PROJET_COTY.ANALYSE.FACT_SALES f
JOIN PROJET_COTY.ANALYSE.DIM_STORES s ON f.STORE_ID = s.STORE_ID
GROUP BY s.STORE_TYPE
ORDER BY CA_TOTAL DESC;
