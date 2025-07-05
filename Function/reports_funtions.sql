----------------------------------------------------------------------
-- FUNÇÕES DE RELATÓRIO
----------------------------------------------------------------------

-- Relatório 1.1: Faturamento por Período
CREATE OR REPLACE FUNCTION relatorio_faturamento_periodo(p_data_inicio DATE, p_data_fim DATE)
RETURNS TABLE (forma_pagamento TEXT, valor_total_faturado DECIMAL) AS $$
BEGIN
    -- Validação dos parâmetros de entrada
    IF p_data_inicio IS NULL OR p_data_fim IS NULL THEN
        RAISE EXCEPTION 'As datas de início e fim devem ser fornecidas.';
    END IF;
    IF p_data_inicio > p_data_fim THEN
        RAISE EXCEPTION 'A data de início não pode ser posterior à data de fim.';
    END IF;

    RETURN QUERY
    SELECT tp.nome::TEXT, SUM(par.valor_parcela)
    FROM parcela AS par
    JOIN lavagem AS lav ON par.fk_parcela_lavagem = lav.id_lavagem
    JOIN tipo_pagamento AS tp ON lav.fk_lavagem_pagamento = tp.id_tipo_pagamento
    WHERE par.status_parcela = 'PAGO' AND par.dt_pagamento BETWEEN p_data_inicio AND p_data_fim
    GROUP BY tp.nome
    ORDER BY SUM(par.valor_parcela) DESC;
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Ocorreu um erro inesperado ao gerar o relatório de faturamento. Por favor, contate o suporte.';
END;
$$ LANGUAGE plpgsql;


-- Relatório 1.2: Inadimplência (Contas Atrasadas)
CREATE OR REPLACE FUNCTION relatorio_inadimplencia()
RETURNS TABLE (nome_cliente TEXT, telefone_cliente VARCHAR, id_lavagem INT, numero_parcela INT, valor_devido DECIMAL, data_vencimento DATE, dias_em_atraso INT) AS $$
BEGIN
    PERFORM ATUALIZAR_STATUS_PARCELAS();
    
    RETURN QUERY
    SELECT c.nome::TEXT, c.telefone, l.id_lavagem, p.num_parcela, p.valor_parcela, p.dt_vencimento, (CURRENT_DATE - p.dt_vencimento)::INT AS dias_em_atraso
    FROM parcela AS p
    JOIN lavagem AS l ON p.fk_parcela_lavagem = l.id_lavagem
    JOIN cliente AS c ON l.fk_lavagem_cliente = c.id_cliente
    WHERE p.status_parcela = 'ATRASADO'
    ORDER BY dias_em_atraso DESC;
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Ocorreu um erro inesperado ao gerar o relatório de inadimplência. Por favor, contate o suporte.';
END;
$$ LANGUAGE plpgsql;


-- Relatório 1.3: Rentabilidade por Serviço
CREATE OR REPLACE FUNCTION relatorio_rentabilidade_por_servico(p_data_inicio DATE, p_data_fim DATE)
RETURNS TABLE(tipo_servico TEXT, quantidade_solicitada BIGINT, receita_total DECIMAL) AS $$
BEGIN
    IF p_data_inicio IS NULL OR p_data_fim IS NULL THEN
        RAISE EXCEPTION 'As datas de início e fim devem ser fornecidas.';
    END IF;
    IF p_data_inicio > p_data_fim THEN
        RAISE EXCEPTION 'A data de início não pode ser posterior à data de fim.';
    END IF;

    RETURN QUERY
    SELECT tl.descricao::TEXT, COUNT(DISTINCT l.id_lavagem), SUM(p.valor_parcela)
    FROM parcela AS p
    JOIN lavagem AS l ON p.fk_parcela_lavagem = l.id_lavagem
    JOIN tipo_lavagem AS tl ON l.fk_lavagem_tipo = tl.id_tipo_lavagem
    WHERE p.status_parcela = 'PAGO' AND p.dt_pagamento BETWEEN p_data_inicio AND p_data_fim
    GROUP BY tl.descricao
    ORDER BY receita_total DESC;
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Ocorreu um erro inesperado ao gerar o relatório de rentabilidade. Por favor, contate o suporte.';
END;
$$ LANGUAGE plpgsql;


-- Relatório 1.4: Ranking de Clientes
CREATE OR REPLACE FUNCTION relatorio_ranking_clientes(p_data_inicio DATE DEFAULT NULL, p_data_fim DATE DEFAULT NULL)
RETURNS TABLE (posicao_ranking BIGINT, nome_cliente TEXT, total_gasto DECIMAL, frequencia_lavagens BIGINT) AS $$
BEGIN
    IF p_data_inicio IS NOT NULL AND p_data_fim IS NOT NULL AND p_data_inicio > p_data_fim THEN
        RAISE EXCEPTION 'A data de início não pode ser posterior à data de fim.';
    END IF;

    RETURN QUERY
    SELECT ROW_NUMBER() OVER (ORDER BY SUM(p.valor_parcela) DESC), c.nome::TEXT, SUM(p.valor_parcela), COUNT(DISTINCT l.id_lavagem)
    FROM parcela AS p
    JOIN lavagem AS l ON p.fk_parcela_lavagem = l.id_lavagem
    JOIN cliente AS c ON l.fk_lavagem_cliente = c.id_cliente
    WHERE p.status_parcela = 'PAGO' AND ((p_data_inicio IS NULL AND p_data_fim IS NULL) OR (p.dt_pagamento BETWEEN p_data_inicio AND p_data_fim))
    GROUP BY c.id_cliente, c.nome
    ORDER BY total_gasto DESC, frequencia_lavagens DESC;
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Ocorreu um erro inesperado ao gerar o ranking de clientes. Por favor, contate o suporte.';
END;
$$ LANGUAGE PLPGSQL;


-- Relatório 1.5: Consumo de Produtos
CREATE OR REPLACE FUNCTION relatorio_consumo_produtos(p_data_inicio DATE DEFAULT NULL, p_data_fim DATE DEFAULT NULL)
RETURNS TABLE (nome_produto TEXT, unidade_medida VARCHAR, quantidade_total_utilizada DECIMAL) AS $$
BEGIN
    IF p_data_inicio IS NOT NULL AND p_data_fim IS NOT NULL AND p_data_inicio > p_data_fim THEN
        RAISE EXCEPTION 'A data de início não pode ser posterior à data de fim.';
    END IF;

    RETURN QUERY
    SELECT p.nome::TEXT, p.unidade_medida, SUM(lp.qtd_utilizada) AS quantidade_total_utilizada
    FROM lavagem_produto AS lp
    JOIN produto AS p ON lp.fk_lavagem_produto_produto = p.id_produto
    JOIN lavagem AS l ON lp.fk_lavagem_produto_lavagem = l.id_lavagem
    WHERE (p_data_inicio IS NULL AND p_data_fim IS NULL) OR (l.dt_entrada::DATE BETWEEN p_data_inicio AND p_data_fim)
    GROUP BY p.id_produto, p.nome, p.unidade_medida
    ORDER BY quantidade_total_utilizada DESC;
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Ocorreu um erro inesperado ao gerar o relatório de consumo. Por favor, contate o suporte.';
END;
$$ LANGUAGE PLPGSQL;


-- Relatório 1.6: Eficiência de Entrega
CREATE OR REPLACE FUNCTION relatorio_eficiencia_entrega(p_data_inicio DATE DEFAULT NULL, p_data_fim DATE DEFAULT NULL)
RETURNS TABLE (tipo_servico TEXT, total_concluido BIGINT, percentual_no_prazo NUMERIC, tempo_medio_prometido_horas NUMERIC, tempo_medio_real_entrega_horas NUMERIC) AS $$
BEGIN
    IF p_data_inicio IS NOT NULL AND p_data_fim IS NOT NULL AND p_data_inicio > p_data_fim THEN
        RAISE EXCEPTION 'A data de início não pode ser posterior à data de fim.';
    END IF;

    RETURN QUERY
    SELECT tl.descricao::TEXT, COUNT(l.id_lavagem), TRUNC((COUNT(*) FILTER (WHERE l.dt_real_entrega <= l.dt_prev_entrega) * 100.0 / COUNT(l.id_lavagem)), 2), TRUNC(AVG(EXTRACT(EPOCH FROM (l.dt_prev_entrega - l.dt_entrada))) / 3600, 2), TRUNC(AVG(EXTRACT(EPOCH FROM (l.dt_real_entrega - l.dt_entrada))) / 3600, 2)
    FROM lavagem AS l
    JOIN tipo_lavagem AS tl ON l.fk_lavagem_tipo = tl.id_tipo_lavagem
    WHERE l.status_lavagem = 'CONCLUIDA' AND l.dt_entrada IS NOT NULL AND l.dt_prev_entrega IS NOT NULL AND l.dt_real_entrega IS NOT NULL AND l.dt_real_entrega >= l.dt_entrada AND l.dt_prev_entrega >= l.dt_entrada AND ((p_data_inicio IS NULL AND p_data_fim IS NULL) OR (l.dt_real_entrega::DATE BETWEEN p_data_inicio AND p_data_fim))
    GROUP BY tl.descricao;
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Ocorreu um erro inesperado ao gerar o relatório de eficiência. Por favor, contate o suporte.';
END;
$$ LANGUAGE PLPGSQL;


-- Relatório 1.7: Desempenho por Funcionário
CREATE OR REPLACE FUNCTION relatorio_desempenho_funcionario(p_data_inicio DATE DEFAULT NULL, p_data_fim DATE DEFAULT NULL)
RETURNS TABLE (nome_funcionario TEXT, cargo VARCHAR, lavagens_realizadas BIGINT) AS $$
BEGIN
    IF p_data_inicio IS NOT NULL AND p_data_fim IS NOT NULL AND p_data_inicio > p_data_fim THEN
        RAISE EXCEPTION 'A data de início não pode ser posterior à data de fim.';
    END IF;

    RETURN QUERY
    SELECT f.nome::TEXT, f.cargo, COUNT(l.id_lavagem) AS lavagens_realizadas
    FROM lavagem AS l
    JOIN funcionario AS f ON l.fk_lavagem_funcionario = f.id_funcionario
    WHERE (p_data_inicio IS NULL AND p_data_fim IS NULL) OR (l.dt_entrada::DATE BETWEEN p_data_inicio AND p_data_fim)
    GROUP BY f.id_funcionario, f.nome, f.cargo
    ORDER BY lavagens_realizadas DESC;
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Ocorreu um erro inesperado ao gerar o relatório de desempenho. Por favor, contate o suporte.';
END;
$$ LANGUAGE PLPGSQL;


-- Relatório 1.8: Alerta de Estoque Baixo
CREATE OR REPLACE FUNCTION relatorio_alerta_estoque(p_limite_minimo NUMERIC)
RETURNS TABLE (nome_produto TEXT, estoque_atual NUMERIC, unidade_medida VARCHAR) AS $$
BEGIN
    IF p_limite_minimo IS NULL OR p_limite_minimo < 0 THEN
        RAISE EXCEPTION 'O limite mínimo para o estoque deve ser um número positivo.';
    END IF;

    RETURN QUERY
    SELECT p.nome::TEXT, TRUNC((p.qtd_estoque / p.fator_conversao), 2), p.unidade_medida
    FROM produto AS p
    WHERE (p.qtd_estoque / p.fator_conversao) <= p_limite_minimo
    ORDER BY p.nome;
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Ocorreu um erro inesperado ao gerar o alerta de estoque. Por favor, contate o suporte.';
END;
$$ LANGUAGE PLPGSQL;


-- Relatório 1.9: Clientes Inativos
CREATE OR REPLACE FUNCTION relatorio_clientes_inativos(p_dias_inativo INT)
RETURNS TABLE (nome_cliente TEXT, telefone VARCHAR, ultimo_servico DATE, dias_sem_servico INT) AS $$
BEGIN
    IF p_dias_inativo IS NULL OR p_dias_inativo < 0 THEN
        RAISE EXCEPTION 'O número de dias de inatividade deve ser um número positivo.';
    END IF;

    RETURN QUERY
    WITH UltimosServicos AS (
        SELECT fk_lavagem_cliente, MAX(dt_entrada::DATE) as data_ultimo_servico
        FROM lavagem
        GROUP BY fk_lavagem_cliente
    )
    SELECT c.nome::TEXT, c.telefone, us.data_ultimo_servico, (CURRENT_DATE - us.data_ultimo_servico) AS dias_sem_servico
    FROM cliente AS c
    JOIN UltimosServicos us ON c.id_cliente = us.fk_lavagem_cliente
    WHERE (CURRENT_DATE - us.data_ultimo_servico) >= p_dias_inativo
    ORDER BY dias_sem_servico DESC;
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Ocorreu um erro inesperado ao gerar o relatório de clientes inativos. Por favor, contate o suporte.';
END;
$$ LANGUAGE PLPGSQL;


-- Relatório 1.10: Histórico de Lavagens por Cliente (CORRIGIDO)
CREATE OR REPLACE FUNCTION relatorio_historico_cliente(p_cliente_cpf VARCHAR)
RETURNS TABLE (id_lavagem INT, data_servico DATE, tipo_servico TEXT, valor_total NUMERIC, status_lavagem VARCHAR) AS $$
DECLARE
    v_cliente_id INT;
BEGIN
    IF p_cliente_cpf IS NULL OR p_cliente_cpf = '' THEN
        RAISE EXCEPTION 'O CPF do cliente deve ser fornecido.';
    END IF;

    SELECT id_cliente INTO v_cliente_id FROM cliente WHERE cpf = p_cliente_cpf;
    IF NOT FOUND THEN
        RAISE NOTICE 'Nenhum cliente encontrado com o CPF: %', p_cliente_cpf;
        RETURN;
    END IF;

    -- A consulta à view é a fonte dos dados.
    RETURN QUERY
    SELECT
        v.id_lavagem,
        v.dt_entrada::DATE,
        v.tipo_servico::TEXT, -- Cast explícito para garantir a correspondência
        v.valor_total_lavagem,
        v.status_lavagem
    FROM V_DETALHES_LAVAGENS AS v
    WHERE v.fk_lavagem_cliente = v_cliente_id
    ORDER BY v.dt_entrada DESC;
EXCEPTION
    -- O bloco de exceção captura qualquer erro e retorna uma mensagem genérica.
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Ocorreu um erro inesperado ao gerar o histórico do cliente. Por favor, contate o suporte.';
END;
$$ LANGUAGE PLPGSQL;

----------------------------------------------------------------------
-- SEÇÃO 2: VIEWS (VISÕES)
----------------------------------------------------------------------
-- Estas views funcionam como tabelas virtuais para simplificar
-- relatorios do dia a dia.
----------------------------------------------------------------------

-- View 2.1: Painel de Controle de Lavagens
CREATE OR REPLACE VIEW V_DETALHES_LAVAGENS AS
SELECT
    l.id_lavagem,
    l.fk_lavagem_cliente,
    l.status_lavagem,
    (SELECT SUM(p.valor_parcela) FROM parcela p WHERE p.fk_parcela_lavagem = l.id_lavagem) AS valor_total_lavagem,
    l.dt_entrada,
    l.dt_prev_entrega,
    l.dt_real_entrega,
    c.nome AS nome_cliente,
    f.nome AS nome_funcionario,
    tl.descricao AS tipo_servico,
    l.observacoes
FROM 
    lavagem AS l
LEFT JOIN cliente AS c ON l.fk_lavagem_cliente = c.id_cliente
LEFT JOIN funcionario AS f ON l.fk_lavagem_funcionario = f.id_funcionario
LEFT JOIN tipo_lavagem AS tl ON l.fk_lavagem_tipo = tl.id_tipo_lavagem;


-- View 2.2: Estoque Atual de Forma Legível
CREATE OR REPLACE VIEW V_ESTOQUE_ATUAL AS
SELECT
    id_produto,
    nome,
    TRUNC((qtd_estoque / fator_conversao), 2) AS quantidade_em_estoque,
    unidade_medida
FROM
    produto
ORDER BY
    nome;