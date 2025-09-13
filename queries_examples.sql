-- ======================================================
-- CONSULTAS BÁSICAS
-- ======================================================

-- 1) Total de registros
SELECT COUNT(*) FROM trabalho_sp;

-- 2) Laudas por ano
SELECT ano_planilha, SUM(laudas) AS total_laudas
FROM trabalho_sp
GROUP BY ano_planilha
ORDER BY ano_planilha;

-- 3) Top 5 tipos de documentos
SELECT tipo_documento, COUNT(*) AS total
FROM trabalho_sp
GROUP BY tipo_documento
ORDER BY total DESC
LIMIT 5;

-- 4) Idiomas mais frequentes
SELECT idioma, COUNT(*) AS total
FROM trabalho_sp
GROUP BY idioma
ORDER BY total DESC;

-- ======================================================
-- CONSULTAS AVANÇADAS
-- ======================================================

-- 5) Totais gerais (CQ vs Revisão)
SELECT tipo_atividade, COUNT(*) AS total
FROM trabalho_sp
WHERE tipo_atividade IN ('CQ','Revisão')
GROUP BY tipo_atividade
ORDER BY total DESC;

-- 6) Totais por ano (CQ vs Revisão)
SELECT ano_planilha, tipo_atividade, COUNT(*) AS total
FROM trabalho_sp
WHERE tipo_atividade IN ('CQ','Revisão')
GROUP BY ano_planilha, tipo_atividade
ORDER BY ano_planilha, tipo_atividade;

-- 7) Totais por mês (agregando todos os anos)
SELECT mes_num,
       CASE mes_num
            WHEN 1 THEN 'Janeiro' WHEN 2 THEN 'Fevereiro'
            WHEN 3 THEN 'Março'   WHEN 4 THEN 'Abril'
            WHEN 5 THEN 'Maio'    WHEN 6 THEN 'Junho'
            WHEN 7 THEN 'Julho'   WHEN 8 THEN 'Agosto'
            WHEN 9 THEN 'Setembro' WHEN 10 THEN 'Outubro'
            WHEN 11 THEN 'Novembro' WHEN 12 THEN 'Dezembro'
       END AS mes,
       tipo_atividade,
       COUNT(*) AS total
FROM trabalho_sp
WHERE tipo_atividade IN ('CQ','Revisão')
GROUP BY mes_num, tipo_atividade
ORDER BY mes_num, tipo_atividade;

-- 8) Mês mais movimentado (somando CQ + Revisão, todos os anos)
SELECT mes_num,
       CASE mes_num
            WHEN 1 THEN 'Janeiro' WHEN 2 THEN 'Fevereiro'
            WHEN 3 THEN 'Março'   WHEN 4 THEN 'Abril'
            WHEN 5 THEN 'Maio'    WHEN 6 THEN 'Junho'
            WHEN 7 THEN 'Julho'   WHEN 8 THEN 'Agosto'
            WHEN 9 THEN 'Setembro' WHEN 10 THEN 'Outubro'
            WHEN 11 THEN 'Novembro' WHEN 12 THEN 'Dezembro'
       END AS mes,
       COUNT(*) AS total
FROM trabalho_sp
WHERE tipo_atividade IN ('CQ','Revisão')
GROUP BY mes_num
ORDER BY total DESC
LIMIT 1;

-- 9) Idioma mais revisado em cada ano
WITH contagem AS (
    SELECT ano_planilha, idioma, COUNT(*) AS total
    FROM trabalho_sp
    WHERE tipo_atividade IN ('CQ','Revisão')
    GROUP BY ano_planilha, idioma
),
ranked AS (
    SELECT contagem.*,
           RANK() OVER (PARTITION BY ano_planilha ORDER BY total DESC) AS rk
    FROM contagem
)
SELECT ano_planilha, idioma, total
FROM ranked
WHERE rk = 1
ORDER BY ano_planilha;

-- 10) Mês mais movimentado em cada ano
WITH mensal AS (
    SELECT ano_planilha, mes_num, COUNT(*) AS total
    FROM trabalho_sp
    WHERE tipo_atividade IN ('CQ','Revisão')
    GROUP BY ano_planilha, mes_num
),
ranked AS (
    SELECT m.*,
           RANK() OVER (PARTITION BY ano_planilha ORDER BY total DESC) AS rk
    FROM mensal m
)
SELECT ano_planilha, mes_num,
       CASE mes_num
            WHEN 1 THEN 'Janeiro' WHEN 2 THEN 'Fevereiro'
            WHEN 3 THEN 'Março'   WHEN 4 THEN 'Abril'
            WHEN 5 THEN 'Maio'    WHEN 6 THEN 'Junho'
            WHEN 7 THEN 'Julho'   WHEN 8 THEN 'Agosto'
            WHEN 9 THEN 'Setembro' WHEN 10 THEN 'Outubro'
            WHEN 11 THEN 'Novembro' WHEN 12 THEN 'Dezembro'
       END AS mes,
       total
FROM ranked
WHERE rk = 1
ORDER BY ano_planilha;

-- 11) Idioma mais revisado em cada mês, dentro de cada ano
WITH contagem AS (
    SELECT ano_planilha, mes_num, idioma, COUNT(*) AS total
    FROM trabalho_sp
    WHERE tipo_atividade IN ('CQ','Revisão')
    GROUP BY ano_planilha, mes_num, idioma
),
ranked AS (
    SELECT contagem.*,
           RANK() OVER (PARTITION BY ano_planilha, mes_num ORDER BY total DESC) AS rk
    FROM contagem
)
SELECT ano_planilha, mes_num,
       CASE mes_num
            WHEN 1 THEN 'Janeiro' WHEN 2 THEN 'Fevereiro'
            WHEN 3 THEN 'Março'   WHEN 4 THEN 'Abril'
            WHEN 5 THEN 'Maio'    WHEN 6 THEN 'Junho'
            WHEN 7 THEN 'Julho'   WHEN 8 THEN 'Agosto'
            WHEN 9 THEN 'Setembro' WHEN 10 THEN 'Outubro'
            WHEN 11 THEN 'Novembro' WHEN 12 THEN 'Dezembro'
       END AS mes,
       idioma, total
FROM ranked
WHERE rk = 1
ORDER BY ano_planilha, mes_num;

-- 12) Documento mais recorrente em cada mês por ano
WITH contagem AS (
    SELECT ano_planilha, mes_num, tipo_documento, COUNT(*) AS total
    FROM trabalho_sp
    GROUP BY ano_planilha, mes_num, tipo_documento
),
ranked AS (
    SELECT contagem.*,
           RANK() OVER (PARTITION BY ano_planilha, mes_num ORDER BY total DESC) AS rk
    FROM contagem
)
SELECT ano_planilha, mes_num,
       CASE mes_num
            WHEN 1 THEN 'Janeiro' WHEN 2 THEN 'Fevereiro'
            WHEN 3 THEN 'Março'   WHEN 4 THEN 'Abril'
            WHEN 5 THEN 'Maio'    WHEN 6 THEN 'Junho'
            WHEN 7 THEN 'Julho'   WHEN 8 THEN 'Agosto'
            WHEN 9 THEN 'Setembro' WHEN 10 THEN 'Outubro'
            WHEN 11 THEN 'Novembro' WHEN 12 THEN 'Dezembro'
       END AS mes,
       tipo_documento, total
FROM ranked
WHERE rk = 1
ORDER BY ano_planilha, mes_num;

-- 13) Tempo médio por tipo de documento
SELECT tipo_documento,
       ROUND(AVG(EXTRACT(EPOCH FROM (termino::time - inicio::time)) / 60), 2) AS media_minutos,
       COUNT(*) AS total_registros
FROM trabalho_sp
WHERE tipo_atividade IN ('CQ','Revisão')
  AND inicio IS NOT NULL
  AND termino IS NOT NULL
GROUP BY tipo_documento
ORDER BY media_minutos DESC;

-- 14) Documentos que mais demoraram (Top 10)
SELECT tipo_documento,
       ROUND(AVG(EXTRACT(EPOCH FROM (termino::time - inicio::time)) / 60), 2) AS media_minutos
FROM trabalho_sp
WHERE tipo_atividade IN ('CQ','Revisão')
  AND inicio IS NOT NULL
  AND termino IS NOT NULL
GROUP BY tipo_documento
ORDER BY media_minutos DESC
LIMIT 10;

-- 15) Tempo médio por documento (ajustado pela quantidade de docs)
SELECT 
    tipo_documento,
    ROUND(SUM(EXTRACT(EPOCH FROM (termino::time - inicio::time)) / 60), 2) AS tempo_total_minutos,
    ROUND(SUM(EXTRACT(EPOCH FROM (termino::time - inicio::time)) / 60) / NULLIF(SUM(num_docs),0), 2) AS tempo_medio_por_doc,
    SUM(num_docs) AS total_docs
FROM trabalho_sp
WHERE tipo_atividade IN ('CQ','Revisão')
  AND inicio IS NOT NULL
  AND termino IS NOT NULL
GROUP BY tipo_documento
ORDER BY tempo_medio_por_doc DESC;

-- ======================================================
