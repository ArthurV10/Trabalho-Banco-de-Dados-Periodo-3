-- Código de Triggers utilizados -- 

-- Trigger para a tabela CLIENTE
CREATE OR REPLACE TRIGGER tr_auditar_cliente
AFTER INSERT OR UPDATE OR DELETE ON CLIENTE
FOR EACH ROW
EXECUTE FUNCTION trg_auditoria_generica();

-- Trigger para a tabela FUNCIONARIO
CREATE OR REPLACE TRIGGER tr_auditar_funcionario
AFTER INSERT OR UPDATE OR DELETE ON FUNCIONARIO
FOR EACH ROW
EXECUTE FUNCTION trg_auditoria_generica();

-- Trigger para a tabela TIPO_LAVAGEM
CREATE OR REPLACE TRIGGER tr_auditar_tipo_lavagem
AFTER INSERT OR UPDATE OR DELETE ON TIPO_LAVAGEM
FOR EACH ROW
EXECUTE FUNCTION trg_auditoria_generica();

-- Trigger para a tabela TIPO_PAGAMENTO
CREATE OR REPLACE TRIGGER tr_auditar_tipo_pagamento
AFTER INSERT OR UPDATE OR DELETE ON TIPO_PAGAMENTO
FOR EACH ROW
EXECUTE FUNCTION trg_auditoria_generica();

-- Trigger para a tabela FORNECEDOR
CREATE OR REPLACE TRIGGER tr_auditar_fornecedor
AFTER INSERT OR UPDATE OR DELETE ON FORNECEDOR
FOR EACH ROW
EXECUTE FUNCTION trg_auditoria_generica();

-- Trigger para a tabela PRODUTO
CREATE OR REPLACE TRIGGER tr_auditar_produto
AFTER INSERT OR UPDATE OR DELETE ON PRODUTO
FOR EACH ROW
EXECUTE FUNCTION trg_auditoria_generica();

-- Trigger para a tabela COMPRA
CREATE OR REPLACE TRIGGER tr_auditar_compra
AFTER INSERT OR UPDATE OR DELETE ON COMPRA
FOR EACH ROW
EXECUTE FUNCTION trg_auditoria_generica();

-- Trigger para a tabela ITEM
CREATE OR REPLACE TRIGGER tr_auditar_item
AFTER INSERT OR UPDATE OR DELETE ON ITEM
FOR EACH ROW
EXECUTE FUNCTION trg_auditoria_generica();

-- Trigger para a tabela LAVAGEM
CREATE OR REPLACE TRIGGER tr_auditar_lavagem
AFTER INSERT OR UPDATE OR DELETE ON LAVAGEM
FOR EACH ROW
EXECUTE FUNCTION trg_auditoria_generica();

-- Trigger para a tabela PARCELA
CREATE OR REPLACE TRIGGER tr_auditar_parcela
AFTER INSERT OR UPDATE OR DELETE ON PARCELA
FOR EACH ROW
EXECUTE FUNCTION trg_auditoria_generica();

-- Trigger para a tabela LAVAGEM_PRODUTO
CREATE OR REPLACE TRIGGER tr_audistar_lavagem_produto
AFTER INSERT OR UPDATE OR DELETE ON LAVAGEM_PRODUTO
FOR EACH ROW
EXECUTE FUNCTION trg_auditoria_generica();

-- Trigger para a tabela Cliente, verificar se CPF ja existe --
CREATE OR REPLACE TRIGGER trg_checar_cpf_unico_cliente
BEFORE INSERT OR UPDATE ON CLIENTE
FOR EACH ROW
EXECUTE FUNCTION CHECAR_CPF_UNICO_CLIENTE();

-- Trigger para a tabela Funcionario, verificar se CPF ja existe --
CREATE OR REPLACE TRIGGER trg_checar_cpf_unico_funcionario
BEFORE INSERT OR UPDATE ON FUNCIONARIO
FOR EACH ROW
EXECUTE FUNCTION CHECAR_CPF_UNICO_FUNCIONARIO();

-- Trigger para a tabela fornecedor, verificar se CNPJ ja existe --
CREATE OR REPLACE TRIGGER trg_checar_cnpj_unico_fornecedor
BEFORE INSERT OR UPDATE ON FORNECEDOR
FOR EACH ROW
EXECUTE FUNCTION CHECAR_CPF_UNICO_FORNECEDOR();

-- Trigger para verificar se os valores são positivos na tabela tipo_lavagem --
CREATE OR REPLACE TRIGGER trg_checar_preco_positivo_tipo_lavagem
BEFORE INSERT OR UPDATE ON TIPO_LAVAGEM
FOR EACH ROW
EXECUTE FUNCTION checar_preco_positivo_tipo_lavagem();

-- Trigger para verificar se os valores do estoque são positivos --
CREATE OR REPLACE TRIGGER trg_verificar_qtd_estoque_positiva_produto
BEFORE INSERT OR UPDATE ON PRODUTO
FOR EACH ROW
EXECUTE FUNCTION verificar_qtd_estoque_positiva_produto();

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
