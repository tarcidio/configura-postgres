-- Remove ALUNO, se existir
DROP TABLE IF EXISTS MATRICULADO;

-- Cria ALUNO com colunas de detalhes do aluno
CREATE TABLE MATRICULADO (
    CODIGO TEXT,      -- Identificador do aluno
    INGRESSO TEXT,    -- Ano de ingresso
    CURSO TEXT,       -- Nome do curso
    NOME TEXT,        -- Nome do aluno
    EMAIL TEXT,       -- Email do aluno
    SITUACAO TEXT     -- Situação do aluno (ex: ativo, trancado)
);

-- Remove GRUPO, se existir
DROP TABLE IF EXISTS GRUPO;

-- Cria GRUPO com colunas de associação entre aluno e grupo
CREATE TABLE GRUPO (
    ALUNO TEXT,       -- Nome do aluno
    NUSP TEXT,        -- Número USP do aluno
    GRUPO TEXT        -- Nome ou código do grupo
);

-- Remove ALUNO, se existir
DROP TABLE IF EXISTS ALUNO;

-- Cria ALUNO com colunas de detalhes do aluno
CREATE TABLE ALUNO (
    NUSP TEXT,       -- Número USP do aluno
    NOME TEXT,       -- Nome do aluno
    GRUPO TEXT,      -- Nome ou código do grupo
    EMAIL TEXT,      -- Email do aluno
    SENHA TEXT       -- Senha gerada para o aluno
);

\copy MATRICULADO FROM 'F:\SCC0244-MGBD\SCC244-Organiza-Base\CSV\matriculados.csv' WITH (FORMAT csv, DELIMITER ',', HEADER true, ENCODING 'UTF-8');

\copy GRUPO FROM 'F:\SCC0244-MGBD\SCC244-Organiza-Base\CSV\grupos.csv' WITH (FORMAT csv, DELIMITER ',', HEADER true, ENCODING 'UTF-8');

-- Insere dados combinados na tabela ALUNO
INSERT INTO ALUNO (NUSP, NOME, GRUPO, EMAIL, SENHA)
SELECT 
    g.NUSP,
    m.NOME,
    g.GRUPO,
    m.EMAIL,
    'a' || g.NUSP AS SENHA
FROM MATRICULADO m
JOIN GRUPO g ON m.CODIGO = g.NUSP;

-- Remove ALUNO e GRUPO
DROP TABLE IF EXISTS MATRICULADO;
DROP TABLE IF EXISTS GRUPO;
