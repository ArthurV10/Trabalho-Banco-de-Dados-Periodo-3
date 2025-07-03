-- 1.1 Relatório de Faturamento por Período
CREATE OR REPLACE FUNCTION relatorio_faturamento_periodo(
    p_data_inicio DATE,
    p_data_fim DATE
)
-- Define que a saída será uma tabela com duas colunas
RETURNS TABLE (
    forma_pagamento TEXT,
    valor_total_faturado DECIMAL
)
AS $$
BEGIN
    -- Inicia a consulta que vai gerar a tabela de retorno
    RETURN QUERY
    -- 1. SELECIONA os dados finais que queremos ver:
    SELECT 
        tp.nome::TEXT,           -- O nome da forma de pagamento (ex: 'PIX', 'Dinheiro')
        SUM(par.valor_parcela)   -- A SOMA de todos os valores das parcelas encontradas
    
    -- 2. COMEÇA pela tabela 'parcela', que é onde estão os valores e as datas de pagamento.
    FROM parcela AS par
    
    -- 3. JUNTA com a tabela 'lavagem' para saber qual foi o tipo de pagamento usado em cada serviço.
    JOIN lavagem AS lav ON par.fk_parcela_lavagem = lav.id_lavagem
    
    -- 4. JUNTA com a tabela 'tipo_pagamento' para obter o NOME da forma de pagamento.
    JOIN tipo_pagamento AS tp ON lav.fk_lavagem_pagamento = tp.id_tipo_pagamento
    
    -- 5. FILTRA os resultados para atender a duas condições:
    WHERE 
        par.status_parcela = 'PAGO'  -- Apenas parcelas que já foram pagas (faturamento real)
        AND par.dt_pagamento BETWEEN p_data_inicio AND p_data_fim -- Cujo pagamento ocorreu dentro do período informado
        
    -- 6. AGRUPA todas as linhas pela forma de pagamento, para que o SUM() some os valores de cada forma separadamente.
    GROUP BY tp.nome
    
    -- 7. ORDENA o resultado final para mostrar as formas de pagamento mais lucrativas primeiro.
    ORDER BY SUM(par.valor_parcela) DESC;
END;
$$ LANGUAGE plpgsql;


-- 1.2 Relatório de Inadimplência
CREATE OR REPLACE FUNCTION relatorio_inadimplencia()
-- Define que a saída será uma tabela com 6 colunas
RETURNS TABLE (
    nome_cliente TEXT,
    telefone_cliente VARCHAR,
    id_lavagem INT,
    valor_devido DECIMAL,
    data_vencimento DATE,
    dias_em_atraso INT
)
AS $$
BEGIN
	PERFORM ATUALIZAR_STATUS_PARCELAS();

    RETURN QUERY
    -- 1. SELECIONA os dados que queremos ver:
    SELECT 
        c.nome::TEXT,                   -- O nome do cliente
        c.telefone,                     -- O telefone dele
        l.id_lavagem,                   -- O ID da lavagem referente à dívida
        p.valor_parcela,                -- O valor que ele deve
        p.dt_vencimento,                -- A data em que a dívida venceu
        (CURRENT_DATE - p.dt_vencimento)::INT -- Calcula os dias em atraso (data de hoje - data de vencimento)

    -- 2. COMEÇA pela tabela 'parcela', onde estão as informações de vencimento e status.
    FROM parcela AS p

    -- 3. JUNTA com a tabela 'lavagem' para descobrir qual cliente está associado àquela parcela.
    JOIN lavagem AS l ON p.fk_parcela_lavagem = l.id_lavagem

    -- 4. JUNTA com a tabela 'cliente' para pegar o NOME e o TELEFONE do devedor.
    JOIN cliente AS c ON l.fk_lavagem_cliente = c.id_cliente
    
    -- 5. FILTRA os resultados atrasados:
    WHERE 
        p.status_parcela = 'ATRASADO'
    -- 6. ORDENA o resultado para mostrar os clientes com mais dias de atraso primeiro, pois são os casos mais urgentes.
    ORDER BY dias_em_atraso DESC;
END;
$$ LANGUAGE plpgsql;


-- 1.3 Relatório de Rentabilidade por Serviço
CREATE OR REPLACE FUNCTION relatorio_rentabilidade_por_servico(
    p_data_inicio DATE,
    p_data_fim DATE
)
-- Define a saída como uma tabela de 3 colunas
RETURNS TABLE(
    tipo_servico TEXT,
    quantidade_solicitada BIGINT,
    receita_total DECIMAL
)
AS $$
BEGIN
    RETURN QUERY
    -- 1. SELECIONA os dados que queremos analisar:
    SELECT 
        tl.descricao::TEXT,          -- A descrição do serviço (ex: 'Lavagem a Seco (Peça)')
        COUNT(DISTINCT l.id_lavagem), -- A CONTAGEM de quantas vezes esse serviço foi feito
        SUM(p.valor_parcela)         -- A SOMA de todo o dinheiro que esse serviço gerou

    -- 2. COMEÇA pela tabela 'parcela' para ter acesso aos valores pagos.
    FROM parcela AS p
    
    -- 3. JUNTA com a tabela 'lavagem' para saber qual tipo de serviço corresponde a cada parcela.
    JOIN lavagem AS l ON p.fk_parcela_lavagem = l.id_lavagem
    
    -- 4. JUNTA com a tabela 'tipo_lavagem' para obter a DESCRIÇÃO do serviço.
    JOIN tipo_lavagem AS tl ON l.fk_lavagem_tipo = tl.id_tipo_lavagem
    
    -- 5. FILTRA os resultados para considerar apenas o faturamento real no período.
    WHERE 
        p.status_parcela = 'PAGO' -- Apenas parcelas pagas
        AND p.dt_pagamento BETWEEN p_data_inicio AND p_data_fim -- Pagas dentro do período
        
    -- 6. AGRUPA as linhas por tipo de serviço para que o COUNT e o SUM funcionem para cada serviço individualmente.
    GROUP BY tl.descricao
    
    -- 7. ORDENA o resultado para mostrar os serviços que mais geraram receita no topo.
    ORDER BY receita_total DESC;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION relatorio_ranking_clientes(
    p_data_inicio DATE DEFAULT NULL, -- Parâmetro opcional para a data de início
    p_data_fim DATE DEFAULT NULL     -- Parâmetro opcional para a data de fim
)
RETURNS TABLE (
    posicao_ranking BIGINT,
    nome_cliente TEXT,
    total_gasto DECIMAL,
    frequencia_lavagens BIGINT
)
AS $$
BEGIN
    RETURN QUERY
    -- Seleciona os dados e calcula o ranking, total gasto e frequência para cada cliente
    SELECT
        ROW_NUMBER() OVER (ORDER BY SUM(p.valor_parcela) DESC), -- Numera as linhas para criar a posição no ranking
        c.nome::TEXT,                                           -- Pega o nome do cliente
        SUM(p.valor_parcela),                                   -- Soma o valor de todas as parcelas pagas
        COUNT(DISTINCT l.id_lavagem)                            -- Conta o número de serviços distintos
    FROM parcela AS p
    JOIN lavagem AS l ON p.fk_parcela_lavagem = l.id_lavagem
    JOIN cliente AS c ON l.fk_lavagem_cliente = c.id_cliente
    -- Filtra apenas por parcelas pagas e aplica o filtro de data somente se os parâmetros forem fornecidos
    WHERE p.status_parcela = 'PAGO' AND ((p_data_inicio IS NULL AND p_data_fim IS NULL) OR (p.dt_pagamento BETWEEN p_data_inicio AND p_data_fim))
    -- Agrupa os resultados por cliente para que as funções de agregação (SUM, COUNT) funcionem corretamente
    GROUP BY c.id_cliente, c.nome
    -- Ordena o resultado final para mostrar os maiores gastadores primeiro
    ORDER BY total_gasto, frequencia_lavagens DESC;
END;
$$ LANGUAGE PLPGSQL;