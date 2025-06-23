-------------------- TABELAS PRINCIPAIS --------------------

CREATE TABLE CLIENTE (
    ID_CLIENTE SERIAL PRIMARY KEY,
    NOME VARCHAR(100) NOT NULL, 
    CPF VARCHAR(15) UNIQUE NOT NULL, --- UNIQUE impõe que todos os valores de uma coluna (ou combinação de colunas) sejam exclusivos
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
    CPF VARCHAR(15) UNIQUE NOT NULL,
    CARGO VARCHAR(50),
    DT_CONTRATACAO DATE,
    TELEFONE VARCHAR(20),
    EMAIL VARCHAR(100),
    SALARIO DECIMAL(10,2)
);

CREATE TABLE TIPO_LAVAGEM (
    ID_TIPO_LAVAGEM SERIAL PRIMARY KEY,
    DESCRICAO VARCHAR(100) NOT NULL,
    PRECO_POR_KG DECIMAL(10,2),
    PRECO_FIXO DECIMAL(10,2),
    UNIDADE_MEDIDA VARCHAR(20)
);

CREATE TABLE TIPO_PAGAMENTO (
    ID_TIPO_PAGAMENTO SERIAL PRIMARY KEY,
    DESCRICAO VARCHAR(70) NOT NULL
);

CREATE TABLE FORNECEDOR (
    ID_FORNECEDOR SERIAL PRIMARY KEY,
    NOME VARCHAR(100) NOT NULL,
    CNPJ VARCHAR(20) UNIQUE,
    TELEFONE VARCHAR(20),
    EMAIL VARCHAR(100),
    ENDERECO VARCHAR(255)
);

-------------------- PROCESSOS --------------------

CREATE TABLE PRODUTO (
    ID_PRODUTO SERIAL PRIMARY KEY,
    NOME VARCHAR(100) NOT NULL,
    DESCRICAO TEXT,
    UNIDADE_MEDIDA VARCHAR(20) NOT NULL,
    QTD_ESTOQUE DECIMAL(10,2) NOT NULL CHECK (QTD_ESTOQUE >= 0)
);

CREATE TABLE COMPRA (
    ID_COMPRA SERIAL PRIMARY KEY,
    fk_compra_fornecedor INT REFERENCES FORNECEDOR(ID_FORNECEDOR) ON DELETE SET NULL, -- Adicionado ON DELETE SET NULL,
    DT_COMPRA DATE NOT NULL,
    VALOR_TOTAL DECIMAL(10,2) NOT NULL,
    STATUS_COMPRA VARCHAR(50) CHECK (STATUS_COMPRA IN ('PENDENTE','ENTREGUE','CANCELADA'))  --- Cria uma restrição de verificação (CHECK) que só permite que ela assuma valores informados.
);
DROP TABLE compra CASCADE;


CREATE TABLE ITEM (
    ID_ITEM SERIAL PRIMARY KEY,
    fk_item_compra INT REFERENCES COMPRA(ID_COMPRA) ON DELETE SET NULL, 
    fk_item_produto INT REFERENCES PRODUTO(ID_PRODUTO) ON DELETE SET NULL,
    DESCRICAO_ITEM VARCHAR(100) NOT NULL,
    QTD_ITEM DECIMAL(10,2) NOT NULL CHECK (QTD_ITEM > 0),
    VALOR_UNITARIO DECIMAL(10,2) NOT NULL,
    VALOR_TOTAL DECIMAL(10,2) GENERATED ALWAYS AS (QTD_ITEM * VALOR_UNITARIO) STORED
);

/*
GENERATED ALWAYS AS (QTD_ITEM * VALOR_UNITARIO) indica que o valor dessa coluna será sempre o resultado da multiplicação entre QTD_ITEM e VALOR_UNITARIO.
STORED significa que esse cálculo é feito no momento da inserção/atualização e armazenado fisicamente no banco. 
*/

-------------------- LAVAGEM E FINANCEIRO --------------------

CREATE TABLE LAVAGEM (
    ID_LAVAGEM SERIAL PRIMARY KEY,
    fk_lavagem_cliente INT REFERENCES CLIENTE(ID_CLIENTE) ON DELETE SET NULL,
    fk_lavagem_funcionario INT REFERENCES FUNCIONARIO(ID_FUNCIONARIO) ON DELETE SET NULL,
    fk_lavagem_tipo INT REFERENCES TIPO_LAVAGEM(ID_TIPO_LAVAGEM) ON DELETE SET NULL,
    fk_lavagem_pagamento INT REFERENCES TIPO_PAGAMENTO(ID_TIPO_PAGAMENTO) ON DELETE SET NULL,
    DT_ENTRADA TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    DT_PREV_ENTREGA TIMESTAMP,
    DT_REAL_ENTREGA TIMESTAMP,
    STATUS_LAVAGEM VARCHAR(50) NOT NULL CHECK (STATUS_LAVAGEM IN ('EM ANDAMENTO','CONCLUIDA','CANCELADA')),
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

-- Inserção na tabela cliente (7 clientes variados)
SELECT CADASTRAR('cliente', 'DEFAULT, ''Ana Pereira'', ''111.111.111-11'', ''1985-03-10'', ''86981234567'', ''ana.pereira@email.com'', ''Rua das Flores, 101, Centro, Teresina-PI'', ''Lavagem a seco para vestidos'', DEFAULT, ''2025-06-15''');
SELECT CADASTRAR('cliente', 'DEFAULT, ''Bruno Costa'', ''222.222.222-22'', ''1990-07-22'', ''86982345678'', ''bruno.costa@email.com'', ''Av. Principal, 202, Horto, Teresina-PI'', ''Apenas amaciante suave'', DEFAULT, ''2025-06-10''');
SELECT CADASTRAR('cliente', 'DEFAULT, ''Carla Lima'', ''333.333.333-33'', ''1978-01-05'', ''86983456789'', ''carla.lima@email.com'', ''Rua do Sol, 303, Fátima, Teresina-PI'', ''Lavagem de cobertores'', DEFAULT, ''2025-06-18''');
SELECT CADASTRAR('cliente', 'DEFAULT, ''Diego Alves'', ''444.444.444-44'', ''1995-11-28'', ''86984567890'', ''diego.alves@email.com'', ''Travessa da Lua, 404, Ininga, Teresina-PI'', ''Sem goma'', DEFAULT, ''2025-06-20''');
SELECT CADASTRAR('cliente', 'DEFAULT, ''Elisa Martins'', ''555.555.555-55'', ''1982-09-12'', ''86985678901'', ''elisa.martins@email.com'', ''Rua da Paz, 505, Morada do Sol, Teresina-PI'', ''Remoção de manchas leves'', DEFAULT, ''2025-06-12''');
SELECT CADASTRAR('cliente', 'DEFAULT, ''Fernando Rocha'', ''666.666.666-66'', ''1970-04-17'', ''86986789012'', ''fernando.rocha@email.com'', ''Av. do Bosque, 606, Piçarra, Teresina-PI'', ''Roupas sociais passadas'', DEFAULT, ''2025-06-08''');
SELECT CADASTRAR('cliente', 'DEFAULT, ''Giovanna Silva'', ''777.777.777-77'', ''2000-02-20'', ''86987890123'', ''giovanna.silva@email.com'', ''Rua da Alegria, 707, São Cristóvão, Teresina-PI'', ''Secagem delicada para lã'', DEFAULT, ''2025-06-22''');

-- Inserção na tabela funcionario (5 funcionários com diferentes cargos)
SELECT CADASTRAR('funcionario', 'DEFAULT, ''João Neto'', ''112.233.444-55'', ''Atendente'', ''2023-01-10'', ''86991112222'', ''joao.neto@lavanderia.com'', 2000.00');
SELECT CADASTRAR('funcionario', 'DEFAULT, ''Mariana Alves'', ''667.788.999-00'', ''Lavador'', ''2022-05-20'', ''86992223333'', ''mariana.alves@lavanderia.com'', 2400.00');
SELECT CADASTRAR('funcionario', 'DEFAULT, ''Lucas Santos'', ''001.122.333-44'', ''Passadeira'', ''2023-03-15'', ''86993334444'', ''lucas.santos@lavanderia.com'', 2200.00');
SELECT CADASTRAR('funcionario', 'DEFAULT, ''Sofia Nunes'', ''445.566.777-88'', ''Gerente'', ''2021-08-01'', ''86994445555'', ''sofia.nunes@lavanderia.com'', 3800.00');
SELECT CADASTRAR('funcionario', 'DEFAULT, ''Pedro Mendes'', ''556.677.888-99'', ''Atendente'', ''2024-02-01'', ''86995556666'', ''pedro.mendes@lavanderia.com'', 2100.00');

-- Inserção na tabela tipo_lavagem (7 tipos de lavagem essenciais)
SELECT CADASTRAR('tipo_lavagem', 'DEFAULT, ''Lavagem Convencional (KG)'', 10.00, NULL, ''Kg''');
SELECT CADASTRAR('tipo_lavagem', 'DEFAULT, ''Lavagem a Seco (Peça)'', NULL, 55.00, ''Peça''');
SELECT CADASTRAR('tipo_lavagem', 'DEFAULT, ''Lavagem Delicada (KG)'', 15.00, NULL, ''Kg''');
SELECT CADASTRAR('tipo_lavagem', 'DEFAULT, ''Lavagem de Edredom (Unidade)'', NULL, 45.00, ''Unidade''');
SELECT CADASTRAR('tipo_lavagem', 'DEFAULT, ''Passadoria (Peça)'', NULL, 18.00, ''Peça''');
SELECT CADASTRAR('tipo_lavagem', 'DEFAULT, ''Limpeza de Tapete (M2)'', 12.00, NULL, ''m2''');
SELECT CADASTRAR('tipo_lavagem', 'DEFAULT, ''Higienização de Sofá (Unidade)'', NULL, 180.00, ''Unidade''');


-- Inserção na tabela tipo_pagamento (5 formas de pagamento mais comuns)
SELECT CADASTRAR('tipo_pagamento', 'DEFAULT, ''Cartão de Crédito''');
SELECT CADASTRAR('tipo_pagamento', 'DEFAULT, ''Cartão de Débito''');
SELECT CADASTRAR('tipo_pagamento', 'DEFAULT, ''Dinheiro''');
SELECT CADASTRAR('tipo_pagamento', 'DEFAULT, ''PIX''');
SELECT CADASTRAR('tipo_pagamento', 'DEFAULT, ''Boleto Bancário''');

-- Inserção na tabela fornecedor (5 fornecedores principais)
SELECT CADASTRAR('fornecedor', 'DEFAULT, ''Limpa Tudo Soluções'', ''00.111.222/0001-33'', ''8630001111'', ''contato@limpatudo.com'', ''Rua das Indústrias, 100, Teresina-PI''');
SELECT CADASTRAR('fornecedor', 'DEFAULT, ''Produtquímica LTDA'', ''00.444.555/0001-66'', ''8630002222'', ''vendas@produtquimica.com'', ''Av. Central, 200, Teresina-PI''');
SELECT CADASTRAR('fornecedor', 'DEFAULT, ''Aroma & Cia'', ''01.234.567/0001-89'', ''8630003333'', ''comercial@aromacia.com'', ''Rua da Perfumaria, 300, Teresina-PI''');
SELECT CADASTRAR('fornecedor', 'DEFAULT, ''Máquinas Lavanderia'', ''03.456.789/0001-01'', ''8630004444'', ''suporte@maquinaslavanderia.com'', ''Av. dos Equipamentos, 400, Teresina-PI''');
SELECT CADASTRAR('fornecedor', 'DEFAULT, ''Embalagens Express'', ''02.345.678/0001-90'', ''8630005555'', ''contato@embalagensexpress.com'', ''Rua da Logística, 500, Teresina-PI''');

-- Inserção na tabela produto (7 produtos comuns e essenciais)
SELECT CADASTRAR('produto', 'DEFAULT, ''Sabão Líquido Profissional'', ''Sabão concentrado para lavanderias'', ''Litro'', 200.00');
SELECT CADASTRAR('produto', 'DEFAULT, ''Amaciante Perfumado'', ''Amaciante com fragrância duradoura'', ''Litro'', 150.00');
SELECT CADASTRAR('produto', 'DEFAULT, ''Alvejante Oxy'', ''Alvejante sem cloro para brancos e coloridos'', ''Litro'', 100.00');
SELECT CADASTRAR('produto', 'DEFAULT, ''Tira Manchas Universal'', ''Eficaz contra diversos tipos de manchas'', ''Frasco'', 75.00');
SELECT CADASTRAR('produto', 'DEFAULT, ''Cabide Plástico Reforçado'', ''Para pendurar roupas após lavagem/passadoria'', ''Unidade'', 500.00');
SELECT CADASTRAR('produto', 'DEFAULT, ''Saco de Embalagem Grande'', ''Para entrega de roupas lavadas'', ''Unidade'', 1000.00');
SELECT CADASTRAR('produto', 'DEFAULT, ''Detergente Limpeza Geral'', ''Para limpeza do ambiente da lavanderia'', ''Litro'', 80.00');

-- Inserção na tabela compra (5 compras de suprimentos)
SELECT CADASTRAR('compra', 'DEFAULT, 1, ''2025-05-01'', 450.00, ''ENTREGUE'''); -- Do fornecedor 1 (Limpa Tudo)
SELECT CADASTRAR('compra', 'DEFAULT, 2, ''2025-05-10'', 300.00, ''ENTREGUE'''); -- Do fornecedor 2 (Produtquímica)
SELECT CADASTRAR('compra', 'DEFAULT, 3, ''2025-05-15'', 120.00, ''ENTREGUE'''); -- Do fornecedor 3 (Aroma & Cia)
SELECT CADASTRAR('compra', 'DEFAULT, 4, ''2025-05-20'', 800.00, ''PENDENTE'''); -- Do fornecedor 4 (Máquinas Lavanderia)
SELECT CADASTRAR('compra', 'DEFAULT, 5, ''2025-06-01'', 250.00, ''ENTREGUE'''); -- Do fornecedor 5 (Embalagens Express)

-- Inserção na tabela item (Itens das compras)
SELECT CADASTRAR('item', 'DEFAULT, 1, 1, ''Sabão Profissional 5L'', 5.00, 90.00, DEFAULT'); -- Compra 1, Produto 1
SELECT CADASTRAR('item', 'DEFAULT, 1, 2, ''Amaciante 2L'', 10.00, 20.00, DEFAULT'); -- Compra 1, Produto 2
SELECT CADASTRAR('item', 'DEFAULT, 2, 3, ''Alvejante Oxy 1L'', 4.00, 75.00, DEFAULT'); -- Compra 2, Produto 3
SELECT CADASTRAR('item', 'DEFAULT, 3, 4, ''Tira Manchas 500ml'', 3.00, 40.00, DEFAULT'); -- Compra 3, Produto 4
SELECT CADASTRAR('item', 'DEFAULT, 4, 5, ''Cabides Plásticos (Pacote 100)'', 8.00, 100.00, DEFAULT'); -- Compra 4, Produto 5
SELECT CADASTRAR('item', 'DEFAULT, 5, 6, ''Saco de Embalagem (Pacote 500)'', 2.00, 125.00, DEFAULT'); -- Compra 5, Produto 6

-- Inserção na tabela lavagem (10 lavagens variadas, relacionando com clientes, funcionários, tipos de lavagem e pagamentos)
-- Data atual para o CURRENT_TIMESTAMP seria aproximadamente 2025-06-22
-- As datas de previsão e entrega real são posteriores à DT_ENTRADA
SELECT CADASTRAR('lavagem', 'DEFAULT, 1, 1, 1, 4, DEFAULT, ''2025-06-20 10:00:00'', ''2025-06-21 10:00:00'', ''CONCLUIDA'', ''Roupas do dia a dia, 3kg'''); -- Cliente 1, Atendente 1, Lav. Convencional, PIX
SELECT CADASTRAR('lavagem', 'DEFAULT, 2, 2, 2, 1, DEFAULT, ''2025-06-21 11:30:00'', NULL, ''EM ANDAMENTO'', ''Vestido de festa (lavagem a seco)'''); -- Cliente 2, Lavador 2, Lav. a Seco, Cartão Crédito
SELECT CADASTRAR('lavagem', 'DEFAULT, 3, 3, 3, 2, DEFAULT, ''2025-06-22 09:00:00'', NULL, ''EM ANDAMENTO'', ''Edredom de casal e 2 fronhas'''); -- Cliente 3, Passadeira 3, Lav. Delicada, Cartão Débito
SELECT CADASTRAR('lavagem', 'DEFAULT, 4, 1, 4, 3, DEFAULT, ''2025-06-19 14:00:00'', ''2025-06-20 14:00:00'', ''CONCLUIDA'', ''Cobertor de microfibra'''); -- Cliente 4, Atendente 1, Lav. Edredom, Dinheiro
SELECT CADASTRAR('lavagem', 'DEFAULT, 5, 2, 5, 4, DEFAULT, ''2025-06-22 15:00:00'', NULL, ''EM ANDAMENTO'', ''5 camisas sociais para passar'''); -- Cliente 5, Lavador 2, Passadoria, PIX
SELECT CADASTRAR('lavagem', 'DEFAULT, 6, 3, 1, 1, DEFAULT, ''2025-06-18 08:00:00'', ''2025-06-19 08:00:00'', ''CONCLUIDA'', ''7kg de roupas mistas'''); -- Cliente 6, Passadeira 3, Lav. Convencional, Cartão Crédito
SELECT CADASTRAR('lavagem', 'DEFAULT, 7, 4, 3, 2, DEFAULT, ''2025-06-21 16:00:00'', NULL, ''EM ANDAMENTO'', ''Roupas delicadas de bebê, 1kg'''); -- Cliente 7, Gerente 4, Lav. Delicada, Cartão Débito
SELECT CADASTRAR('lavagem', 'DEFAULT, 1, 5, 6, 3, DEFAULT, ''2025-06-17 10:00:00'', ''2025-06-19 10:00:00'', ''CONCLUIDA'', ''Tapete da sala (2m x 3m)'''); -- Cliente 1, Atendente 5, Limpeza de Tapete, Dinheiro
SELECT CADASTRAR('lavagem', 'DEFAULT, 2, 1, 7, 4, DEFAULT, ''2025-06-22 13:00:00'', NULL, ''EM ANDAMENTO'', ''Sofá de 3 lugares'''); -- Cliente 2, Atendente 1, Higienização de Sofá, PIX
SELECT CADASTRAR('lavagem', 'DEFAULT, 3, 2, 1, 1, DEFAULT, ''2025-06-19 09:00:00'', ''2025-06-20 09:00:00'', ''CONCLUIDA'', ''4kg de calças jeans e camisetas'''); -- Cliente 3, Lavador 2, Lav. Convencional, Cartão Crédito

-- Inserção na tabela parcela (Parcelas para algumas lavagens - com status variado)
SELECT CADASTRAR('parcela', 'DEFAULT, 1, 1, 30.00, ''2025-07-10'', ''2025-07-08'', ''PAGO'''); -- Lavagem 1, Parcela 1
SELECT CADASTRAR('parcela', 'DEFAULT, 2, 1, 55.00, ''2025-07-15'', NULL, ''PENDENTE'''); -- Lavagem 2, Parcela 1
SELECT CADASTRAR('parcela', 'DEFAULT, 3, 1, 45.00, ''2025-07-20'', NULL, ''PENDENTE'''); -- Lavagem 3, Parcela 1
SELECT CADASTRAR('parcela', 'DEFAULT, 4, 1, 45.00, ''2025-07-12'', ''2025-07-11'', ''PAGO'''); -- Lavagem 4, Parcela 1
SELECT CADASTRAR('parcela', 'DEFAULT, 5, 1, 90.00, ''2025-07-18'', NULL, ''PENDENTE'''); -- Lavagem 5, Parcela 1
SELECT CADASTRAR('parcela', 'DEFAULT, 6, 1, 70.00, ''2025-07-05'', ''2025-07-04'', ''PAGO'''); -- Lavagem 6, Parcela 1
SELECT CADASTRAR('parcela', 'DEFAULT, 7, 1, 15.00, ''2025-07-25'', NULL, ''PENDENTE'''); -- Lavagem 7, Parcela 1
SELECT CADASTRAR('parcela', 'DEFAULT, 8, 1, 24.00, ''2025-07-16'', ''2025-07-15'', ''PAGO'''); -- Lavagem 8, Parcela 1
SELECT CADASTRAR('parcela', 'DEFAULT, 9, 1, 180.00, ''2025-07-28'', NULL, ''PENDENTE'''); -- Lavagem 9, Parcela 1
SELECT CADASTRAR('parcela', 'DEFAULT, 10, 1, 40.00, ''2025-07-19'', ''2025-07-18'', ''PAGO'''); -- Lavagem 10, Parcela 1

-- Inserção na tabela lavagem_produto (Uso de produtos nas lavagens)
SELECT CADASTRAR('lavagem_produto', '1, 1, 0.05'); -- Lavagem 1 usou Sabão Líquido
SELECT CADASTRAR('lavagem_produto', '1, 2, 0.03'); -- Lavagem 1 usou Amaciante Perfumado
SELECT CADASTRAR('lavagem_produto', '2, 3, 0.01'); -- Lavagem 2 usou Alvejante Oxy
SELECT CADASTRAR('lavagem_produto', '3, 1, 0.10'); -- Lavagem 3 usou Sabão Líquido
SELECT CADASTRAR('lavagem_produto', '4, 1, 0.08'); -- Lavagem 4 usou Sabão Líquido
SELECT CADASTRAR('lavagem_produto', '5, 4, 0.02'); -- Lavagem 5 usou Tira Manchas
SELECT CADASTRAR('lavagem_produto', '6, 1, 0.12'); -- Lavagem 6 usou Sabão Líquido
SELECT CADASTRAR('lavagem_produto', '7, 2, 0.04'); -- Lavagem 7 usou Amaciante Perfumado
SELECT CADASTRAR('lavagem_produto', '8, 7, 0.15'); -- Lavagem 8 usou Detergente Limpeza Geral
SELECT CADASTRAR('lavagem_produto', '9, 1, 0.20'); -- Lavagem 9 usou Sabão Líquido
SELECT CADASTRAR('lavagem_produto', '10, 2, 0.06'); -- Lavagem 10 usou Amaciante Perfumado

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

SELECT deletar('auditoria_log');
ALTER SEQUENCE auditoria_log_id_log_seq RESTART WITH 1;