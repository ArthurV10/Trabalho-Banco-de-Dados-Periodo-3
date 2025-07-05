----------------------------------------------------------------------
-- SEÇÃO 1: COMANDOS DE CONSULTA E LIMPEZA
----------------------------------------------------------------------

-- Selects para visualizar todas as tabelas
SELECT * FROM cliente;
SELECT * FROM tipo_lavagem;
SELECT * FROM tipo_pagamento;
SELECT * FROM fornecedor;
SELECT * FROM funcionario;
SELECT * FROM produto;
SELECT * FROM compra;
SELECT * FROM item;
SELECT * FROM lavagem;
SELECT * FROM parcela;
SELECT * FROM lavagem_produto;
SELECT * FROM auditoria_log;

----------------------------------------------------------------------
-- SEÇÃO 2: CRIAÇÃO DE CENÁRIOS DE TESTE ADICIONAIS
----------------------------------------------------------------------

SELECT ATUALIZAR_STATUS_PARCELAS();


-- Cenário 2: Faturamento Extra e Desempenho de Funcionário
-- Propósito: Adicionar mais dados de faturamento e de trabalho para os funcionários.
-- O funcionário 'Lucas Santos' realiza um serviço de alto valor.
SELECT CADASTRAR_LAVAGEM(
    p_cliente_cpf            => '111.111.111-11', -- Ana Pereira
    p_funcionario_cpf        => '001.122.333-44', -- Lucas Santos
    p_tipo_lavagem_descricao => 'Higienização de Sofá (Unidade)',
    p_tipo_pagamento_nome    => 'Cartão de Crédito',
    p_dt_prev_entrega        => '2025-08-20 18:00:00',
    p_observacoes            => 'Limpeza completa do sofá de 3 lugares.',
    p_qtd_parcelas           => 3  -- Parcelado em 3x
);
-- Registrando o pagamento de todas as parcelas para contar como faturamento
-- (Supondo que a lavagem acima é a de ID 12)
SELECT REGISTRAR_PAGAMENTO_PARCELA(id_parcela) FROM parcela WHERE fk_parcela_lavagem = 12;


-- Cenário 3: Eficiência de Entrega
-- Propósito: Gerar dados para o 'relatorio_eficiencia_entrega'.
-- A funcionária 'Mariana Alves' realiza um serviço e o entrega ATRASADO.
SELECT CADASTRAR_LAVAGEM(
    p_cliente_cpf            => '222.222.222-22', -- Bruno Costa
    p_funcionario_cpf        => '667.788.999-00', -- Mariana Alves
    p_tipo_lavagem_descricao => 'Lavagem Delicada (KG)',
    p_tipo_pagamento_nome    => 'Dinheiro',
    p_dt_prev_entrega        => '2025-07-25 12:00:00',
    p_observacoes            => 'Atrasou a entrega devido à alta demanda.',
    p_peso_lavagem           => 5.0
);
-- Concluindo a lavagem com data de entrega real posterior à prevista.
SELECT ATUALIZAR_STATUS_LAVAGEM(13, 'CONCLUIDA');
SELECT ALTERAR('lavagem', 'dt_real_entrega = ''2025-07-26 10:00:00''', 'id_lavagem = 13');


-- 4. Uso alto de produto para baixar o estoque do "Detergente Limpeza Geral"
SELECT CADASTRAR('lavagem_produto', (SELECT MAX(id_lavagem) FROM lavagem) || ', 7, 350');


-- Faturamento de Julho de 2025
RAISE NOTICE 'Relatório: Faturamento em Julho de 2025';
SELECT * FROM relatorio_faturamento_periodo('2025-07-01', '2025-07-31');

-- Clientes com pagamentos em atraso
SELECT ALTERAR('parcela', 'dt_vencimento = ''2025-07-3''', 'id_parcela = 2');

----------------------------------------------------------------------
-- SEÇÃO 3: RELATORIOS
----------------------------------------------------------------------

-- Cenário para popular o 'relatorio_inadimplencia'
-- Forçamos uma data de vencimento no passado para a parcela da lavagem de ID 2
DROP TRIGGER TR_VERIFICAR_DT_VENCIMENTO_FUTURA ON PARCELA;
SELECT ALTERAR('parcela', 'dt_vencimento = ''2025-07-01''', 'fk_parcela_lavagem = 2');

SELECT * FROM relatorio_inadimplencia();


-- Cenário para popular o 'relatorio_clientes_inativos'
-- Forçamos uma data de entrada antiga para a lavagem do "Fernando Rocha" (lavagem ID 6)
SELECT ALTERAR('lavagem', 'dt_entrada = ''2024-01-05 10:00:00''', 'fk_lavagem_cliente = 6');

-- Clientes que não retornam há mais de 180 dias
RAISE NOTICE 'Relatório: Clientes Inativos (>180 dias)';
SELECT * FROM relatorio_clientes_inativos(180);

-- Desempenho dos funcionários no último ano
RAISE NOTICE 'Relatório: Desempenho dos Funcionários (Último Ano)';
SELECT * FROM relatorio_desempenho_funcionario('2024-07-01', CURRENT_DATE);

-- Alerta de produtos com menos de 100 unidades/litros em estoque
RAISE NOTICE 'Relatório: Alerta de Estoque Baixo';
SELECT * FROM relatorio_alerta_estoque(100);

-- Histórico completo da cliente "Ana Pereira"
RAISE NOTICE 'Relatório: Histórico da Cliente Ana Pereira';
SELECT * FROM relatorio_historico_cliente('111.111.111-11');

-- Consulta à View de detalhes das lavagens
RAISE NOTICE 'View: Painel de Controle de Lavagens';
SELECT * FROM V_DETALHES_LAVAGENS;

-- Consulta à View de estoque atual
RAISE NOTICE 'View: Estoque Atual';
SELECT * FROM V_ESTOQUE_ATUAL;


----------------- USO DO ESTOQUE -----------------------

-- Consultando o estoque atual em ml
SELECT nome, qtd_estoque, unidade_base FROM produto WHERE id_produto = 1;

-- Criando uma nova compra (ela receberá o ID 6, pois a última foi 5)
-- O status inicial é 'PENDENTE'
SELECT CADASTRAR('compra', 'DEFAULT, 1, ''2025-07-04'', 900.00, ''PENDENTE''');

-- Adicionando 10 Litros de Sabão Líquido a essa nova compra (ID 6)
SELECT CADASTRAR('item', 'DEFAULT, 6, 1, ''Sabão Profissional (10 Litros)'', 10.00, 90.00');

-- ATENÇÃO: Este comando vai acionar o gatilho 'trg_adicionar_estoque_apos_entrega'
-- Ele vai ler o item da compra 6 (10 Litros) e somar 10 * 1000 = 10000ml ao estoque.
SELECT ALTERAR('compra', 'status_compra = ''ENTREGUE''', 'id_compra = 6');

-- Vamos verificar o estoque novamente
SELECT nome, qtd_estoque, unidade_base FROM produto WHERE id_produto = 1;

-- ATENÇÃO: Este comando vai acionar o gatilho 'trg_subtrair_estoque_apos_uso'
-- Ele vai subtrair 150ml do estoque do produto de ID 1.
-- (Usando a lavagem de ID 10 como exemplo)
SELECT CADASTRAR('lavagem_produto', '10, 1, 150.00');

-- Vamos verificar o estoque pela última vez
SELECT nome, qtd_estoque, unidade_base FROM produto WHERE id_produto = 1;

SELECT 
    nome, 
    (qtd_estoque / fator_conversao) AS estoque_convertido,
    unidade_medida
FROM produto;


---------------------------------------------------------------------------------






SELECT * FROM lavagem ORDER BY id_lavagem ;
-- ESTE COMANDO DEVE FALHAR
SELECT ALTERAR(
    'lavagem', 
    'status_lavagem = ''CONCLUIDA''', -- Mudando o status
    'id_lavagem = 3'
);