-- Codigo para funções das tabelas --

-- Função para cadastrar dados dentro de qualquer tabela --
CREATE OR REPLACE FUNCTION CADASTRAR(
	P_NOME_TABELA TEXT,
	P_VALORES_PARA_INSERIR TEXT
)
RETURNS VOID
AS $$
DECLARE
    -- Variáveis para capturar os detalhes do erro original
    v_original_error_message TEXT;
    v_original_sqlstate TEXT;
BEGIN
	-- Tenta executar a inserção.
	-- Se um erro ocorrer aqui, ele será capturado pelo bloco EXCEPTION abaixo.
	EXECUTE 'INSERT INTO ' || quote_ident(P_NOME_TABELA) || ' VALUES (' || P_VALORES_PARA_INSERIR || ')';

	-- Esta notificação só será exibida se a inserção for bem-sucedida.
	RAISE NOTICE 'Dados inseridos corretamente na tabela %' , P_NOME_TABELA;

EXCEPTION
	-- Captura qualquer tipo de erro que ocorra durante o EXECUTE.
	WHEN OTHERS THEN
        -- GET STACKED DIAGNOSTICS é usado para obter informações detalhadas
        -- sobre o erro que acabou de ocorrer, incluindo a mensagem original e o SQLSTATE.
        GET STACKED DIAGNOSTICS
            v_original_error_message = MESSAGE_TEXT, -- A mensagem de erro original (ex: do trigger de CPF)
            v_original_sqlstate = RETURNED_SQLSTATE; -- O código SQLSTATE do erro original (ex: 'P0001' para RAISE EXCEPTION)

        -- Verifica se o erro é especificamente aquele levantado por um RAISE EXCEPTION (SQLSTATE 'P0001'),
        -- como o erro de CPF duplicado do seu trigger.
        IF v_original_sqlstate = 'P0001' THEN
            -- Se for o erro de CPF duplicado, combinamos a mensagem original do trigger
            -- com a sua mensagem genérica da função CADASTRAR.
            RAISE EXCEPTION 'Erro ao inserir dados na tabela "%". % Por favor, verifique os dados fornecidos.',
                            P_NOME_TABELA, v_original_error_message;
        ELSE
            -- Para qualquer outro tipo de erro (ex: violação de NOT NULL, tipo de dado incorreto,
            -- coluna inexistente, etc.), usamos apenas a mensagem genérica.
            RAISE EXCEPTION 'Erro ao inserir dados na tabela "%". Por favor, verifique os dados fornecidos ou a estrutura da tabela.',
                            P_NOME_TABELA;
        END IF;
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

CREATE OR REPLACE FUNCTION CHECAR_CPF_UNICO_CLIENTE()
RETURNS TRIGGER AS $$
BEGIN
    -- Verifica se o CPF que está sendo inserido/atualizado já existe na tabela CLIENTE
    -- Exclui o próprio registro em caso de UPDATE para evitar falsos positivos
    IF EXISTS (
        SELECT 1
        FROM CLIENTE
        WHERE CPF = NEW.CPF
          AND ID_CLIENTE IS DISTINCT FROM NEW.ID_CLIENTE -- Garante que não é o mesmo registro em caso de UPDATE
    ) THEN
        -- Se o CPF já existe, lança uma exceção e impede a operação
        RAISE EXCEPTION 'Já existe um cliente cadastrado com o CPF %.', NEW.CPF;
    END IF;

    -- Retorna NEW para permitir que a operação de INSERT ou UPDATE continue
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION CHECAR_CPF_UNICO_FUNCIONARIO()
RETURNS TRIGGER AS $$
BEGIN
    -- Verifica se o CPF que está sendo inserido/atualizado já existe na tabela FUNCIONARIO
    -- Exclui o próprio registro em caso de UPDATE para evitar falsos positivos
    IF EXISTS (
        SELECT 1
        FROM FUNCIONARIO
        WHERE CPF = NEW.CPF
          AND ID_FUNCIONARIO IS DISTINCT FROM NEW.ID_FUNCIONARIO -- Garante que não é o mesmo registro em caso de UPDATE
    ) THEN
        -- Se o CPF já existe, lança uma exceção e impede a operação
        RAISE EXCEPTION 'Erro: Já existe um funcionário cadastrado com o CPF %.', NEW.CPF;
    END IF;

    -- Retorna NEW para permitir que a operação de INSERT ou UPDATE continue
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION CHECAR_CPF_UNICO_FORNECEDOR()
RETURNS TRIGGER AS $$
BEGIN
    -- Verifica se o CNPJ que está sendo inserido/atualizado já existe na tabela FORNECEDOR
    -- Exclui o próprio registro em caso de UPDATE para evitar falsos positivos
    IF EXISTS (
        SELECT 1
        FROM FORNECEDOR
        WHERE CNPJ = NEW.CNPJ
          AND ID_FORNECEDOR IS DISTINCT FROM NEW.ID_FORNECEDOR -- Garante que não é o mesmo registro em caso de UPDATE
    ) THEN
        -- Se o CNPJ já existe, lança uma exceção e impede a operação
        RAISE EXCEPTION 'Erro: Já existe um fornecedor cadastrado com o CNPJ %.', NEW.CNPJ;
    END IF;

    -- Retorna NEW para permitir que a operação de INSERT ou UPDATE continue
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION checar_preco_positivo_tipo_lavagem()
RETURNS TRIGGER AS $$
BEGIN
    -- Verifica se PRECO_POR_KG é negativo
    IF NEW.PRECO_POR_KG < 0 THEN
        RAISE EXCEPTION 'O preço por KG não pode ser negativo. Valor fornecido: %.', NEW.PRECO_POR_KG;
    END IF;

    -- Verifica se PRECO_FIXO é negativo
    IF NEW.PRECO_FIXO < 0 THEN
        RAISE EXCEPTION 'O preço fixo não pode ser negativo. Valor fornecido: %.', NEW.PRECO_FIXO;
    END IF;

    -- Retorna NEW para permitir que a operação de INSERT ou UPDATE continue
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION verificar_qtd_estoque_positiva_produto()
RETURNS TRIGGER AS $$
BEGIN
    -- Verifica se a quantidade em estoque que está sendo inserida/atualizada é negativa
    IF NEW.QTD_ESTOQUE < 0 THEN
        -- Se for negativa, lança uma exceção e impede a operação
        RAISE EXCEPTION 'A quantidade em estoque não pode ser negativa. Valor fornecido: %.', NEW.QTD_ESTOQUE;
    END IF;

    -- Retorna NEW para permitir que a operação de INSERT ou UPDATE continue
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION DELETAR_FORNECEDOR_E_DEIXAR_FK_NULO_COMPRA()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE COMPRA
    SET fk_compra_fornecedor = NULL
    WHERE fk_compra_fornecedor = OLD.ID_FORNECEDOR;

    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION LIMITAR_VALORES_STATUS_COMPRA()
RETURNS TRIGGER AS $$
BEGIN
	IF NEW.STATUS_COMPRA NOT IN ('PENDENTE','ENTREGUE','CANCELADA') THEN
		RAISE EXCEPTION 'A definição de Status da compra está diferente do padronizado. Valor fornecido: "%"', NEW.STATUS_COMPRA;
	END IF;

    RETURN NEW;
END;
$$
LANGUAGE PLPGSQL;