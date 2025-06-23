-- Codigo para funções das tabelas --

-- Função para cadastrar dados dentro de qualquer tabela --
CREATE OR REPLACE FUNCTION CADASTRAR(
	P_NOME_TABELA TEXT,
	P_VALORES_PARA_INSERIR TEXT
)
RETURNS VOID
AS $$
BEGIN
	EXECUTE 'INSERT INTO ' || quote_ident(P_NOME_TABELA) || ' VALUES (' || P_VALORES_PARA_INSERIR || ')';
	-- Note o espaço extra depois de 'INSERT INTO ' e antes de ' VALUES ('
	-- A função quote_ident() é usada para lidar com nomes de tabelas que podem conter caracteres especiais ou serem palavras-chave.

	RAISE NOTICE 'Dados inseridos corretamente na tabela %' , P_NOME_TABELA;

EXCEPTION
	WHEN OTHERS THEN
		RAISE EXCEPTION 'Erro ao inserir dados na tabela "%": %', P_NOME_TABELA, SQLERRM;
END;
$$
LANGUAGE PLPGSQL;

-- Função para deletar todos os dados dentro de qualquer tabela --
CREATE OR REPLACE FUNCTION DELETAR(
    P_NOME_TABELA TEXT,
    P_CONDICIONAL_DELETAR TEXT DEFAULT NULL
)
RETURNS VOID
AS $$
BEGIN
    IF (P_CONDICIONAL_DELETAR IS NULL) THEN
        -- Deleta todos os dados da tabela
        EXECUTE 'DELETE FROM ' || quote_ident(P_NOME_TABELA);
        
        RAISE NOTICE 'Todos os dados da tabela "%" foram deletados com sucesso.', P_NOME_TABELA;
    ELSE
        -- Deleta dados com base na condição fornecida
        EXECUTE 'DELETE FROM ' || quote_ident(P_NOME_TABELA) || ' WHERE ' || P_CONDICIONAL_DELETAR;
        RAISE NOTICE 'Os dados da tabela "%" com a condição "%" foram deletados com sucesso.', P_NOME_TABELA, P_CONDICIONAL_DELETAR;
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Erro ao deletar dados da tabela "%": %', P_NOME_TABELA, SQLERRM;
END;
$$
LANGUAGE PLPGSQL;

CREATE OR REPLACE FUNCTION ALTERAR(
    P_NOME_TABELA TEXT,
    P_CONJUNTO_ATUALIZACAO TEXT, 
    P_CONDICAO TEXT             
)
RETURNS VOID
AS $$
BEGIN
    EXECUTE 'UPDATE ' || quote_ident(P_NOME_TABELA) ||
            ' SET ' || P_CONJUNTO_ATUALIZACAO ||
            ' WHERE ' || P_CONDICAO;

    IF FOUND THEN -- Verifica se alguma linha foi afetada pelo UPDATE
        RAISE NOTICE 'Dados alterados corretamente na tabela %.', P_NOME_TABELA;
    ELSE
        RAISE NOTICE 'Nenhum registro encontrado ou alterado na tabela % com a condição especificada.', P_NOME_TABELA;
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Erro ao alterar dados na tabela "%": %', P_NOME_TABELA, SQLERRM;
END;
$$
LANGUAGE PLPGSQL;

CREATE OR REPLACE FUNCTION RESETAR_SERIAL()
RETURNS VOID
AS $$
BEGIN 
	ALTER SEQUENCE cliente_id_cliente_seq RESTART WITH 1;
	ALTER SEQUENCE funcionario_id_funcionario_seq RESTART WITH 1;
	ALTER SEQUENCE tipo_lavagem_id_tipo_lavagem_seq RESTART WITH 1;
	ALTER SEQUENCE tipo_pagamento_id_tipo_pagamento_seq RESTART WITH 1;
	ALTER SEQUENCE fornecedor_id_fornecedor_seq RESTART WITH 1;
	ALTER SEQUENCE produto_id_produto_seq RESTART WITH 1;
	ALTER SEQUENCE compra_id_compra_seq RESTART WITH 1;
	ALTER SEQUENCE item_id_item_seq RESTART WITH 1;
	ALTER SEQUENCE lavagem_id_lavagem_seq RESTART WITH 1;
	ALTER SEQUENCE parcela_id_parcela_seq RESTART WITH 1;
END;
$$
LANGUAGE PLPGSQL;


CREATE OR REPLACE FUNCTION LIMPAR_TODAS_TABELAS()
RETURNS VOID
AS $$
BEGIN
    -- Limpa tabelas com chaves estrangeiras primeiro
    PERFORM DELETAR('lavagem_produto');
    PERFORM DELETAR('parcela');
    PERFORM DELETAR('lavagem');
    PERFORM DELETAR('item');
    PERFORM DELETAR('compra');
    PERFORM DELETAR('produto');
    PERFORM DELETAR('fornecedor');
    PERFORM DELETAR('tipo_pagamento');
    PERFORM DELETAR('tipo_lavagem');
    PERFORM DELETAR('funcionario');
    PERFORM DELETAR('cliente');

    RAISE NOTICE 'Todas as tabelas foram limpas com sucesso.';
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Erro ao limpar tabelas: %', SQLERRM;
END;
$$
LANGUAGE PLPGSQL;

CREATE OR REPLACE FUNCTION trg_auditoria_generica()
RETURNS TRIGGER AS $$
DECLARE
    v_detalhes TEXT;
    v_id_afetado INT;
    v_nome_old TEXT := NULL;
    v_nome_new TEXT := NULL;
    v_cpf_old TEXT := NULL;
    v_cpf_new TEXT := NULL;
    v_pk_column_name_actual TEXT; -- Variável para armazenar o nome real da coluna PK
BEGIN
    -- Obter o nome real da coluna da Chave Primária para a tabela atual
    SELECT kcu.column_name
    INTO v_pk_column_name_actual
    FROM information_schema.table_constraints AS tc
    JOIN information_schema.key_column_usage AS kcu
        ON tc.constraint_name = kcu.constraint_name
        AND tc.table_schema = kcu.table_schema
    WHERE tc.table_name = TG_TABLE_NAME
      AND tc.constraint_type = 'PRIMARY KEY';

    -- Tentar obter o ID do registro afetado usando o nome real da PK
    BEGIN
        IF v_pk_column_name_actual IS NOT NULL THEN
            IF TG_OP = 'DELETE' THEN
                EXECUTE 'SELECT ($1).' || quote_ident(v_pk_column_name_actual) INTO v_id_afetado USING OLD;
            ELSE
                EXECUTE 'SELECT ($1).' || quote_ident(v_pk_column_name_actual) INTO v_id_afetado USING NEW;
            END IF;
        ELSE
            v_id_afetado := NULL; -- Não foi possível encontrar o nome da PK
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            v_id_afetado := NULL; -- Outros erros na obtenção da PK
    END;

    -- Tentar extrair NOME e CPF de forma genérica (se existirem nas tabelas OLD/NEW)
    -- Usa um bloco BEGIN/EXCEPTION para lidar com tabelas que não possuem NOME/CPF
    BEGIN
        IF TG_OP = 'INSERT' THEN
            EXECUTE 'SELECT $1.NOME, $1.CPF FROM ' || quote_ident(TG_TABLE_NAME) || ' AS tbl'
            INTO v_nome_new, v_cpf_new USING NEW;
            v_detalhes := 'Novo registro em ' || TG_TABLE_NAME || ': ' || COALESCE(v_nome_new, '') || ' (CPF: ' || COALESCE(v_cpf_new, '') || ')';

        ELSIF TG_OP = 'UPDATE' THEN
            EXECUTE 'SELECT $1.NOME, $1.CPF FROM ' || quote_ident(TG_TABLE_NAME) || ' AS tbl'
            INTO v_nome_old, v_cpf_old USING OLD;
            EXECUTE 'SELECT $1.NOME, $1.CPF FROM ' || quote_ident(TG_TABLE_NAME) || ' AS tbl'
            INTO v_nome_new, v_cpf_new USING NEW;

            v_detalhes := 'Atualização em ' || TG_TABLE_NAME || ' (ID: ' || COALESCE(v_id_afetado::TEXT, 'N/A') || '). ' ||
                          'Nome de "' || COALESCE(v_nome_old, 'N/A') || '" para "' || COALESCE(v_nome_new, 'N/A') || '". ' ||
                          'CPF de "' || COALESCE(v_cpf_old, 'N/A') || '" para "' || COALESCE(v_cpf_new, 'N/A') || '".';

        ELSIF TG_OP = 'DELETE' THEN
            EXECUTE 'SELECT $1.NOME, $1.CPF FROM ' || quote_ident(TG_TABLE_NAME) || ' AS tbl'
            INTO v_nome_old, v_cpf_old USING OLD;
            v_detalhes := 'Registro deletado de ' || TG_TABLE_NAME || ': "' || COALESCE(v_nome_old, '') || '" (CPF: ' || COALESCE(v_cpf_old, '') || ')';
        END IF;

    EXCEPTION
        WHEN undefined_column THEN
            -- Fallback se as colunas NOME ou CPF não existirem na tabela
            v_detalhes := TG_OP || ' em ' || TG_TABLE_NAME || ' (ID: ' || COALESCE(v_id_afetado::TEXT, 'N/A') || ')';
        WHEN OTHERS THEN
            -- Captura outros erros inesperados na extração de detalhes
            v_detalhes := TG_OP || ' em ' || TG_TABLE_NAME || ' (ID: ' || COALESCE(v_id_afetado::TEXT, 'N/A') || ') - Erro ao obter detalhes: ' || SQLERRM;
    END;

    -- Inserir o registro na tabela de auditoria
    INSERT INTO AUDITORIA_LOG (NOME_TABELA, OPERACAO, ID_REGISTRO_AFETADO, DETALHES)
    VALUES (TG_TABLE_NAME, TG_OP, v_id_afetado, v_detalhes);

    -- Para triggers AFTER, sempre retornamos NULL
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;