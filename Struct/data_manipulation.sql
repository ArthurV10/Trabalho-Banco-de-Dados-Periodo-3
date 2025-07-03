
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

SELECT * FROM relatorio_ranking_clientes();

-------------------- CRIAÇÂO DE CENÁRIOS --------------------

-- Cenário 1: Inadimplência para o cliente Diego Alves

-- Primeiro, criamos uma nova lavagem para ele, que já foi concluída.
SELECT CADASTRAR('lavagem', 
    'DEFAULT, 4, 2, 5, 1, ''2025-06-10 14:00:00'', ''2025-06-12 14:00:00'', ''2025-06-12 14:00:00'', ''CONCLUIDA'', ''Serviço concluído, aguardando pagamento.''');

-- Agora, a parcela para a lavagem 11, com data de vencimento no passado.
SELECT CADASTRAR('parcela', 
    'DEFAULT, 11, 1, 25.00, ''2025-06-25'', NULL, ''ATRASADO''');

-- Cenário 2: Inadimplência para a cliente Elisa Martins

-- Criamos a lavagem para ela.
SELECT CADASTRAR('lavagem', 
    'DEFAULT, 5, 3, 2, 4, ''2025-06-15 10:00:00'', ''2025-06-17 10:00:00'', ''2025-06-17 10:00:00'', ''CONCLUIDA'', ''Pagamento via PIX pendente.''');

-- E agora a parcela para a lavagem 12, também vencida.
SELECT CADASTRAR('parcela', 
    'DEFAULT, 12, 1, 55.00, ''2025-06-30'', NULL, ''ATRASADO''');