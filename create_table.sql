CREATE TABLE trabalho_sp (
    id SERIAL PRIMARY KEY,
    ano INT,
    data DATE,
    referencia VARCHAR(50),
    tipo_atividade VARCHAR(20),
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
