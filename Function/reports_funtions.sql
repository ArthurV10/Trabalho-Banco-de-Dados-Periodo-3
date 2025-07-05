----------------------------------------------------------------------
--==================================================================--
--||                                                              ||--
--||         ARQUIVO DE RELATÓRIOS, VIEWS E FUNÇÕES DE APOIO        ||--
--||                                                              ||--
--==================================================================--
--
-- Este arquivo centraliza todas as funções de consulta e as views
-- utilizadas para análise e visualização dos dados da lavanderia.
--
----------------------------------------------------------------------


----------------------------------------------------------------------
-- SEÇÃO 1: FUNÇÕES DE RELATÓRIO
----------------------------------------------------------------------
-- Estas funções aceitam parâmetros para gerar análises específicas
-- sobre o desempenho do negócio.
----------------------------------------------------------------------

-- Relatório 1.1: Faturamento por Período
CREATE OR REPLACE FUNCTION relatorio_faturamento_periodo(p_data_inicio DATE, p_data_fim DATE)
RETURNS TABLE (forma_pagamento TEXT, valor_total_faturado DECIMAL) AS $$
BEGIN
    RETURN QUERY
    SELECT tp.nome::TEXT, SUM(par.valor_parcela)
    FROM parcela AS par
    JOIN lavagem AS lav ON par.fk_parcela_lavagem = lav.id_lavagem
    JOIN tipo_pagamento AS tp ON lav.fk_lavagem_pagamento = tp.id_tipo_pagamento
    WHERE par.status_parcela = 'PAGO' AND par.dt_pagamento BETWEEN p_data_inicio AND p_data_fim
    GROUP BY tp.nome
    ORDER BY SUM(par.valor_parcela) DESC;
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
END;
$$ LANGUAGE plpgsql;


-- Relatório 1.3: Rentabilidade por Serviço
CREATE OR REPLACE FUNCTION relatorio_rentabilidade_por_servico(p_data_inicio DATE, p_data_fim DATE)
RETURNS TABLE(tipo_servico TEXT, quantidade_solicitada BIGINT, receita_total DECIMAL) AS $$
BEGIN
    RETURN QUERY
    SELECT tl.descricao::TEXT, COUNT(DISTINCT l.id_lavagem), SUM(p.valor_parcela)
    FROM parcela AS p
    JOIN lavagem AS l ON p.fk_parcela_lavagem = l.id_lavagem
    JOIN tipo_lavagem AS tl ON l.fk_lavagem_tipo = tl.id_tipo_lavagem
    WHERE p.status_parcela = 'PAGO' AND p.dt_pagamento BETWEEN p_data_inicio AND p_data_fim
    GROUP BY tl.descricao
    ORDER BY receita_total DESC;
END;
$$ LANGUAGE plpgsql;


-- Relatório 1.4: Ranking de Clientes
CREATE OR REPLACE FUNCTION relatorio_ranking_clientes(p_data_inicio DATE DEFAULT NULL, p_data_fim DATE DEFAULT NULL)
RETURNS TABLE (posicao_ranking BIGINT, nome_cliente TEXT, total_gasto DECIMAL, frequencia_lavagens BIGINT) AS $$
BEGIN
    RETURN QUERY
    SELECT ROW_NUMBER() OVER (ORDER BY SUM(p.valor_parcela) DESC), c.nome::TEXT, SUM(p.valor_parcela), COUNT(DISTINCT l.id_lavagem)
    FROM parcela AS p
    JOIN lavagem AS l ON p.fk_parcela_lavagem = l.id_lavagem
    JOIN cliente AS c ON l.fk_lavagem_cliente = c.id_cliente
    WHERE p.status_parcela = 'PAGO' AND ((p_data_inicio IS NULL AND p_data_fim IS NULL) OR (p.dt_pagamento BETWEEN p_data_inicio AND p_data_fim))
    GROUP BY c.id_cliente, c.nome
    ORDER BY total_gasto DESC, frequencia_lavagens DESC;
END;
$$ LANGUAGE PLPGSQL;

----------------------------------------------------------------------
-- SEÇÃO 2: VIEWS (VISÕES)
----------------------------------------------------------------------
-- Estas views funcionam como tabelas virtuais para simplificar
-- consultas do dia a dia.
----------------------------------------------------------------------

-- View 2.1: Painel de Controle de Lavagens (CORRIGIDA)
CREATE OR REPLACE VIEW V_DETALHES_LAVAGENS AS
SELECT
    l.id_lavagem,
    l.fk_lavagem_cliente, -- Adicionado ID do cliente para facilitar filtros
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
