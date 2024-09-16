DO $$
DECLARE
    prefixoNomeEsquema TEXT := 'GRUPO';
BEGIN
    -- Log para acompanhamento
    RAISE NOTICE 'Iniciando deleção dos esquemas';
    CALL  Administrador.DeletarEsquemas(prefixoNomeEsquema);
    -- Log para acompanhamento
    RAISE NOTICE 'Deleção dos esquemas concluída';

    -- Log para acompanhamento
    RAISE NOTICE 'Iniciando deleção dos usuários';
    CALL  Administrador.DeletarUsuarios();
    -- Log para acompanhamento
    RAISE NOTICE 'Deleção dos usuário concluída';

    -- Log para acompanhamento
    RAISE NOTICE 'Iniciando deleção dos papéis';
    CALL Administrador.DeletarPapeis(prefixoNomeEsquema);
    -- Log para acompanhamento
    RAISE NOTICE 'Deleção dos papéis concluída';
END $$;