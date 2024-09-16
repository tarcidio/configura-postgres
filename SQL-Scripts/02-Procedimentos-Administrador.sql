DROP SCHEMA IF EXISTS Administrador CASCADE;
CREATE SCHEMA Administrador;

-- Procedure: Cria um esquema e um papel associado, além de conceder permissões sobre o banco de dados, esquema e objetos
-- Entrada: NomeEsquema (nome base do esquema), NomeBancoDados (nome do banco de dados)
-- Saída: Nenhuma (log de operações realizadas)
CREATE OR REPLACE PROCEDURE Administrador.CriarEsquemaPapelEPrivilegios(NomeEsquema TEXT, NomeBancoDados TEXT)
LANGUAGE plpgsql
AS $$
DECLARE
    comando TEXT;
    sufixoEsquema TEXT := '-ESQUEMA';
    sufixoPapel TEXT := '-PAPEL';
    nomeEsquemaCompleto TEXT := NomeEsquema || sufixoEsquema;
    nomePapelCompleto TEXT := NomeEsquema || sufixoPapel;
BEGIN
    -- Criar Esquema
    EXECUTE format('CREATE SCHEMA IF NOT EXISTS %I', nomeEsquemaCompleto);

    -- Log mensagem de acompanhamento
    RAISE NOTICE 'Esquema % foi criado', nomeEsquemaCompleto;

    -- Criar Papel para o esquema criado
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = nomePapelCompleto) THEN
        EXECUTE format('CREATE ROLE %I', nomePapelCompleto);
        -- Log mensagem de acompanhamento
        RAISE NOTICE 'Papel % foi criado', nomePapelCompleto;
    ELSE
        -- Log mensagem de acompanhamento
        RAISE NOTICE 'Papel % já tinha sido criado antes', nomePapelCompleto;
    END IF;

    -- Concede permissão para acessar o banco de dados
    EXECUTE format('GRANT CONNECT ON DATABASE %I TO %I', NomeBancoDados, nomePapelCompleto);

    -- Concede permissão para acessar o esquema
    EXECUTE format('GRANT USAGE ON SCHEMA %I TO %I', nomeEsquemaCompleto, nomePapelCompleto);

    -- Concede permissão para criar objetos no esquema
    EXECUTE format('GRANT CREATE ON SCHEMA %I TO %I', nomeEsquemaCompleto, nomePapelCompleto);

    -- Concede todas as permissões sobre todas as tabelas, sequências e funções existentes no esquema
    EXECUTE format('GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA %I TO %I', nomeEsquemaCompleto, nomePapelCompleto);
    EXECUTE format('GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA %I TO %I', nomeEsquemaCompleto, nomePapelCompleto);
    EXECUTE format('GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA %I TO %I', nomeEsquemaCompleto, nomePapelCompleto);

    -- Concede todas as permissões para tabelas, sequências e funções que ainda serão criadas no esquema
    EXECUTE format('ALTER DEFAULT PRIVILEGES IN SCHEMA %I GRANT ALL PRIVILEGES ON TABLES TO %I', nomeEsquemaCompleto, nomePapelCompleto);
    EXECUTE format('ALTER DEFAULT PRIVILEGES IN SCHEMA %I GRANT ALL PRIVILEGES ON SEQUENCES TO %I', nomeEsquemaCompleto, nomePapelCompleto);
    EXECUTE format('ALTER DEFAULT PRIVILEGES IN SCHEMA %I GRANT ALL PRIVILEGES ON FUNCTIONS TO %I', nomeEsquemaCompleto, nomePapelCompleto);

    -- Configura o search_path para esta Papel
    EXECUTE format('ALTER ROLE %I SET search_path TO %I', nomePapelCompleto, nomeEsquemaCompleto);

    -- Log mensagem de acompanhamento
    RAISE NOTICE 'Papel % recebeu os privlégio para seu esquema', nomePapelCompleto;
END;
$$;

-- Procedure: Cria múltiplos esquemas e papéis correspondentes, iterando com base em um prefixo e número
-- Entrada: NumEsquemas (número de esquemas a criar), PrefixoNomeEsquema (prefixo para o nome dos esquemas), NomeBancoDados (nome do banco de dados)
-- Saída: Nenhuma (log de operações realizadas)
CREATE OR REPLACE PROCEDURE Administrador.CriarEsquemasERespectivosPapeis(NumEsquemas INT, PrefixoNomeEsquema TEXT, NomeBancoDados TEXT)
LANGUAGE plpgsql
AS $$
DECLARE
    nomeEsquema TEXT;
BEGIN
    FOR i IN 1..NumEsquemas LOOP
        IF i < 10 THEN
            nomeEsquema := PrefixoNomeEsquema || '-' || '0' || i;
        ELSE
            nomeEsquema := PrefixoNomeEsquema || '-' || i;
        END IF;

        -- Será commitado apenas quando Administrador.CriarEsquemasERespectivosPapeis também for
        CALL Administrador.CriarEsquemaPapelEPrivilegios(nomeEsquema, NomeBancoDados);
    END LOOP;
EXCEPTION
    WHEN OTHERS THEN
        -- Se houver erro, registrar a mensagem
        RAISE NOTICE 'Erro ao criar esquema %: %. Fazendo reversão: todos esquemas e papéis criados estão sendo deletados', nomeEsquema, SQLERRM;
END;
$$;

-- Procedure: Cria um usuário com senha e atribui um papel a ele
-- Entrada: NUSP ('nome' do usuário), Senha (senha do usuário), NomePapel (nome do papel a ser concedido)
-- Saída: Nenhuma (log de operações realizadas)
CREATE OR REPLACE PROCEDURE Administrador.CriarUsuarioComSenhaEPapel(NUSP TEXT, Senha TEXT, NomePapel TEXT)
LANGUAGE plpgsql
AS $$
BEGIN
    -- Cria o usuário com a senha fornecida
    EXECUTE format('CREATE USER %I WITH PASSWORD %L', NUSP, Senha);

    -- Log mensagem de acompanhamento
    RAISE NOTICE 'Usuário % foi criado', NUSP;
    
    -- Verifica se o Papel já existe
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = NomePapel) THEN
        -- Se o Papel não existir, levanta um erro
        RAISE EXCEPTION 'Papel % não existe.', NomePapel;
    ELSE
        -- Log mensagem de acompanhamento
        RAISE NOTICE 'Papel % existe e pode ser atribuído ao usuário %.', NomePapel, NUSP;
    END IF;

    -- Concede o Papel ao usuário
    EXECUTE format('GRANT %I TO %I', NomePapel, NUSP);

    -- Log mensagem de acompanhamento
    RAISE NOTICE 'Usuário % recebeu o papel %', NUSP, NomePapel;
EXCEPTION
    WHEN duplicate_object THEN
        -- Se o usuário já existir, exibe mensagem de erro
        RAISE NOTICE 'Usuário % já existe.', NUSP;
    WHEN others THEN
        -- Se houver um erro inesperado, exibe a mensagem de erro
        RAISE NOTICE 'Erro ao criar o usuário %: %', NUSP, SQLERRM;
END;
$$;

-- Procedure: Cria múltiplos usuários com base em uma tabela de alunos e concede papéis
-- Entrada: TabelaAlunos (nome da tabela de alunos com NUSP e senha), PrefixoNomePapel (prefixo dos papéis)
-- Saída: Nenhuma (log de operações realizadas)
CREATE OR REPLACE PROCEDURE Administrador.CriarUsuarios(TabelaAlunos TEXT, PrefixoNomePapel TEXT)
LANGUAGE plpgsql
AS $$
DECLARE
    tuplaUsuario RECORD;
BEGIN
    FOR tuplaUsuario IN
        EXECUTE format(
            'SELECT 
                NUSP,
                Senha,
                NomePapel
            FROM %I
            JOIN (
                SELECT 
                    rolname AS NomePapel,
                    ROW_NUMBER() OVER (ORDER BY rolname) AS NumeroPapel
                FROM pg_roles
                WHERE 
                    rolname NOT LIKE ''pg_%%''
                    AND rolname <> ''pg_read_all_data''
                    AND rolname LIKE %L
            ) AS TabelaEsquema
            ON %I.Grupo = TabelaEsquema.NumeroPapel::TEXT',
            TabelaAlunos,
            '%' || PrefixoNomePapel || '%',
            TabelaAlunos
        )
    LOOP
        -- Cria o usuário e concede o papel
        EXECUTE format('CALL Administrador.CriarUsuarioComSenhaEPapel(%L, %L, %L)', 
                       tuplaUsuario.NUSP, 
                       tuplaUsuario.Senha, 
                       tuplaUsuario.NomePapel);
    END LOOP;
END;
$$;

-- Procedure: Deleta esquemas com base em um prefixo de nome
-- Entrada: PrefixoNomeEsquema (prefixo dos esquemas a serem deletados)
-- Saída: Nenhuma (log de operações realizadas)
CREATE OR REPLACE PROCEDURE Administrador.DeletarEsquemas(PrefixoNomeEsquema TEXT)
LANGUAGE plpgsql
AS $$
DECLARE
    rec RECORD;
BEGIN
    FOR rec IN 
        SELECT schema_name 
        FROM information_schema.schemata
        WHERE schema_name LIKE '%' || PrefixoNomeEsquema || '%'
    LOOP
        BEGIN
            EXECUTE format('DROP SCHEMA IF EXISTS %I CASCADE', rec.schema_name);
            RAISE NOTICE 'Esquema % deletado.', rec.schema_name;
        EXCEPTION
            WHEN OTHERS THEN
                RAISE WARNING 'Falha ao deletar esquema %: %', rec.schema_name, SQLERRM;
        END;
    END LOOP;
END;
$$;

-- Procedure: Deleta usuários com prefixo numérico (NUSP)
-- Entrada: Nenhuma
-- Saída: Nenhuma (log de operações realizadas)
CREATE OR REPLACE PROCEDURE Administrador.DeletarUsuarios()
LANGUAGE plpgsql
AS $$
DECLARE
    rec RECORD;
BEGIN
    -- Deleta todas os usuários com prefixo numérico
    FOR rec IN 
        SELECT rolname 
        FROM pg_roles
        WHERE rolname ~ '^\d+$'
    LOOP
        BEGIN
            EXECUTE format('DROP ROLE IF EXISTS %I', rec.rolname);
            RAISE NOTICE 'Usuário % deletado.', rec.rolname;
        EXCEPTION
            WHEN OTHERS THEN
                RAISE WARNING 'Falha ao deletar usuário %: %', rec.rolname, SQLERRM;
        END;
    END LOOP;
END;
$$;

-- Procedure: Deleta todos os papéis que possuem um prefixo específico no nome
-- Entrada: PrefixoNomePapel (prefixo dos papéis a serem deletados)
-- Saída: Nenhuma (log de operações realizadas)
CREATE OR REPLACE PROCEDURE Administrador.DeletarPapeis(PrefixoNomePapel TEXT)
LANGUAGE plpgsql
AS $$
DECLARE
    rec RECORD;
BEGIN
    -- Deleta todas os papéis com o prefixo fornecido
    FOR rec IN 
        SELECT rolname 
        FROM pg_roles
        WHERE rolname LIKE '%' || PrefixoNomePapel || '%'
    LOOP
        BEGIN
            EXECUTE format('DROP OWNED BY %I CASCADE', rec.rolname);
            EXECUTE format('DROP ROLE IF EXISTS %I', rec.rolname);
            RAISE NOTICE 'Papel % deletado.', rec.rolname;
        EXCEPTION
            WHEN OTHERS THEN
                RAISE WARNING 'Falha ao deletar papel %: %', rec.rolname, SQLERRM;
        END;
    END LOOP;
END;
$$;
