CREATE TABLE CLIENTE (
    ID_CLIENTE SERIAL PRIMARY KEY,
    NOME VARCHAR(100) NOT NULL, 
    CPF VARCHAR(15) NOT NULL, --- ADICIONEI OS UNIQUE POR FUNÇÃO ---
    DT_NASC DATE,
    TELEFONE VARCHAR(20),
    EMAIL VARCHAR(100),
    ENDERECO VARCHAR(255),
    PREFERENCIAS_LAVAGEM TEXT,
    DATA_CADASTRO DATE DEFAULT CURRENT_DATE, --- DATA_CADASTRO como do tipo DATE e, se nenhum valor for informado ao inserir um registro, o banco atribui automaticamente a data atual (hoje) àquele campo.
    ULTIMO_SERVICO DATE
);

CREATE TABLE FUNCIONARIO (
    ID_FUNCIONARIO SERIAL PRIMARY KEY,
    NOME VARCHAR(100) NOT NULL,
    CPF VARCHAR(15) NOT NULL, --- ADICIONEI OS UNIQUE POR FUNÇÃO ---
    CARGO VARCHAR(50),
    DT_CONTRATACAO DATE,
    TELEFONE VARCHAR(20),
    EMAIL VARCHAR(100),
    SALARIO DECIMAL(10,2)
);

CREATE TABLE TIPO_LAVAGEM (
    ID_TIPO_LAVAGEM SERIAL PRIMARY KEY,
    DESCRICAO VARCHAR(100) NOT NULL,
    PRECO_POR_KG DECIMAL(10,2), -- FIZ ESSES DOIS AQUI NÃO SEREM NEGATIVO -- 
    PRECO_FIXO DECIMAL(10,2), -- FIZ ESSES DOIS AQUI NÃO SEREM NEGATIVO -- 
    UNIDADE_MEDIDA VARCHAR(20)
);

CREATE TABLE TIPO_PAGAMENTO (
    ID_TIPO_PAGAMENTO SERIAL PRIMARY KEY,
    NOME VARCHAR(30) NOT NULL,
    DESCRICAO VARCHAR(120) NOT NULL
);

CREATE TABLE FORNECEDOR (
    ID_FORNECEDOR SERIAL PRIMARY KEY,
    NOME VARCHAR(100) NOT NULL,
    CNPJ VARCHAR(20), --- ADICIONEI OS UNIQUE POR FUNÇÃO ---
    TELEFONE VARCHAR(20),
    EMAIL VARCHAR(100),
    ENDERECO VARCHAR(255)
);

-------------------- PROCESSOS --------------------

CREATE TABLE PRODUTO (
    ID_PRODUTO SERIAL PRIMARY KEY,
    NOME VARCHAR(100) NOT NULL,
    DESCRICAO TEXT,
    UNIDADE_MEDIDA VARCHAR(20) NOT NULL,      -- Como o produto é vendido (ex: Litro, Kg, Unidade) - Adicionar Trigger
    UNIDADE_BASE VARCHAR(20) NOT NULL,        -- A menor unidade de controle (ex: ml, g, unidade) - Adicionar Trigger
    FATOR_CONVERSAO DECIMAL(10, 4) NOT NULL,  -- Quantas 'unidades_base' cabem em uma 'unidade_medida' - Adicionar Trigger
    QTD_ESTOQUE INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE COMPRA (
    ID_COMPRA SERIAL PRIMARY KEY,
    fk_compra_fornecedor INT REFERENCES FORNECEDOR(ID_FORNECEDOR),
    DT_COMPRA DATE NOT NULL, -- Adicionar timestamp nesta colun a
    VALOR_TOTAL DECIMAL(10,2) NOT NULL, -- Valor não fica negativo -- 
    STATUS_COMPRA VARCHAR(50) 
);

CREATE TABLE ITEM (
    ID_ITEM SERIAL PRIMARY KEY,
    fk_item_compra INT REFERENCES COMPRA(ID_COMPRA), --
    fk_item_produto INT REFERENCES PRODUTO(ID_PRODUTO),--
    DESCRICAO_ITEM VARCHAR(100) NOT NULL,
    QTD_ITEM DECIMAL(10,2) NOT NULL, --
    VALOR_UNITARIO DECIMAL(10,2) NOT NULL, --
    VALOR_TOTAL DECIMAL(10,2) --
);


/*
GENERATED ALWAYS AS (QTD_ITEM * VALOR_UNITARIO) indica que o valor dessa coluna será sempre o resultado da multiplicação entre QTD_ITEM e VALOR_UNITARIO.
STORED significa que esse cálculo é feito no momento da inserção/atualização e armazenado fisicamente no banco. 
*/

-------------------- LAVAGEM E FINANCEIRO --------------------
CREATE TABLE LAVAGEM (
    ID_LAVAGEM SERIAL PRIMARY KEY,
    fk_lavagem_cliente INT REFERENCES CLIENTE(ID_CLIENTE),
    fk_lavagem_funcionario INT REFERENCES FUNCIONARIO(ID_FUNCIONARIO),
    fk_lavagem_tipo INT REFERENCES TIPO_LAVAGEM(ID_TIPO_LAVAGEM),
    fk_lavagem_pagamento INT REFERENCES TIPO_PAGAMENTO(ID_TIPO_PAGAMENTO),
    DT_ENTRADA TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    DT_PREV_ENTREGA TIMESTAMP,
    DT_REAL_ENTREGA TIMESTAMP,
    STATUS_LAVAGEM VARCHAR(50) NOT NULL,
	VALOR_TOTAL_LAVAGEM DECIMAL(10,2),
    OBSERVACOES TEXT
);

CREATE TABLE PARCELA (
    ID_PARCELA SERIAL PRIMARY KEY,
    fk_parcela_lavagem INT REFERENCES LAVAGEM(ID_LAVAGEM) ON DELETE SET NULL,
    NUM_PARCELA INT NOT NULL,
    VALOR_PARCELA DECIMAL(10,2) NOT NULL,
    DT_VENCIMENTO DATE NOT NULL,
    DT_PAGAMENTO DATE,
    STATUS_PARCELA VARCHAR(50) NOT NULL CHECK (STATUS_PARCELA IN ('PAGO','PENDENTE','ATRASADO'))
);

-------------------- RELACIONAMENTO USO DE PRODUTOS NA LAVAGEM --------------------

CREATE TABLE LAVAGEM_PRODUTO (
    fk_lavagem_produto_lavagem INT REFERENCES LAVAGEM(ID_LAVAGEM) ON DELETE SET NULL,
    fk_lavagem_produto_produto INT REFERENCES PRODUTO(ID_PRODUTO) ON DELETE SET NULL,
    QTD_UTILIZADA DECIMAL(10,2) NOT NULL CHECK (QTD_UTILIZADA > 0),
    PRIMARY KEY (fk_lavagem_produto_lavagem, fk_lavagem_produto_produto)
);

SELECT * FROM LAVAGEM_PRODUTO;

-- Tabela de Auditoria
CREATE TABLE AUDITORIA_LOG (
    ID_LOG SERIAL PRIMARY KEY,
    NOME_TABELA VARCHAR(100) NOT NULL,
    OPERACAO VARCHAR(10) NOT NULL, -- 'INSERT', 'UPDATE', 'DELETE'
    ID_REGISTRO_AFETADO INT,
    DATA_HORA TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    USUARIO_BD TEXT DEFAULT CURRENT_USER,
    DETALHES TEXT
);

-------------------- POVOAMENTO DAS TABELAS --------------------

-- Primeiro, execute as funções de limpeza e reset:
 SELECT LIMPAR_TODAS_TABELAS();
 SELECT RESETAR_SERIAL();

-- Inserção nas tabelas de cadastro usando a função genérica
SELECT CADASTRAR('cliente', 'DEFAULT, ''Ana Pereira'', ''111.111.111-11'', ''1985-03-10'', ''86981234567'', ''ana.pereira@email.com'', ''Rua das Flores, 101, Centro, Teresina-PI'', ''Lavagem a seco para vestidos'', DEFAULT, NULL');
SELECT CADASTRAR('cliente', 'DEFAULT, ''Bruno Costa'', ''222.222.222-22'', ''1990-07-22'', ''86982345678'', ''bruno.costa@email.com'', ''Av. Principal, 202, Horto, Teresina-PI'', ''Apenas amaciante suave'', DEFAULT, NULL');
SELECT CADASTRAR('cliente', 'DEFAULT, ''Carla Lima'', ''333.333.333-33'', ''1978-01-05'', ''86983456789'', ''carla.lima@email.com'', ''Rua do Sol, 303, Fátima, Teresina-PI'', ''Lavagem de cobertores'', DEFAULT, NULL');
SELECT CADASTRAR('cliente', 'DEFAULT, ''Diego Alves'', ''444.444.444-44'', ''1995-11-28'', ''86984567890'', ''diego.alves@email.com'', ''Travessa da Lua, 404, Ininga, Teresina-PI'', ''Sem goma'', DEFAULT, NULL');
SELECT CADASTRAR('cliente', 'DEFAULT, ''Elisa Martins'', ''555.555.555-55'', ''1982-09-12'', ''86985678901'', ''elisa.martins@email.com'', ''Rua da Paz, 505, Morada do Sol, Teresina-PI'', ''Remoção de manchas leves'', DEFAULT, NULL');
SELECT CADASTRAR('cliente', 'DEFAULT, ''Fernando Rocha'', ''666.666.666-66'', ''1970-04-17'', ''86986789012'', ''fernando.rocha@email.com'', ''Av. do Bosque, 606, Piçarra, Teresina-PI'', ''Roupas sociais passadas'', DEFAULT, NULL');
SELECT CADASTRAR('cliente', 'DEFAULT, ''Giovanna Silva'', ''777.777.777-77'', ''2000-02-20'', ''86987890123'', ''giovanna.silva@email.com'', ''Rua da Alegria, 707, São Cristóvão, Teresina-PI'', ''Secagem delicada para lã'', DEFAULT, NULL');

SELECT CADASTRAR('funcionario', 'DEFAULT, ''João Neto'', ''112.233.444-55'', ''Atendente'', ''2023-01-10'', ''86991112222'', ''joao.neto@lavanderia.com'', 2000.00');
SELECT CADASTRAR('funcionario', 'DEFAULT, ''Mariana Alves'', ''667.788.999-00'', ''Lavador'', ''2022-05-20'', ''86992223333'', ''mariana.alves@lavanderia.com'', 2400.00');
SELECT CADASTRAR('funcionario', 'DEFAULT, ''Lucas Santos'', ''001.122.333-44'', ''Passadeira'', ''2023-03-15'', ''86993334444'', ''lucas.santos@lavanderia.com'', 2200.00');
SELECT CADASTRAR('funcionario', 'DEFAULT, ''Sofia Nunes'', ''445.566.777-88'', ''Gerente'', ''2021-08-01'', ''86994445555'', ''sofia.nunes@lavanderia.com'', 3800.00');
SELECT CADASTRAR('funcionario', 'DEFAULT, ''Pedro Mendes'', ''556.677.888-99'', ''Atendente'', ''2024-02-01'', ''86995556666'', ''pedro.mendes@lavanderia.com'', 2100.00');

SELECT CADASTRAR('tipo_lavagem', 'DEFAULT, ''Lavagem Convencional (KG)'', 10.00, NULL, ''Kg''');
SELECT CADASTRAR('tipo_lavagem', 'DEFAULT, ''Lavagem a Seco (Peça)'', NULL, 55.00, ''Peça''');
SELECT CADASTRAR('tipo_lavagem', 'DEFAULT, ''Lavagem Delicada (KG)'', 15.00, NULL, ''Kg''');
SELECT CADASTRAR('tipo_lavagem', 'DEFAULT, ''Lavagem de Edredom (Unidade)'', NULL, 45.00, ''Unidade''');
SELECT CADASTRAR('tipo_lavagem', 'DEFAULT, ''Passadoria (Peça)'', NULL, 18.00, ''Peça''');
SELECT CADASTRAR('tipo_lavagem', 'DEFAULT, ''Limpeza de Tapete (M2)'', 12.00, NULL, ''m2''');
SELECT CADASTRAR('tipo_lavagem', 'DEFAULT, ''Higienização de Sofá (Unidade)'', NULL, 180.00, ''Unidade''');

SELECT CADASTRAR('tipo_pagamento', 'DEFAULT, ''Cartão de Crédito'', ''Pagamento realizado via cartão de crédito...''');
SELECT CADASTRAR('tipo_pagamento', 'DEFAULT, ''Cartão de Débito'', ''Pagamento realizado via cartão de débito...''');
SELECT CADASTRAR('tipo_pagamento', 'DEFAULT, ''Dinheiro'', ''Pagamento realizado em espécie...''');
SELECT CADASTRAR('tipo_pagamento', 'DEFAULT, ''PIX'', ''Pagamento instantâneo via sistema PIX...''');
SELECT CADASTRAR('tipo_pagamento', 'DEFAULT, ''Boleto Bancário'', ''Pagamento realizado através de boleto...''');

SELECT CADASTRAR('fornecedor', 'DEFAULT, ''Limpa Tudo Soluções'', ''00.111.222/0001-33'', ''8630001111'', ''contato@limpatudo.com'', ''Rua das Indústrias, 100, Teresina-PI''');
SELECT CADASTRAR('fornecedor', 'DEFAULT, ''Produtquímica LTDA'', ''00.444.555/0001-66'', ''8630002222'', ''vendas@produtquimica.com'', ''Av. Central, 200, Teresina-PI''');
SELECT CADASTRAR('fornecedor', 'DEFAULT, ''Aroma & Cia'', ''01.234.567/0001-89'', ''8630003333'', ''comercial@aromacia.com'', ''Rua da Perfumaria, 300, Teresina-PI''');
SELECT CADASTRAR('fornecedor', 'DEFAULT, ''Máquinas Lavanderia'', ''03.456.789/0001-01'', ''8630004444'', ''suporte@maquinaslavanderia.com'', ''Av. dos Equipamentos, 400, Teresina-PI''');
SELECT CADASTRAR('fornecedor', 'DEFAULT, ''Embalagens Express'', ''02.345.678/0001-90'', ''8630005555'', ''contato@embalagensexpress.com'', ''Rua da Logística, 500, Teresina-PI''');

SELECT CADASTRAR('produto', 'DEFAULT, ''Sabão Líquido Profissional'', ''Sabão concentrado para lavanderias'', ''Litro'', ''ml'', 1000, 200000.00');
SELECT CADASTRAR('produto', 'DEFAULT, ''Amaciante Perfumado'', ''Amaciante com fragrância duradoura'', ''Litro'', ''ml'', 1000, 150000.00');
SELECT CADASTRAR('produto', 'DEFAULT, ''Alvejante Oxy'', ''Alvejante sem cloro para brancos e coloridos'', ''Litro'', ''ml'', 1000, 100000.00');
SELECT CADASTRAR('produto', 'DEFAULT, ''Tira Manchas Universal'', ''Eficaz contra diversos tipos de manchas - frasco de 500ml'', ''Frasco'', ''ml'', 500, 37500.00');
SELECT CADASTRAR('produto', 'DEFAULT, ''Cabide Plástico Reforçado'', ''Para pendurar roupas após lavagem/passadoria'', ''Unidade'', ''unidade'', 1, 500.00');
SELECT CADASTRAR('produto', 'DEFAULT, ''Saco de Embalagem Grande'', ''Para entrega de roupas lavadas'', ''Unidade'', ''unidade'', 1, 1000.00');
SELECT CADASTRAR('produto', 'DEFAULT, ''Detergente Limpeza Geral'', ''Para limpeza do ambiente da lavanderia'', ''Litro'', ''ml'', 1000, 80000.00');

SELECT CADASTRAR('compra', 'DEFAULT, 1	, ''2025-05-01'', 450.00, ''ENTREGUE''');
SELECT CADASTRAR('compra', 'DEFAULT, 2, ''2025-05-10'', 300.00, ''ENTREGUE''');
SELECT CADASTRAR('compra', 'DEFAULT, 3, ''2025-05-15'', 120.00, ''ENTREGUE''');
SELECT CADASTRAR('compra', 'DEFAULT, 4, ''2025-05-20'', 800.00, ''PENDENTE''');
SELECT CADASTRAR('compra', 'DEFAULT, 5, ''2025-06-01'', 250.00, ''ENTREGUE''');

-- Inserção na tabela item (dados corrigidos)
SELECT CADASTRAR('item', 'DEFAULT, 1, 1, ''Sabão Profissional 5L'', 5.00, 90.00');
SELECT CADASTRAR('item', 'DEFAULT, 1, 2, ''Amaciante 2L'', 10.00, 20.00');
SELECT CADASTRAR('item', 'DEFAULT, 2, 3, ''Alvejante Oxy 1L'', 4.00, 75.00');
SELECT CADASTRAR('item', 'DEFAULT, 3, 4, ''Tira Manchas 500ml'', 3.00, 40.00');
SELECT CADASTRAR('item', 'DEFAULT, 4, 5, ''Cabides Plásticos (Pacote 100)'', 8.00, 100.00');
SELECT CADASTRAR('item', 'DEFAULT, 5, 6, ''Saco de Embalagem (Pacote 500)'', 2.00, 125.00');

-- Inserção na tabela lavagem usando a função específica
-- As datas de entrada foram fixadas para consistência nos testes dos relatórios
SELECT CADASTRAR_LAVAGEM('111.111.111-11', '112.233.444-55', 'Lavagem Convencional (KG)', 'PIX', '2025-07-20 10:00:00', 'CONCLUIDA', 'Roupas do dia a dia, 3kg', '2025-07-19 18:00:00');
SELECT CADASTRAR_LAVAGEM('222.222.222-22', '667.788.999-00', 'Lavagem a Seco (Peça)', 'Cartão de Crédito', '2025-07-21 11:30:00', 'EM ANDAMENTO', 'Vestido de festa (lavagem a seco)');
SELECT CADASTRAR_LAVAGEM('333.333.333-33', '001.122.333-44', 'Lavagem Delicada (KG)', 'Cartão de Débito', '2025-07-22 09:00:00', 'EM ANDAMENTO', 'Edredom de casal e 2 fronhas');
SELECT CADASTRAR_LAVAGEM('444.444.444-44', '112.233.444-55', 'Lavagem de Edredom (Unidade)', 'Dinheiro', '2025-07-19 14:00:00', 'CONCLUIDA', 'Cobertor de microfibra', '2025-07-19 13:00:00');
SELECT CADASTRAR_LAVAGEM('555.555.555-55', '667.788.999-00', 'Passadoria (Peça)', 'PIX', '2025-07-22 15:00:00', 'EM ANDAMENTO', '5 camisas sociais para passar');
SELECT CADASTRAR_LAVAGEM('666.666.666-66', '001.122.333-44', 'Lavagem Convencional (KG)', 'Cartão de Crédito', '2025-07-18 08:00:00', 'CONCLUIDA', '7kg de roupas mistas', '2025-07-18 07:30:00');
SELECT CADASTRAR_LAVAGEM('777.777.777-77', '445.566.777-88', 'Lavagem Delicada (KG)', 'Cartão de Débito', '2025-07-21 16:00:00', 'EM ANDAMENTO', 'Roupas delicadas de bebê, 1kg');
SELECT CADASTRAR_LAVAGEM('111.111.111-11', '556.677.888-99', 'Limpeza de Tapete (M2)', 'Dinheiro', '2025-07-17 10:00:00', 'CONCLUIDA', 'Tapete da sala (2m x 3m)', '2025-07-17 09:00:00');
SELECT CADASTRAR_LAVAGEM('222.222.222-22', '112.233.444-55', 'Higienização de Sofá (Unidade)', 'PIX', '2025-07-25 13:00:00', 'EM ANDAMENTO', 'Sofá de 3 lugares');
SELECT CADASTRAR_LAVAGEM('333.333.333-33', '667.788.999-00', 'Lavagem Convencional (KG)', 'Cartão de Crédito', '2025-07-19 09:00:00', 'CONCLUIDA', '4kg de calças jeans e camisetas', '2025-07-18 20:00:00');

-- Inserção na tabela parcela (usando a função genérica, o que é adequado aqui)
SELECT CADASTRAR('parcela', 'DEFAULT, 1, 1, 30.00, ''2025-07-10'', ''2025-07-08'', ''PAGO''');
SELECT CADASTRAR('parcela', 'DEFAULT, 2, 1, 55.00, ''2025-07-15'', NULL, ''PENDENTE''');
SELECT CADASTRAR('parcela', 'DEFAULT, 3, 1, 45.00, ''2025-07-20'', NULL, ''PENDENTE''');
SELECT CADASTRAR('parcela', 'DEFAULT, 4, 1, 45.00, ''2025-07-12'', ''2025-07-11'', ''PAGO''');
SELECT CADASTRAR('parcela', 'DEFAULT, 5, 1, 90.00, ''2025-07-18'', NULL, ''PENDENTE''');
SELECT CADASTRAR('parcela', 'DEFAULT, 6, 1, 70.00, ''2025-07-05'', ''2025-07-04'', ''PAGO''');
SELECT CADASTRAR('parcela', 'DEFAULT, 7, 1, 15.00, ''2025-07-25'', NULL, ''PENDENTE''');
SELECT CADASTRAR('parcela', 'DEFAULT, 8, 1, 24.00, ''2025-07-16'', ''2025-07-15'', ''PAGO''');
SELECT CADASTRAR('parcela', 'DEFAULT, 9, 1, 180.00, ''2025-07-28'', NULL, ''PENDENTE''');
SELECT CADASTRAR('parcela', 'DEFAULT, 10, 1, 40.00, ''2025-07-19'', ''2025-07-18'', ''PAGO''');

-- Inserção na tabela lavagem_produto (usando a função genérica, adequado para esta tabela de ligação)
SELECT CADASTRAR('lavagem_produto', '1, 1, 0.05');
SELECT CADASTRAR('lavagem_produto', '1, 2, 0.03');
SELECT CADASTRAR('lavagem_produto', '2, 3, 0.01');
SELECT CADASTRAR('lavagem_produto', '3, 1, 0.10');
SELECT CADASTRAR('lavagem_produto', '4, 1, 0.08');
SELECT CADASTRAR('lavagem_produto', '5, 4, 0.02');
SELECT CADASTRAR('lavagem_produto', '6, 1, 0.12');
SELECT CADASTRAR('lavagem_produto', '7, 2, 0.04');
SELECT CADASTRAR('lavagem_produto', '8, 7, 0.15');
SELECT CADASTRAR('lavagem_produto', '9, 1, 0.20');
SELECT CADASTRAR('lavagem_produto', '10, 2, 0.06');


SELECT deletar('auditoria_log');
ALTER SEQUENCE auditoria_log_id_log_seq RESTART WITH 1;



SELECT CADASTRAR('cliente', 'DEFAULT, ''Bruno 1Costa'', ''212.422.222-22'', ''1990-07-22'', ''86982345678'', ''bruno.costa@email.com'', ''Av. Principal, 202, Horto, Teresina-PI'', ''Apenas amaciante suave'', DEFAULT, NULL');