-- Codigo para funções das tabelas --

---------------------|| FUNÇÕES GERAIS || ---------------------
-------------------------------@------------------------------
--------------------------------------------------------------

----------- Função para cadastrar dados dentro de qualquer tabela -----------
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
-----------------------------------------------------------------------------


----------- Função para deletar todos os dados dentro de qualquer tabela -----------
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
------------------------------------------------------------------------------------


----------------- Função para Atualizar ou Mudar as coisas (Update) ----------------
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
------------------------------------------------------------------------------------


------------------ Função para recontar os ID serial -------------------

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
------------------------------------------------------------------------


---------------- Função para limpar todas as tabelas ----------------
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
---------------------------------------------------------------------

------------ Função para não permitir numeros nos nomes ------------
CREATE OR REPLACE FUNCTION NOMES_NAO_NUMEROS()
RETURNS TRIGGER AS $$
BEGIN
	IF NEW.NOME ~ '.*\d.*' THEN
		RAISE EXCEPTION 'Não é permitido números dentro do nome. Valor fornecido: "%".', NEW.NOME;
	END IF;

    -- Retorna NEW para permitir que a operação de INSERT ou UPDATE continue
	RETURN NEW;
END;
$$
LANGUAGE PLPGSQL;
--------------------------------------------------------------------


--------------------------------------------------------------
--------------------------------------------------------------
--------------------------------------------------------------









--------------------|| FUNÇÕES CLIENTE ||---------------------
------------------------------@-------------------------------
--------------------------------------------------------------
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
--------------------------------------------------------------
--------------------------------------------------------------
--------------------------------------------------------------









-------------------|| FUNÇÕES FUNCIONARIO ||------------------
------------------------------@-------------------------------
--------------------------------------------------------------
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
--------------------------------------------------------------
--------------------------------------------------------------
--------------------------------------------------------------









------------------|| FUNÇÕES TIPO LAVAGEM ||------------------
------------------------------@-------------------------------
--------------------------------------------------------------
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
--------------------------------------------------------------
--------------------------------------------------------------
--------------------------------------------------------------









-------------------|| FUNÇÕES FORNECEDOR ||-------------------
-----------------------------@--------------------------------
--------------------------------------------------------------
CREATE OR REPLACE FUNCTION CHECAR_CNPJ_UNICO_FORNECEDOR()
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
--------------------------------------------------------------
--------------------------------------------------------------
--------------------------------------------------------------









---------------------|| FUNÇÕES PRODUTO ||--------------------
------------------------------@-------------------------------
--------------------------------------------------------------
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

-------- Função para subtrair ao estoque do produto ----------------------
CREATE OR REPLACE FUNCTION trg_fun_subtrair_estoque_produto()
RETURNS TRIGGER AS $$
BEGIN
    -- Subtrai a quantidade utilizada (que deve ser informada na unidade base) do estoque do produto.
    UPDATE produto
    SET qtd_estoque = qtd_estoque - NEW.qtd_utilizada
    WHERE id_produto = NEW.fk_lavagem_produto_produto;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
--------------------------------------------------------------
--------------------------------------------------------------
--------------------------------------------------------------









---------------------|| FUNÇÕES COMPRA ||---------------------
------------------------------@-------------------------------
--------------------------------------------------------------

-------- Função para tornar FK nula ao fornecedor ser deletado --------
CREATE OR REPLACE FUNCTION DELETAR_FORNECEDOR_E_DEIXAR_FK_NULO_COMPRA()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE COMPRA
    SET fk_compra_fornecedor = NULL
    WHERE fk_compra_fornecedor = OLD.ID_FORNECEDOR;

    RETURN OLD;
END;
$$ LANGUAGE plpgsql;
-----------------------------------------------------------------------

-------- Função para limitar palavras usadas no atributo status --------
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
------------------------------------------------------------------------

-------- Função para limitar palavras usadas no atributo status --------
CREATE OR REPLACE FUNCTION checar_preco_positivo_compra()
RETURNS TRIGGER AS $$
BEGIN
    -- Verifica se PRECO_POR_KG é negativo
    IF NEW.VALOR_TOTAL < 0 THEN
        RAISE EXCEPTION 'O valor total não pode ser negativo. Valor fornecido: %.', NEW.VALOR_TOTAL;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
------------------------------------------------------------------------

-------- Função para adicionar ao estoque do produto ----------------------
CREATE OR REPLACE FUNCTION trg_fun_adicionar_estoque_compra()
RETURNS TRIGGER AS $$
DECLARE
    item_da_compra RECORD;
BEGIN
    -- O gatilho só executa se o status da compra MUDOU para 'ENTREGUE'
    IF NEW.status_compra = 'ENTREGUE' AND OLD.status_compra <> 'ENTREGUE' THEN

        -- Percorre cada item da compra que foi entregue
        FOR item_da_compra IN SELECT * FROM item WHERE fk_item_compra = NEW.id_compra LOOP

            -- Adiciona a quantidade do item comprado ao estoque do produto
            UPDATE produto
            SET qtd_estoque = qtd_estoque + (item_da_compra.qtd_item * produto.fator_conversao)
            WHERE id_produto = item_da_compra.fk_item_produto;

        END LOOP;

    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
------------------------------------------------------------------------

--------------------------------------------------------------
--------------------------------------------------------------
--------------------------------------------------------------









----------------------|| FUNÇÕES ITEM ||----------------------
------------------------------@-------------------------------
--------------------------------------------------------------
-- Função para quando deletar COMPRA, setar valor nulo --
CREATE OR REPLACE FUNCTION DELETAR_COMPRA_SETAR_NULO_FK_ITEM()
RETURNS TRIGGER AS $$
BEGIN

    UPDATE ITEM
    SET fk_item_compra = NULL
    WHERE fk_item_compra = OLD.ID_COMPRA;

    RETURN OLD;
END;
$$
LANGUAGE PLPGSQL;

-------------------------------------------------------------------
CREATE OR REPLACE FUNCTION DELETAR_PRODUTO_SETAR_NULO_FK_ITEM()
RETURNS TRIGGER AS $$
BEGIN

    UPDATE ITEM
    SET fk_item_produto = NULL
    WHERE fk_item_produto = OLD.ID_PRODUTO;
    RETURN OLD;
END;
$$
LANGUAGE PLPGSQL;

-------------------------------------------------------------------
CREATE OR REPLACE FUNCTION checar_qtd_positivo_item()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.QTD_ITEM < 0 THEN
        RAISE EXCEPTION 'A quantidade de item não pode ser negativo. Valor fornecido: %.', NEW.QTD_ITEM;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-------------------------------------------------------------------
CREATE OR REPLACE FUNCTION checar_valor_unitario_positivo_item()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.VALOR_UNITARIO < 0 THEN
        RAISE EXCEPTION 'O valor unitário não pode ser negativo. Valor fornecido: %.', NEW.QTD_ITEM;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-------------------------------------------------------------------
CREATE OR REPLACE FUNCTION calcular_valor_total_item()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.QTD_ITEM IS NOT NULL AND NEW.VALOR_UNITARIO IS NOT NULL THEN
        NEW.VALOR_TOTAL = NEW.QTD_ITEM * NEW.VALOR_UNITARIO;
    ELSE
        NEW.VALOR_TOTAL = 0; 
    END IF;

    RETURN NEW;
END;
$$
LANGUAGE PLPGSQL;
--------------------------------------------------------------
--------------------------------------------------------------
--------------------------------------------------------------









---------------------|| FUNÇÕES LAVAGEM ||--------------------
--------------------------------@-----------------------------
--------------------------------------------------------------

----------- Função para garantir consistencia dos dados -----------
CREATE OR REPLACE FUNCTION verificar_consistencia_datas_lavagem()
RETURNS TRIGGER AS $$
BEGIN
    -- Checagem 1: A data de entrega PREVISTA não pode ser anterior à data de ENTRADA.
    IF NEW.dt_prev_entrega IS NOT NULL AND NEW.dt_prev_entrega < NEW.dt_entrada THEN
        RAISE EXCEPTION 'A data de entrega prevista (%) não pode ser anterior à data de entrada (%).',
            to_char(NEW.dt_prev_entrega, 'DD/MM/YYYY'), 
            to_char(NEW.dt_entrada, 'DD/MM/YYYY');
    END IF;

    -- Checagem 2: A data de entrega REAL não pode ser anterior à data de ENTRADA.
    -- (Só checa se a dt_real_entrega não for nula)
    IF NEW.dt_real_entrega IS NOT NULL AND NEW.dt_real_entrega < NEW.dt_entrada THEN
        RAISE EXCEPTION 'A data de entrega real (%) não pode ser anterior à data de entrada (%).',
            to_char(NEW.dt_real_entrega, 'DD/MM/YYYY'),
            to_char(NEW.dt_entrada, 'DD/MM/YYYY');
    END IF;

    -- Se todas as checagens passarem, permite que a operação (INSERT ou UPDATE) continue.
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
-------------------------------------------------------------------

----- Função para realizar cadastra na tabela lavagem -----
CREATE OR REPLACE FUNCTION CADASTRAR_LAVAGEM(
    p_cliente_cpf VARCHAR,
    p_funcionario_cpf VARCHAR,
    p_tipo_lavagem_descricao VARCHAR,
    p_tipo_pagamento_nome VARCHAR,
    p_dt_prev_entrega TIMESTAMP,
    p_observacoes TEXT,
    p_peso_lavagem DECIMAL DEFAULT NULL,
    p_qtd_parcelas INT DEFAULT 1
)
RETURNS INT AS $$
DECLARE
    v_cliente_id INT;
    v_funcionario_id INT;
    v_tipo_lavagem_info RECORD;
    v_tipo_pagamento_id INT;
    v_nova_lavagem_id INT;
    v_valor_total_calculado DECIMAL(10, 2);
    v_valor_por_parcela DECIMAL(10, 2);
    v_max_parcelas_permitidas INT;
    v_valor_primeiras_parcelas DECIMAL(10, 2);
    v_valor_ultima_parcela DECIMAL(10, 2);
    i INT;
BEGIN
	PERFORM ATUALIZAR_STATUS_PARCELAS();

    -- 1. Busca dos IDs
    SELECT id_cliente INTO v_cliente_id FROM cliente WHERE cpf = p_cliente_cpf;
    IF NOT FOUND THEN RAISE EXCEPTION 'Cliente com CPF "%" não encontrado.', p_cliente_cpf; END IF;
    SELECT id_funcionario INTO v_funcionario_id FROM funcionario WHERE cpf = p_funcionario_cpf;
    IF NOT FOUND THEN RAISE EXCEPTION 'Funcionário com CPF "%" não encontrado.', p_funcionario_cpf; END IF;
    SELECT * INTO v_tipo_lavagem_info FROM tipo_lavagem WHERE descricao = p_tipo_lavagem_descricao;
    IF NOT FOUND THEN RAISE EXCEPTION 'Tipo de Lavagem com a descrição "%" não encontrado.', p_tipo_lavagem_descricao; END IF;
    SELECT id_tipo_pagamento INTO v_tipo_pagamento_id FROM tipo_pagamento WHERE nome = p_tipo_pagamento_nome;
    IF NOT FOUND THEN RAISE EXCEPTION 'Tipo de Pagamento com o nome "%" não encontrado.', p_tipo_pagamento_nome; END IF;

    -- 2. Cálculo do Preço Total
    IF v_tipo_lavagem_info.preco_fixo IS NOT NULL THEN
        v_valor_total_calculado := v_tipo_lavagem_info.preco_fixo;
    ELSIF v_tipo_lavagem_info.preco_por_kg IS NOT NULL THEN
        IF p_peso_lavagem IS NULL OR p_peso_lavagem <= 0 THEN RAISE EXCEPTION 'Para lavagens por KG, o peso deve ser informado.'; END IF;
        v_valor_total_calculado := v_tipo_lavagem_info.preco_por_kg * p_peso_lavagem;
    ELSE
        RAISE EXCEPTION 'O tipo de lavagem "%" não possui uma regra de precificação.', p_tipo_lavagem_descricao;
    END IF;

    -- 3. Validação da Parcela Mínima de R$ 10,00
    IF p_qtd_parcelas > 0 THEN
        v_valor_por_parcela := v_valor_total_calculado / p_qtd_parcelas;
        IF v_valor_por_parcela < 10.00 AND p_qtd_parcelas > 1 THEN
            v_max_parcelas_permitidas := floor(v_valor_total_calculado / 10.00);
            RAISE EXCEPTION 'O valor por parcela (R$%) é menor que o mínimo de R$ 10,00. Para este serviço, o máximo permitido é de % parcela(s).', 
                TRUNC(v_valor_por_parcela, 2), v_max_parcelas_permitidas;
        END IF;
    END IF;

    -- 4. Inserção na Tabela LAVAGEM
    INSERT INTO lavagem (fk_lavagem_cliente, fk_lavagem_funcionario, fk_lavagem_tipo, fk_lavagem_pagamento, dt_prev_entrega, status_lavagem, valor_total_lavagem, peso_lavagem, qtd_parcelas, observacoes) 
    VALUES (v_cliente_id, v_funcionario_id, v_tipo_lavagem_info.id_tipo_lavagem, v_tipo_pagamento_id, p_dt_prev_entrega, 'EM ANDAMENTO', v_valor_total_calculado, p_peso_lavagem, p_qtd_parcelas, p_observacoes) 
    RETURNING id_lavagem INTO v_nova_lavagem_id;

    -- 5. Criação das Parcelas
    v_valor_primeiras_parcelas := TRUNC(v_valor_total_calculado / p_qtd_parcelas, 2);
    v_valor_ultima_parcela := v_valor_total_calculado - (v_valor_primeiras_parcelas * (p_qtd_parcelas - 1));
    FOR i IN 1..p_qtd_parcelas LOOP
        INSERT INTO parcela (fk_parcela_lavagem, num_parcela, valor_parcela, dt_vencimento, status_parcela)
        VALUES (v_nova_lavagem_id, i, CASE WHEN i < p_qtd_parcelas THEN v_valor_primeiras_parcelas ELSE v_valor_ultima_parcela END, (p_dt_prev_entrega::DATE + (i-1) * INTERVAL '1 month'), 'PENDENTE');
    END LOOP;

    RAISE NOTICE 'Lavagem de ID % (Valor: R$%) cadastrada e % parcela(s) gerada(s) com sucesso.', v_nova_lavagem_id, v_valor_total_calculado, p_qtd_parcelas;
    RETURN v_nova_lavagem_id;
END;
$$ LANGUAGE PLPGSQL;

--------------------------------------------------------------------------

---------- Função para tornar valores nulos ao serem deletados nas tabelas estrangeiras ----------
CREATE OR REPLACE FUNCTION VALORES_NULOS_AO_DELETAR_ATRIBUTOS_ESTRAGEIROS()
RETURNS TRIGGER AS $$
BEGIN
    -- Verifica qual tabela pai disparou o trigger usando TG_TABLE_NAME
    IF TG_TABLE_NAME = 'cliente' THEN
        -- Se um cliente foi deletado, define fk_lavagem_cliente como NULL
        UPDATE LAVAGEM
        SET fk_lavagem_cliente = NULL
        WHERE fk_lavagem_cliente = OLD.ID_CLIENTE;
    ELSIF TG_TABLE_NAME = 'funcionario' THEN
        -- Se um funcionário foi deletado, define fk_lavagem_funcionario como NULL
        UPDATE LAVAGEM
        SET fk_lavagem_funcionario = NULL
        WHERE fk_lavagem_funcionario = OLD.ID_FUNCIONARIO;
    ELSIF TG_TABLE_NAME = 'tipo_lavagem' THEN
        -- Se um tipo de lavagem foi deletado, define fk_lavagem_tipo como NULL
        UPDATE LAVAGEM
        SET fk_lavagem_tipo = NULL
        WHERE fk_lavagem_tipo = OLD.ID_TIPO_LAVAGEM;
    ELSIF TG_TABLE_NAME = 'tipo_pagamento' THEN
        -- Se um tipo de pagamento foi deletado, define fk_lavagem_pagamento como NULL
        UPDATE LAVAGEM
        SET fk_lavagem_pagamento = NULL
        WHERE fk_lavagem_pagamento = OLD.ID_TIPO_PAGAMENTO;
    END IF;

    -- Para triggers BEFORE DELETE, é necessário retornar OLD para permitir que a
    -- operação de DELETE na tabela pai continue.
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;
--------------------------------------------------------------------------------------------------

------- Função para verificar se os status está dentro do padronizado -------
CREATE OR REPLACE FUNCTION LIMITAR_STATUS_LAVAGEM()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.STATUS_LAVAGEM NOT IN ('EM ANDAMENTO','CONCLUIDA','CANCELADA') THEN
        RAISE EXCEPTION 'O status fornecido está fora dos padrões. Valor fornecido: "%"', NEW.STATUS_LAVAGEM;
    END IF;
											
    RETURN NEW;
END;
$$
LANGUAGE PLPGSQL;
-----------------------------------------------------------------------------

-------- Função para verificar se o tempo de entrega prevista e real é inferior à entrada --------
CREATE OR REPLACE FUNCTION VERIFICAR_DATA_INFERIOR_ENTRADA()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.DT_PREV_ENTREGA IS NOT NULL AND 	NEW.DT_PREV_ENTREGA < NEW.DT_ENTRADA THEN
        RAISE EXCEPTION 'A data de previsão de entrega (%) não pode ser anterior à data de entrada (%).',
                        NEW.DT_PREV_ENTREGA, NEW.DT_ENTRADA;
    END IF;

    IF NEW.DT_REAL_ENTREGA IS NOT NULL AND NEW.DT_REAL_ENTREGA < NEW.DT_ENTRADA THEN
        RAISE EXCEPTION 'A data real de entrega (%) não pode ser anterior à data de entrada (%).',
                        NEW.DT_REAL_ENTREGA, NEW.DT_ENTRADA;
    END IF;

    RETURN NEW;
END;
$$
LANGUAGE PLPGSQL;
--------------------------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION verificar_consistencia_datas_lavagem()
RETURNS TRIGGER AS $$
BEGIN
    -- Checagem 1: A data de entrega PREVISTA não pode ser anterior à data de ENTRADA.
    IF NEW.dt_prev_entrega IS NOT NULL AND NEW.dt_prev_entrega < NEW.dt_entrada THEN
        RAISE EXCEPTION 'A data de entrega prevista (%) não pode ser anterior à data de entrada (%).',
            to_char(NEW.dt_prev_entrega, 'DD/MM/YYYY HH24:MI'), 
            to_char(NEW.dt_entrada, 'DD/MM/YYYY HH24:MI');
    END IF;

    -- Checagem 2: A data de entrega REAL não pode ser anterior à data de ENTRADA.
    IF NEW.dt_real_entrega IS NOT NULL AND NEW.dt_real_entrega < NEW.dt_entrada THEN
        RAISE EXCEPTION 'A data de entrega real (%) não pode ser anterior à data de entrada (%).',
            to_char(NEW.dt_real_entrega, 'DD/MM/YYYY HH24:MI'),
            to_char(NEW.dt_entrada, 'DD/MM/YYYY HH24:MI');
    END IF;

    -- NOVA CHECAGEM 3: Se o status for 'CONCLUIDA', a data de entrega real é obrigatória.
    IF NEW.status_lavagem = 'CONCLUIDA' AND NEW.dt_real_entrega IS NULL THEN
        RAISE EXCEPTION 'Uma lavagem com status "CONCLUIDA" deve ter uma data de entrega real preenchida.';
    END IF;

    -- Se todas as checagens passarem, permite que a operação (INSERT ou UPDATE) continue.
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
--------------------------------------------------------------------------------------

-- Função para informar sobre a elegibilidade e limites de parcelamento de uma lavagem
CREATE OR REPLACE FUNCTION INFORMAR_PARCELAMENTO_LAVAGEM()
RETURNS TRIGGER AS $$
DECLARE
    v_valor_total DECIMAL(10,2);
    v_max_parcelas INT;
BEGIN
    v_valor_total := NEW.VALOR_TOTAL_LAVAGEM;

    IF v_valor_total IS NULL OR v_valor_total <= 0 THEN
        RAISE NOTICE 'Atenção: O valor total da lavagem não é válido para parcelamento.';
    ELSIF v_valor_total <= 50.00 THEN
        RAISE NOTICE 'Atenção: Lavagens com valor de R$ % não são elegíveis para parcelamento (mínimo R$ 50.01).', v_valor_total;
    ELSE
        -- Define as regras de parcelamento
        IF v_valor_total > 500.00 THEN
            v_max_parcelas := 12;
        ELSIF v_valor_total > 200.00 THEN
            v_max_parcelas := 6;
        ELSIF v_valor_total > 100.00 THEN
            v_max_parcelas := 4;
        ELSIF v_valor_total > 50.00 THEN
            v_max_parcelas := 2;
        END IF;

        RAISE NOTICE 'Informação: Lavagem com valor de R$ % é elegível para parcelamento em até % vezes.', v_valor_total, v_max_parcelas;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE PLPGSQL;
------------------------------------------------------------------------------------

-- Função para adicionar um valor extra ao VALOR_TOTAL_LAVAGEM de uma lavagem específica
CREATE OR REPLACE FUNCTION ADICIONAR_VALOR_EXTRA_LAVAGEM(
    P_ID_LAVAGEM INT,
    P_VALOR_TAXA DECIMAL(10,2)
)
RETURNS VOID
AS $$
DECLARE
    v_num_ultima_parcela INT;
BEGIN
    -- 1. Verifica se a lavagem existe
    IF NOT EXISTS (SELECT 1 FROM lavagem WHERE id_lavagem = P_ID_LAVAGEM) THEN
        RAISE EXCEPTION 'Erro: Lavagem com ID % não encontrada.', P_ID_LAVAGEM;
    END IF;

    -- 2. Descobre qual o número da última parcela existente
    SELECT COALESCE(MAX(num_parcela), 0) INTO v_num_ultima_parcela
    FROM parcela
    WHERE fk_parcela_lavagem = P_ID_LAVAGEM;

    -- 3. Insere uma NOVA PARCELA para representar a taxa extra
    INSERT INTO parcela (fk_parcela_lavagem, num_parcela, valor_parcela, dt_vencimento, status_parcela)
    VALUES (
        P_ID_LAVAGEM,
        v_num_ultima_parcela + 1,
        P_VALOR_TAXA,
        CURRENT_DATE, -- Vencimento imediato
        'PENDENTE'
    );

    RAISE NOTICE 'Valor de R$ % adicionado com sucesso à lavagem ID %.', P_VALOR_TAXA, P_ID_LAVAGEM;

END;
$$
LANGUAGE PLPGSQL;

---------------------------------------------------------------------------------------------------

-- Função para remover um valor do VALOR_TOTAL_LAVAGEM de uma lavagem específica
CREATE OR REPLACE FUNCTION REMOVER_VALOR_EXTRA_LAVAGEM(
    P_ID_LAVAGEM INT,
    P_VALOR_DESCONTO DECIMAL(10,2)
)
RETURNS VOID
AS $$
DECLARE
    v_num_ultima_parcela INT;
BEGIN
    -- 1. Verifica se a lavagem existe
    IF NOT EXISTS (SELECT 1 FROM lavagem WHERE id_lavagem = P_ID_LAVAGEM) THEN
        RAISE EXCEPTION 'Erro: Lavagem com ID % não encontrada.', P_ID_LAVAGEM;
    END IF;

    -- 2. Garante que o valor do desconto seja positivo
    IF P_VALOR_DESCONTO <= 0 THEN
        RAISE EXCEPTION 'O valor do desconto deve ser um número positivo.';
    END IF;

    -- 3. Descobre qual o número da última parcela existente
    SELECT COALESCE(MAX(num_parcela), 0) INTO v_num_ultima_parcela
    FROM parcela
    WHERE fk_parcela_lavagem = P_ID_LAVAGEM;

    -- 4. Insere uma NOVA PARCELA com valor NEGATIVO para representar o desconto
    INSERT INTO parcela (fk_parcela_lavagem, num_parcela, valor_parcela, dt_vencimento, status_parcela)
    VALUES (
        P_ID_LAVAGEM,
        v_num_ultima_parcela + 1,
        -P_VALOR_DESCONTO, -- O valor do desconto é inserido como negativo
        CURRENT_DATE,
        'PAGO' -- Um desconto é considerado "pago" no momento em que é concedido
    );

    RAISE NOTICE 'Desconto de R$ % aplicado com sucesso à lavagem ID %.', P_VALOR_DESCONTO, P_ID_LAVAGEM;

END;
$$
LANGUAGE PLPGSQL;
-----------------------------------------------------------------------------------------

-- Função para verificar se o peso da lavagem é positivo
CREATE OR REPLACE FUNCTION VERIFICAR_PESO_LAVAGEM_POSITIVO()
RETURNS TRIGGER AS $$
BEGIN
    -- Verifica se o novo valor de PESO_LAVAGEM é menor que 0
    IF NEW.PESO_LAVAGEM < 0 THEN
        -- Se for negativo, lança uma exceção personalizada
        RAISE EXCEPTION 'Erro: O peso da lavagem não pode ser negativo. Valor fornecido: %', NEW.PESO_LAVAGEM;
    END IF;

    -- Retorna NEW para permitir que a operação de INSERT ou UPDATE continue
    RETURN NEW;
END;
$$
LANGUAGE PLPGSQL;
------------------------------------------------------------

CREATE OR REPLACE FUNCTION fun_sincronizar_dados_lavagem()
RETURNS TRIGGER AS $$
DECLARE
    v_lavagem_id_alvo INT;
BEGIN
    -- Determina qual lavagem precisa ser atualizada.
    -- Se uma parcela foi deletada, usa o ID antigo (OLD).
    -- Se foi inserida ou atualizada, usa o ID novo (NEW).
    IF TG_OP = 'DELETE' THEN
        v_lavagem_id_alvo := OLD.fk_parcela_lavagem;
    ELSE
        v_lavagem_id_alvo := NEW.fk_parcela_lavagem;
    END IF;

    -- Se não houver uma lavagem associada, não faz nada.
    IF v_lavagem_id_alvo IS NULL THEN
        RETURN NULL;
    END IF;

    -- Recalcula a soma e a contagem das parcelas e atualiza a tabela lavagem.
    -- COALESCE(..., 0) garante que o resultado seja 0 se não houver parcelas, evitando nulos.
    UPDATE lavagem
    SET 
        valor_total_lavagem = (SELECT COALESCE(SUM(valor_parcela), 0) FROM parcela WHERE fk_parcela_lavagem = v_lavagem_id_alvo),
        qtd_parcelas = (SELECT COUNT(*) FROM parcela WHERE fk_parcela_lavagem = v_lavagem_id_alvo)
    WHERE 
        id_lavagem = v_lavagem_id_alvo;

    -- Para gatilhos AFTER, o retorno geralmente é NULL.
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;


--------------------------------------------------------------
--------------------------------------------------------------
--------------------------------------------------------------









--------------------|| FUNÇÕES AUDITORIA ||-------------------
-------------------------------@------------------------------
--------------------------------------------------------------
CREATE OR REPLACE FUNCTION trg_auditoria_generica()
RETURNS TRIGGER AS $$
DECLARE
    v_id_afetado INT;
    v_detalhes TEXT := '';
    r RECORD;
    old_jsonb JSONB;
    new_jsonb JSONB;
    v_identificador_registro TEXT;
BEGIN
    -- Obter o ID do registro afetado (lógica mantida)
    DECLARE
        v_pk_column_name_actual TEXT;
    BEGIN
        SELECT kcu.column_name INTO v_pk_column_name_actual
        FROM information_schema.table_constraints AS tc
        JOIN information_schema.key_column_usage AS kcu
            ON tc.constraint_name = kcu.constraint_name AND tc.table_schema = kcu.table_schema
        WHERE tc.table_name = TG_TABLE_NAME
          AND tc.table_schema = TG_TABLE_SCHEMA
          AND tc.constraint_type = 'PRIMARY KEY';

        IF v_pk_column_name_actual IS NOT NULL THEN
            IF TG_OP = 'DELETE' THEN
                EXECUTE 'SELECT ($1).' || quote_ident(v_pk_column_name_actual) INTO v_id_afetado USING OLD;
            ELSE
                EXECUTE 'SELECT ($1).' || quote_ident(v_pk_column_name_actual) INTO v_id_afetado USING NEW;
            END IF;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN v_id_afetado := NULL;
    END;

    -- Construir a mensagem de detalhes
    IF TG_OP = 'INSERT' OR TG_OP = 'DELETE' THEN
        -- Tenta encontrar um campo representativo (nome, descricao, etc.) para o resumo.
        BEGIN
            IF TG_OP = 'INSERT' THEN
                EXECUTE format('SELECT ($1).%I', 'nome') INTO v_identificador_registro USING NEW;
            ELSE -- DELETE
                EXECUTE format('SELECT ($1).%I', 'nome') INTO v_identificador_registro USING OLD;
            END IF;
        EXCEPTION WHEN undefined_column THEN
            BEGIN
                IF TG_OP = 'INSERT' THEN
                    EXECUTE format('SELECT ($1).%I', 'descricao') INTO v_identificador_registro USING NEW;
                ELSE -- DELETE
                    EXECUTE format('SELECT ($1).%I', 'descricao') INTO v_identificador_registro USING OLD;
                END IF;
            EXCEPTION WHEN undefined_column THEN
                v_identificador_registro := 'ID ' || COALESCE(v_id_afetado::TEXT, 'N/A');
            END;
        END;
        
        -- Monta a mensagem concisa para INSERT e DELETE
        IF TG_OP = 'INSERT' THEN
            v_detalhes := format('Novo registro inserido: "%s"', v_identificador_registro);
        ELSE -- DELETE
            v_detalhes := format('Registro deletado: "%s"', v_identificador_registro);
        END IF;

    ELSIF TG_OP = 'UPDATE' THEN
        -- Para UPDATE, mantém a lógica detalhada para detectar apenas o que mudou.
        old_jsonb := to_jsonb(OLD);
        new_jsonb := to_jsonb(NEW);
        
        FOR r IN SELECT * FROM jsonb_each_text(new_jsonb) LOOP
            IF r.value IS DISTINCT FROM (old_jsonb ->> r.key) THEN
                v_detalhes := v_detalhes || 
                    format('Campo "%s" alterado de "%s" para "%s". ', 
                           r.key, 
                           (old_jsonb ->> r.key), 
                           r.value
                    );
            END IF;
        END LOOP;
        
        IF v_detalhes = '' THEN
            v_detalhes := 'UPDATE executado sem alterações de dados.';
        ELSE
            v_detalhes := 'Registro atualizado. Alterações: ' || v_detalhes;
        END IF;
    END IF;

    -- Inserir o registro final na tabela de auditoria
    INSERT INTO auditoria_log (nome_tabela, operacao, id_registro_afetado, detalhes)
    VALUES (TG_TABLE_NAME, TG_OP, v_id_afetado, v_detalhes);

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;
--------------------------------------------------------------
--------------------------------------------------------------
--------------------------------------------------------------









---------------------|| FUNÇÕES PARCELA ||--------------------
-------------------------------@------------------------------
--------------------------------------------------------------

CREATE OR REPLACE FUNCTION ATUALIZAR_STATUS_PARCELAS()
RETURNS VOID AS $$
BEGIN
    -- O comando UPDATE vai alterar a tabela 'parcela'
    UPDATE parcela
    -- Define o novo valor para a coluna 'status_parcela'
    SET status_parcela = 'ATRASADO'
    -- A cláusula WHERE especifica QUAIS parcelas devem ser alteradas
    WHERE 
        dt_vencimento < CURRENT_DATE  -- Condição 1: A data de vencimento já passou
        AND status_parcela = 'PENDENTE'; -- Condição 2: E o status atual ainda é 'PENDENTE'
END;
$$
LANGUAGE PLPGSQL;

-- Função para setar fk_parcela_lavagem como NULL na tabela PARCELA
-- quando um registro correspondente é deletado da tabela LAVAGEM.
CREATE OR REPLACE FUNCTION DELETAR_LAVAGEM_SETAR_NULO_FK_PARCELA()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE PARCELA
    SET fk_parcela_lavagem = NULL
    WHERE fk_parcela_lavagem = OLD.ID_LAVAGEM;

    RETURN OLD;
END;
$$ LANGUAGE plpgsql;
-----------------------------------------------------------------

-- Função para verificar se NUM_PARCELA é um valor positivo.
CREATE OR REPLACE FUNCTION VERIFICAR_NUM_PARCELA_POSITIVO()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.NUM_PARCELA < 0 THEN
        RAISE EXCEPTION 'O número da parcela não pode ser negativo. Valor fornecido: %', NEW.NUM_PARCELA;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
------------------------------------------------------------

-- Função para verificar se VALOR_PARCELA é um valor positivo.
CREATE OR REPLACE FUNCTION VERIFICAR_VALOR_PARCELA_POSITIVO()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.VALOR_PARCELA < 0 THEN
        RAISE EXCEPTION 'O valor da parcela não pode ser negativo. Valor fornecido: %', NEW.VALOR_PARCELA;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
--------------------------------------------------------------

-- Função para verificar se DT_VENCIMENTO não é anterior à data atual.
CREATE OR REPLACE FUNCTION VERIFICAR_DT_VENCIMENTO_FUTURA()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.DT_VENCIMENTO IS NOT NULL AND NEW.DT_VENCIMENTO < CURRENT_DATE THEN
        RAISE EXCEPTION 'Erro: A data de vencimento (%) não pode ser anterior à data atual (%).',
                        NEW.DT_VENCIMENTO, CURRENT_DATE;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
------------------------------------------------------------------------

-- Função para verificar se STATUS_PARCELA está entre os valores permitidos.
CREATE OR REPLACE FUNCTION VERIFICAR_STATUS_PARCELA()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.STATUS_PARCELA NOT IN ('PAGO','PENDENTE','ATRASADO') THEN
        RAISE EXCEPTION 'Erro: O status da parcela está fora dos padrões. Valor fornecido: "%"', NEW.STATUS_PARCELA;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION fun_validar_qtd_parcelas()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.qtd_parcelas < 0 OR NEW.qtd_parcelas > 12 THEN
        RAISE EXCEPTION 'O número de parcelas deve estar entre 0 e 12. Valor fornecido: %', NEW.qtd_parcelas;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE PLPGSQL;


--------------------------------------------------------------
--------------------------------------------------------------
--------------------------------------------------------------
--------------------------------------------------------------









-----------------|| FUNÇÕES LAVAGEM PRODUTO ||----------------
-------------------------------@------------------------------
--------------------------------------------------------------

-- Função para deletar registros em LAVAGEM_PRODUTO quando uma LAVAGEM é deletada --
CREATE OR REPLACE FUNCTION DELETAR_LAVAGEM_CASCADE_LAVAGEM_PRODUTO()
RETURNS TRIGGER AS $$
BEGIN
    DELETE FROM LAVAGEM_PRODUTO
    WHERE fk_lavagem_produto_lavagem = OLD.ID_LAVAGEM;
    RETURN OLD;
END;
$$ LANGUAGE PLPGSQL;
------------------------------------------------------------------------------------

-- Função para deletar registros em LAVAGEM_PRODUTO quando um PRODUTO é deletado --
CREATE OR REPLACE FUNCTION DELETAR_PRODUTO_CASCADE_LAVAGEM_PRODUTO()
RETURNS TRIGGER AS $$
BEGIN
    DELETE FROM LAVAGEM_PRODUTO
    WHERE fk_lavagem_produto_produto = OLD.ID_PRODUTO;
    RETURN OLD;
END;
$$ LANGUAGE PLPGSQL;

----------------------------------------------------------------------------------

-- Função para não permitir valores negativos em QTD_UTILIZADA --
CREATE OR REPLACE FUNCTION VERIFICAR_QTD_UTILIZADA_POSITIVO()
RETURNS TRIGGER AS $$
BEGIN
	IF (NEW.QTD_UTILIZADA < 0) THEN
		RAISE EXCEPTION 'A quantidade fornecida não pode ser negativa. Valor fornecido: %', NEW.QTD_UTILIZADA; -- Adicionado ; aqui
	END IF;

	RETURN NEW;
END;
$$
LANGUAGE PLPGSQL;
-----------------------------------------------------------------

--------------------------------------------------------------
--------------------------------------------------------------
--------------------------------------------------------------
--------------------------------------------------------------
