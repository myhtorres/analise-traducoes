from pathlib import Path

import pandas as pd

# Caminho base onde estão os arquivos
BASE = Path("/Users/myrelletorres/Documents/sp_traducoes_dados")

# Arquivos por ano
arquivos = {
    "2022": BASE / "Planilha Controle Pessoa - 2022.xlsx",
    "2023": BASE / "Planilha Controle Pessoal - 2023.xlsx",
    "2024": BASE / "Planilha Controle Pessoal - 2024.xlsx",
    "2025": BASE / "Planilha Controle Pessoal - 2025.xlsx",
}

# Mapeamento de nomes variáveis para nomes padronizados
RENOMEAR = {
    "Referência": "referencia",
    "Referência CQ / REVISÃO": "tipo_atividade",
    "CQ / REVISÃO": "tipo_atividade",
    "CQ/Revisão": "tipo_atividade",
    "Enviado por": "enviado_por",
    "Enviado Por": "enviado_por",
    "Arquivos em": "arquivos_em",
    "Arquivos em:": "arquivos_em",
    "Nº de Laudas": "laudas",
    "Nº de Docs": "num_docs",
    "Tipo de documento": "tipo_documento",
    "Tipo de Documento": "tipo_documento",
    "Data": "Data",
    "Idioma": "Idioma",
    "Início": "Início",
    "Término": "Término",
}

# Mapeamento dos meses
MAPA_MESES = {
    "Janeiro": 1, "Fevereiro": 2, "Março": 3, "Abril": 4,
    "Maio": 5, "Junho": 6, "Julho": 7, "Agosto": 8,
    "Setembro": 9, "Outubro": 10, "Novembro": 11, "Dezembro": 12
}

# Lista de colunas finais (sem observacoes e sem ano duplicado)
COLUNAS_FINAL = [
    "Data", "referencia", "tipo_atividade", "enviado_por", "Idioma",
    "arquivos_em", "laudas", "Início", "Término", "num_docs", "tipo_documento",
    "ano_planilha", "mes_aba", "mes_num"
]

# Função para padronizar colunas de uma aba
def padronizar_colunas(df, ano, aba):
    df = df.rename(columns=RENOMEAR)

    # Garante todas as colunas presentes
    for c in COLUNAS_FINAL:
        if c not in df.columns:
            df[c] = None

    # Normaliza tipo_atividade (CQ, Revisão)
    if "tipo_atividade" in df.columns:
        df["tipo_atividade"] = (
            df["tipo_atividade"].astype(str)
            .str.strip()
            .str.replace(r"(?i)cq", "CQ", regex=True)
            .str.replace(r"(?i)revis(ão|ao)?", "Revisão", regex=True)
        )

    # Converte datas para formato brasileiro
    df["Data"] = pd.to_datetime(df["Data"], dayfirst=True, errors="coerce").dt.strftime("%d/%m/%Y")

    # Normaliza horário: Início e Término
    for hcol in ["Início", "Término"]:
        df[hcol] = (
            df[hcol].astype(str)
            .str.replace("0 days ", "", regex=False)
            .str.replace("1 days ", "24:00:00 ", regex=False)
            .str.strip()
            .str.replace(r"^(\d{1,2}:\d{2})$", r"\1:00", regex=True)
        )

        # Troca valores inválidos (ex: "CANCELADA") por NULL
        df[hcol] = pd.to_datetime(df[hcol], format="%H:%M:%S", errors="coerce").dt.strftime("%H:%M:%S")


    # Converte campos numéricos
    df["laudas"] = pd.to_numeric(df["laudas"], errors="coerce")
    df["num_docs"] = pd.to_numeric(df["num_docs"], errors="coerce").fillna(0).astype("Int64")

    # Adiciona colunas técnicas
    df["ano_planilha"] = ano
    df["mes_aba"] = aba
    df["mes_num"] = MAPA_MESES.get(aba.split()[0], None)

    # Retorna DataFrame com colunas na ordem certa
    return df[COLUNAS_FINAL]

# Lê todas as abas de um arquivo Excel
def ler_todas_as_abas(arquivo, ano):
    xls = pd.ExcelFile(arquivo)
    frames = []
    for aba in xls.sheet_names:
        if aba.lower().startswith("observ"):
            continue  # descarta Observações

        tmp = pd.read_excel(xls, sheet_name=aba)

        # Pula abas vazias
        if tmp.dropna(how="all").empty:
            continue

        # Remove colunas duplicadas
        tmp = tmp.loc[:, ~tmp.columns.duplicated(keep="first")]

        # Padroniza colunas
        tmp = padronizar_colunas(tmp, ano, aba)
        frames.append(tmp)

    # Retorna vazio se nada válido
    if not frames:
        return pd.DataFrame(columns=COLUNAS_FINAL)

    return pd.concat(frames, ignore_index=True)

# ============ PIPELINE PRINCIPAL ============

todos = []
for ano, arq in arquivos.items():
    print(f"Processando {ano} ({arq.name})...")
    df_ano = ler_todas_as_abas(arq, ano)
    todos.append(df_ano)

# Junta tudo
final = pd.concat(todos, ignore_index=True)

# Exporta para CSV final
saida = BASE / "trabalho_sp_padronizado.csv"
final.to_csv(saida, index=False, encoding="utf-8-sig")
print(f"✅ Arquivo final gerado: {saida}")






