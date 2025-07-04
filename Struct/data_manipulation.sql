
-- Selects para todas tabelas
SELECT * FROM cliente;
SELECT * FROM funcionario;
SELECT * FROM tipo_lavagem;
SELECT * FROM tipo_pagamento;
SELECT * FROM fornecedor;
SELECT * FROM produto;
SELECT * FROM compra;
SELECT * FROM item;
SELECT * FROM lavagem;
SELECT * FROM parcela;
SELECT * FROM lavagem_produto;
SELECT * FROM auditoria_log;

-- Para gerar o relatório de faturamento por método em um determinado periodo:
SELECT * FROM relatorio_faturamento_periodo('2025-07-01', '2025-07-31');

-- Para gerar o relatório de todos os clientes com pagamentos vencidos até hoje:
SELECT * FROM relatorio_inadimplencia();

-- Para ver a rentabilidade de todos os serviços no mês de Julho de 2025:
SELECT * FROM relatorio_rentabilidade_por_servico('2025-07-01', '2025-07-31');

-- Para analisar a performance no segundo trimestre de 2025:
SELECT * FROM relatorio_rentabilidade_por_servico('2025-04-01', '2025-06-30');

-- Para ver a rentabilidade de apenas um dia específico (ex: 08 de Julho de 2025):
SELECT * FROM relatorio_rentabilidade_por_servico('2025-07-08', '2025-07-08');

-- Para ver o ranking de clientes do mês de Julho de 2025:
SELECT * FROM relatorio_ranking_clientes('2025-07-01', '2025-07-31');
SELECT * FROM relatorio_ranking_clientes(); --- Ranking geral

-- Para ver o consumo de produtos no mês de Junho de 2025
SELECT * FROM relatorio_consumo_produtos('2025-06-01', '2025-06-30');
SELECT * FROM relatorio_consumo_produtos(); -- Consumo geral de todos os produtos desde o início


-- Para ver a eficiência operacional GERAL de todos os tempos
SELECT * FROM relatorio_eficiencia_entrega();
SELECT * FROM relatorio_eficiencia_entrega('2025-06-01', '2025-06-30');

-------------------- CRIAÇÃO DE CENÁRIOS DE TESTE ------------------------

-- Cenário 1: Inadimplência para o cliente "Diego Alves" (ID 4)
-- Propósito: Popular o relatorio_inadimplencia.
-- Primeiro, criamos a lavagem 11.
SELECT CADASTRAR('lavagem', 
    'DEFAULT, 4, 2, 5, 1, ''2025-06-10 14:00:00'', ''2025-06-12 14:00:00'', ''2025-06-12 14:00:00'', ''CONCLUIDA'', ''Serviço concluído, aguardando pagamento.''');
-- Agora, a parcela vencida em Junho para a lavagem 11.
SELECT CADASTRAR('parcela', 
    'DEFAULT, 11, 1, 25.00, ''2025-06-25'', NULL, ''ATRASADO''');

	
-- Cenário 2: Inadimplência para a cliente "Elisa Martins" (ID 5)
-- Propósito: Adicionar mais dados ao relatorio_inadimplencia.
-- Criamos a lavagem 12.
SELECT CADASTRAR('lavagem', 
    'DEFAULT, 5, 3, 2, 4, ''2025-06-15 10:00:00'', ''2025-06-17 10:00:00'', ''2025-06-17 10:00:00'', ''CONCLUIDA'', ''Pagamento via PIX pendente.''');
-- E a parcela vencida em Junho para a lavagem 12.
SELECT CADASTRAR('parcela', 
    'DEFAULT, 12, 1, 55.00, ''2025-06-30'', NULL, ''ATRASADO''');


-- Cenário 3: Faturamento e Consumo em Julho com "Ana Pereira" (ID 1)
-- Propósito: Popular os relatórios de faturamento, rentabilidade, ranking e consumo de produtos.
-- Criamos a lavagem 13.
SELECT CADASTRAR('lavagem',
    'DEFAULT, 1, 1, 4, 4, ''2025-07-01 09:00:00'', ''2025-07-02 18:00:00'', ''2025-07-02 17:30:00'', ''CONCLUIDA'', ''Lavagem de edredom, pago via PIX.''');
-- Parcela PAGA em Julho para a lavagem 13.
SELECT CADASTRAR('parcela',
    'DEFAULT, 13, 1, 45.00, ''2025-07-01'', ''2025-07-01'', ''PAGO''');
-- Consumo de produtos para a lavagem 13.
SELECT CADASTRAR('lavagem_produto', '13, 1, 0.08'); -- Sabão Líquido
SELECT CADASTRAR('lavagem_produto', '13, 2, 0.05'); -- Amaciante


-- Cenário 4: Mais faturamento em Julho e fortalecendo o ranking de clientes
-- Propósito: Deixar os relatórios mais ricos, com mais de um cliente e serviço no período.
-- Criamos a lavagem 14 para "Bruno Costa" (ID 2).
SELECT CADASTRAR('lavagem',
    'DEFAULT, 2, 4, 1, 2, ''2025-07-02 11:00:00'', ''2025-07-03 11:00:00'', ''2025-07-03 10:00:00'', ''CONCLUIDA'', ''Lavagem convencional, pago no débito.''');
-- Parcela PAGA em Julho para a lavagem 14.
SELECT CADASTRAR('parcela',
    'DEFAULT, 14, 1, 22.50, ''2025-07-02'', ''2025-07-02'', ''PAGO''');
-- Consumo de produto para a lavagem 14.
SELECT CADASTRAR('lavagem_produto', '14, 1, 0.06'); -- Sabão Líquido


-- Cenário 5: "Ana Pereira" (ID 1) se torna cliente fiel, usando o serviço novamente em Julho.
-- Propósito: Solidificar "Ana Pereira" como a primeira no ranking de clientes.
-- Criamos a lavagem 15, o segundo serviço dela no mês.
SELECT CADASTRAR('lavagem',
    'DEFAULT, 1, 5, 2, 4, ''2025-07-03 15:00:00'', ''2025-07-05 15:00:00'', NULL, ''EM ANDAMENTO'', ''Lavagem a seco de um terno.''');
-- Parcela PAGA na entrada para a lavagem 15.
SELECT CADASTRAR('parcela',
    'DEFAULT, 15, 1, 55.00, ''2025-07-03'', ''2025-07-03'', ''PAGO''');
-- Consumo de produto para a lavagem 15.
SELECT CADASTRAR('lavagem_produto', '15, 3, 0.02'); -- Alvejante Oxy