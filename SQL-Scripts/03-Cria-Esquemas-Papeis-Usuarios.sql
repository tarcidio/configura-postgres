DO $$
DECLARE
    nomeBaseDados TEXT := 'scc244_2024';
    prefixoNomeEsquema TEXT := 'GRUPO';
    nomeTabelaAluno TEXT := 'aluno';
    numGrupos INT;
BEGIN
    -- Contar o número de grupos distintos e armazenar o resultado em numGrupos
    SELECT COUNT(DISTINCT grupo) INTO numGrupos FROM aluno;
    
    -- Exibir o resultado
    RAISE NOTICE 'Número de grupos distintos: %', numGrupos;
   
    -- Log para acompanhamento
    RAISE NOTICE 'Iniciando criação dos esquemas e papéis';
    -- Cria esquemas para cada grupo e suas respectivas roles 
    CALL Administrador.CriarEsquemasERespectivosPapeis(numGrupos, prefixoNomeEsquema, nomeBaseDados);
    -- Log para acompanhamento
    RAISE NOTICE 'Criação dos esquemas e papéis concluído';

    -- Log para acompanhamento
    RAISE NOTICE 'Iniciando criação de usuários';
    -- Cria usuários
    CALL Administrador.CriarUsuarios(nomeTabelaAluno, prefixoNomeEsquema);
    -- Log para acompanhamento
    RAISE NOTICE 'Criação dos usuários concluído';
END $$;