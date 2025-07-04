-- Código de Triggers utilizados -- 

--------------------|| TRIGGER CLIENTE ||---------------------
--------------------------------------------------------------
--------------------------------------------------------------
-- Trigger para a tabela CLIENTE
CREATE OR REPLACE TRIGGER tr_auditar_cliente
AFTER INSERT OR UPDATE OR DELETE ON CLIENTE
FOR EACH ROW
EXECUTE FUNCTION trg_auditoria_generica();

-- Trigger para a tabela Cliente, verificar se CPF ja existe --
CREATE OR REPLACE TRIGGER trg_checar_cpf_unico_cliente
BEFORE INSERT OR UPDATE ON CLIENTE
FOR EACH ROW
EXECUTE FUNCTION CHECAR_CPF_UNICO_CLIENTE();

-- Trigger para a tabela Cliente, verifica se existe algum numero no nome --
CREATE OR REPLACE TRIGGER tr_nomes_nao_numeros_cliente
BEFORE INSERT OR UPDATE ON CLIENTE
FOR EACH ROW
EXECUTE FUNCTION NOMES_NAO_NUMEROS();
--------------------------------------------------------------
--------------------------------------------------------------
--------------------------------------------------------------










-------------------|| TRIGGER FUNCIONARIO ||------------------
--------------------------------------------------------------
--------------------------------------------------------------
-- Trigger para a tabela FUNCIONARIO
CREATE OR REPLACE TRIGGER tr_auditar_funcionario
AFTER INSERT OR UPDATE OR DELETE ON FUNCIONARIO
FOR EACH ROW
EXECUTE FUNCTION trg_auditoria_generica();

-- Trigger para a tabela Funcionario, verificar se CPF ja existe --
CREATE OR REPLACE TRIGGER trg_checar_cpf_unico_funcionario
BEFORE INSERT OR UPDATE ON FUNCIONARIO
FOR EACH ROW
EXECUTE FUNCTION CHECAR_CPF_UNICO_FUNCIONARIO();

-- Trigger para a tabela Funcionario, verifica se existe algum numero no nome --
CREATE OR REPLACE TRIGGER tr_nomes_nao_numeros_cliente
BEFORE INSERT OR UPDATE ON FUNCIONARIO
FOR EACH ROW
EXECUTE FUNCTION NOMES_NAO_NUMEROS();
--------------------------------------------------------------
--------------------------------------------------------------
--------------------------------------------------------------










------------------|| TRIGGER TIPO LAVAGEM ||------------------
--------------------------------------------------------------
--------------------------------------------------------------
-- Trigger para a tabela TIPO_LAVAGEM
CREATE OR REPLACE TRIGGER tr_auditar_tipo_lavagem
AFTER INSERT OR UPDATE OR DELETE ON TIPO_LAVAGEM
FOR EACH ROW
EXECUTE FUNCTION trg_auditoria_generica();

-- Trigger para verificar se os valores são positivos na tabela tipo_lavagem --
CREATE OR REPLACE TRIGGER trg_checar_preco_positivo_tipo_lavagem
BEFORE INSERT OR UPDATE ON TIPO_LAVAGEM
FOR EACH ROW
EXECUTE FUNCTION checar_preco_positivo_tipo_lavagem();
--------------------------------------------------------------
--------------------------------------------------------------
--------------------------------------------------------------










----------------|| TRIGGER TIPO PAGAMENTO ||------------------
--------------------------------------------------------------
--------------------------------------------------------------
-- Trigger para a tabela TIPO_PAGAMENTO
CREATE OR REPLACE TRIGGER tr_auditar_tipo_pagamento
AFTER INSERT OR UPDATE OR DELETE ON TIPO_PAGAMENTO
FOR EACH ROW
EXECUTE FUNCTION trg_auditoria_generica();
--------------------------------------------------------------
--------------------------------------------------------------
--------------------------------------------------------------










-------------------|| TRIGGER Fornecedor ||-------------------
--------------------------------------------------------------
--------------------------------------------------------------
-- Trigger para a tabela FORNECEDOR
CREATE OR REPLACE TRIGGER tr_auditar_fornecedor
AFTER INSERT OR UPDATE OR DELETE ON FORNECEDOR
FOR EACH ROW
EXECUTE FUNCTION trg_auditoria_generica();

-- Trigger para a tabela fornecedor, verificar se CNPJ ja existe --
CREATE OR REPLACE TRIGGER trg_checar_cnpj_unico_fornecedor
BEFORE INSERT OR UPDATE ON FORNECEDOR
FOR EACH ROW
EXECUTE FUNCTION CHECAR_CNPJ_UNICO_FORNECEDOR();
--------------------------------------------------------------
--------------------------------------------------------------
--------------------------------------------------------------










--------------------|| TRIGGER PRODUTO ||---------------------
--------------------------------------------------------------
--------------------------------------------------------------
-- Trigger para a tabela PRODUTO
CREATE OR REPLACE TRIGGER tr_auditar_produto
AFTER INSERT OR UPDATE OR DELETE ON PRODUTO
FOR EACH ROW
EXECUTE FUNCTION trg_auditoria_generica();

-- Trigger para verificar se os valores do estoque são positivos --
CREATE OR REPLACE TRIGGER trg_verificar_qtd_estoque_positiva_produto
BEFORE INSERT OR UPDATE ON PRODUTO
FOR EACH ROW
EXECUTE FUNCTION verificar_qtd_estoque_positiva_produto();

--------------------------------------------------------------
--------------------------------------------------------------
--------------------------------------------------------------










---------------------|| TRIGGER COMPRA ||---------------------
--------------------------------------------------------------
--------------------------------------------------------------
-- Trigger para a tabela COMPRA
CREATE OR REPLACE TRIGGER tr_auditar_compra
AFTER INSERT OR UPDATE OR DELETE ON COMPRA
FOR EACH ROW
EXECUTE FUNCTION trg_auditoria_generica();

-- Trigger para colocar nulo a FK na tabela compra referente ao fornecedor --
CREATE TRIGGER trg_deletar_forncedor_e_deixar_fk_nulo_compra
BEFORE DELETE ON FORNECEDOR
FOR EACH ROW
EXECUTE FUNCTION DELETAR_FORNECEDOR_E_DEIXAR_FK_NULO_COMPRA();

-- Trigger para limitar os valores do status aos padrões fornecidos -- 
CREATE OR REPLACE TRIGGER trg_limitar_valores_status_compra
BEFORE INSERT OR UPDATE ON COMPRA
FOR EACH ROW
EXECUTE FUNCTION LIMITAR_VALORES_STATUS_COMPRA();

-- Trigger para verificar se o preço não estava negativo --
CREATE OR REPLACE TRIGGER trg_verificar_valor_negativo_compra
BEFORE INSERT OR UPDATE ON COMPRA
FOR EACH ROW
EXECUTE FUNCTION checar_preco_positivo_compra();
--------------------------------------------------------------
--------------------------------------------------------------
--------------------------------------------------------------









---------------------|| TRIGGER LAVAGEM ||--------------------
--------------------------------------------------------------
--------------------------------------------------------------
-- Trigger para a tabela LAVAGEM
CREATE OR REPLACE TRIGGER tr_auditar_lavagem
AFTER INSERT OR UPDATE OR DELETE ON LAVAGEM
FOR EACH ROW
EXECUTE FUNCTION trg_auditoria_generica();

-- Trigger para garantir tempos reais na tabela de Lavagem
CREATE TRIGGER trg_verificar_datas_lavagem
BEFORE INSERT OR UPDATE ON lavagem 
FOR EACH ROW 
EXECUTE FUNCTION verificar_consistencia_datas_lavagem(); 

--------------------------------------------------------------
--------------------------------------------------------------
--------------------------------------------------------------









----------------------|| TRIGGER ITEM ||----------------------
--------------------------------------------------------------
--------------------------------------------------------------
-- Trigger para a tabela ITEM
CREATE OR REPLACE TRIGGER tr_auditar_item
AFTER INSERT OR UPDATE OR DELETE ON ITEM
FOR EACH ROW
EXECUTE FUNCTION trg_auditoria_generica();

-- Trigger para a tabela Item, coloca Fk nula quando compra for deletada --
CREATE OR REPLACE TRIGGER TR_DELETAR_COMPRA_SETAR_NULO_FK_ITEM
AFTER DELETE ON COMPRA
FOR EACH ROW
EXECUTE FUNCTION DELETAR_COMPRA_SETAR_NULO_FK_ITEM();

-- Trigger para a tabela Item, coloca Fk nula quando compra for deletada --
CREATE OR REPLACE TRIGGER TR_DELETAR_COMPRA_SETAR_NULO_FK_ITEM
BEFORE DELETE ON COMPRA
FOR EACH ROW
EXECUTE FUNCTION DELETAR_COMPRA_SETAR_NULO_FK_ITEM();

-- Trigger para a tabela Item, coloca Fk nula quando produto for deletado --
CREATE OR REPLACE TRIGGER TR_DELETAR_PRODUTO_SETAR_NULO_FK_ITEM
BEFORE DELETE ON PRODUTO
FOR EACH ROW
EXECUTE FUNCTION DELETAR_PRODUTO_SETAR_NULO_FK_ITEM();

-- Trigger para verificar se o preço não estava negativo --
CREATE OR REPLACE TRIGGER trg_checar_qtd_positivo_item
BEFORE INSERT OR UPDATE ON ITEM
FOR EACH ROW
EXECUTE FUNCTION checar_qtd_positivo_item();

-- Trigger para verificar se o valor unitario não é negativo --
CREATE OR REPLACE TRIGGER trg_checar_valor_unitario_positivo_item
BEFORE INSERT OR UPDATE ON ITEM
FOR EACH ROW
EXECUTE FUNCTION checar_valor_unitario_positivo_item();

-- Trigger para calcular valor total na tabela item --
CREATE OR REPLACE TRIGGER trg_calcular_valor_total_item
BEFORE INSERT OR UPDATE ON ITEM
FOR EACH ROW
EXECUTE FUNCTION calcular_valor_total_item();
--------------------------------------------------------------
--------------------------------------------------------------
--------------------------------------------------------------









---------------------|| TRIGGER PARCELA ||--------------------
--------------------------------------------------------------
--------------------------------------------------------------
-- Trigger para a tabela PARCELA
CREATE OR REPLACE TRIGGER tr_auditar_parcela
AFTER INSERT OR UPDATE OR DELETE ON PARCELA
FOR EACH ROW
EXECUTE FUNCTION trg_auditoria_generica();

--------------------------------------------------------------
--------------------------------------------------------------
--------------------------------------------------------------









-----------------|| TRIGGER LAVAGEM PRODUTO ||----------------
--------------------------------------------------------------
--------------------------------------------------------------
-- Trigger para a tabela LAVAGEM_PRODUTO
CREATE OR REPLACE TRIGGER tr_audistar_lavagem_produto
AFTER INSERT OR UPDATE OR DELETE ON LAVAGEM_PRODUTO
FOR EACH ROW
EXECUTE FUNCTION trg_auditoria_generica();
--------------------------------------------------------------
--------------------------------------------------------------
--------------------------------------------------------------
