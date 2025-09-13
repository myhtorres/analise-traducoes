# 📊 Projeto de Análise de Dados – Traduções  

Este projeto tem como objetivo consolidar planilhas de tradução de diferentes anos (2022–2025), padronizar os dados em Python e carregá-los em um banco de dados PostgreSQL para consultas SQL e análises.  

---

## 🚀 Fluxo de Trabalho  

1. **Padronização dos dados**  
   - Planilhas originais em Excel (2022–2025).  
   - Script Python `padronizar_planilhas.py` → renomeia colunas, trata diferenças, unifica formatos.  
   - Gera `trabalho_sp_padronizado.csv`.  

2. **Criação do banco de dados**  
   - Banco `sp_traducoes` criado no **pgAdmin**.  
   - Tabela `trabalho_sp` definida via SQL.  

3. **Carregamento dos dados**  
   - Importação do CSV via **pgAdmin → Import/Export Data**.  

4. **Consultas SQL**  
   - Análises de produtividade (nº de traduções, laudas, tipos de documentos, idiomas, etc.).  

---

## 🗄️ Estrutura da Tabela  

```sql
CREATE TABLE trabalho_sp (
    id SERIAL PRIMARY KEY,
    ano INT,
    data DATE,
    referencia VARCHAR(50),
    tipo_atividade VARCHAR(20),  -- CQ ou Revisão
    enviado_por VARCHAR(50),
    idioma VARCHAR(30),
    arquivos_em VARCHAR(50),
    laudas NUMERIC,
    inicio TIME,
    termino TIME,
    num_docs INT,
    tipo_documento VARCHAR(100),
    observacoes TEXT
);
````

---

## Script Python (Padronização)

O script [`padronizar_planilhas.py`](./padronizar_planilhas.py) utiliza **pandas** e **openpyxl** para:

* Renomear colunas inconsistentes.
* Tratar valores ausentes (`NULL`).
* Padronizar datas e horários.
* Converter colunas numéricas.
* Adicionar colunas técnicas (`ano_planilha`, `mes_aba`, `mes_num`).

Exemplo de execução no terminal:

```bash
python padronizar_planilhas.py
```

Saída esperada:

```
✅ Arquivo final gerado: trabalho_sp_padronizado.csv
```

---

## 🔍 Consultas Básicas

### Total de registros

```sql
SELECT COUNT(*) FROM trabalho_sp;
```

### Laudas por ano

```sql
SELECT ano, SUM(laudas) 
FROM trabalho_sp
GROUP BY ano
ORDER BY ano;
```

### Top 5 tipos de documentos

```sql
SELECT tipo_documento, COUNT(*) 
FROM trabalho_sp
GROUP BY tipo_documento
ORDER BY COUNT(*) DESC
LIMIT 5;
```

### Idiomas mais frequentes

```sql
SELECT idioma, COUNT(*) 
FROM trabalho_sp
GROUP BY idioma
ORDER BY COUNT(*) DESC;
```

---

## 🔍 Consultas Avançadas (Executadas no Projeto)

### 1) Totais gerais (CQ vs Revisão)

```sql
SELECT tipo_atividade, COUNT(*) AS total
FROM trabalho_sp
WHERE tipo_atividade IN ('CQ','Revisão')
GROUP BY tipo_atividade
ORDER BY total DESC;
```

---

### 2) Totais por ano (CQ vs Revisão)

```sql
SELECT ano_planilha, tipo_atividade, COUNT(*) AS total
FROM trabalho_sp
WHERE tipo_atividade IN ('CQ','Revisão')
GROUP BY ano_planilha, tipo_atividade
ORDER BY ano_planilha, tipo_atividade;
```

---

### 3) Totais por mês (agregando todos os anos)

```sql
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
```

---

### 4) Mês mais movimentado (todos os anos)

```sql
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
```

---

### 5) Idioma mais revisado em cada ano

```sql
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
```

---

### 6) Documento mais recorrente em cada mês por ano

```sql
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
SELECT ano_planilha,
       mes_num,
       CASE mes_num
            WHEN 1 THEN 'Janeiro' WHEN 2 THEN 'Fevereiro'
            WHEN 3 THEN 'Março'   WHEN 4 THEN 'Abril'
            WHEN 5 THEN 'Maio'    WHEN 6 THEN 'Junho'
            WHEN 7 THEN 'Julho'   WHEN 8 THEN 'Agosto'
            WHEN 9 THEN 'Setembro' WHEN 10 THEN 'Outubro'
            WHEN 11 THEN 'Novembro' WHEN 12 THEN 'Dezembro'
       END AS mes,
       tipo_documento,
       total
FROM ranked
WHERE rk = 1
ORDER BY ano_planilha, mes_num;
```

---

### 7) Tempo médio por tipo de documento

```sql
SELECT tipo_documento,
       ROUND(AVG(EXTRACT(EPOCH FROM (termino - inicio)) / 60), 2) AS media_minutos,
       COUNT(*) AS total_registros
FROM trabalho_sp
WHERE tipo_atividade IN ('CQ','Revisão')
  AND inicio IS NOT NULL
  AND termino IS NOT NULL
GROUP BY tipo_documento
ORDER BY media_minutos DESC;
```

---

### 8) Documentos que mais demoraram (Top 10)

```sql
SELECT tipo_documento,
       ROUND(AVG(EXTRACT(EPOCH FROM (termino - inicio)) / 60), 2) AS media_minutos
FROM trabalho_sp
WHERE tipo_atividade IN ('CQ','Revisão')
  AND inicio IS NOT NULL
  AND termino IS NOT NULL
GROUP BY tipo_documento
ORDER BY media_minutos DESC
LIMIT 10;
```

---

## 🛠️ Tecnologias Utilizadas

* **PostgreSQL + pgAdmin** → banco de dados relacional.
* **Python (pandas, openpyxl)** → tratamento e padronização das planilhas.
* **VS Code** → ambiente de desenvolvimento.

---

---

## Próximos Passos

Este projeto está em evolução. As próximas melhorias planejadas incluem:

- **Integração Python → PostgreSQL**: conectar o script `padronizar_planilhas.py` diretamente ao banco, carregando os dados sem precisar do CSV intermediário.  
- **Automação do fluxo ETL**: criar um pipeline que leia novas planilhas automaticamente e atualize o banco com os dados mais recentes.  
- **Visualizações em Power BI / Metabase**: desenvolver dashboards para analisar métricas como laudas traduzidas, tipos de documentos mais recorrentes e tempo médio de execução.  
- **Análises estatísticas adicionais**: aplicar técnicas de estatística descritiva e exploração para encontrar padrões nos dados de traduções.  
- **Validação de dados**: criar regras de consistência para evitar inconsistências (ex.: horários inválidos, colunas faltantes).  
