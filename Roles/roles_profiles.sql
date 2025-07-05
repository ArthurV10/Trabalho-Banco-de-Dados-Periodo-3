

----------------------------------------------------------------------
-- DEFINIÇÃO DAS PERMISSÕES
----------------------------------------------------------------------

-- Permissão de uso geral no schema e para a tabela de auditoria.
GRANT USAGE ON SCHEMA "TrabalhoFinal" TO operacional, balconista, gerente;
GRANT INSERT ON "TrabalhoFinal".auditoria_log TO operacional;
GRANT USAGE, SELECT ON SEQUENCE "TrabalhoFinal".auditoria_log_id_log_seq TO operacional;

-- Permissões para o Perfil "OPERACIONAL"
GRANT SELECT ON "TrabalhoFinal".V_DETALHES_LAVAGENS TO operacional;
GRANT EXECUTE ON FUNCTION "TrabalhoFinal".ATUALIZAR_STATUS_LAVAGEM(INT, VARCHAR) TO operacional;
-- Permissão de UPDATE apenas nas colunas que a função precisa de alterar.
GRANT UPDATE, SELECT ON "TrabalhoFinal".lavagem TO operacional;

-- Permissões para o Perfil "BALCONISTA"
GRANT operacional TO balconista; -- Herda as permissões do perfil operacional.

-- Permissão de leitura (SELECT) apenas nas tabelas e views necessárias.
GRANT SELECT ON "TrabalhoFinal".cliente, "TrabalhoFinal".funcionario, "TrabalhoFinal".tipo_lavagem, "TrabalhoFinal".tipo_pagamento, "TrabalhoFinal".lavagem, "TrabalhoFinal".parcela, "TrabalhoFinal".produto, "TrabalhoFinal".V_ESTOQUE_ATUAL TO balconista;

-- Permissão de escrita apenas na tabela 'cliente'. Outras alterações são feitas por funções.
GRANT INSERT, UPDATE ON "TrabalhoFinal".cliente TO balconista;

-- Permissões para usar as sequences das tabelas onde ele insere dados via funções.
GRANT USAGE, SELECT ON SEQUENCE "TrabalhoFinal".cliente_id_cliente_seq TO balconista;
GRANT USAGE, SELECT ON SEQUENCE "TrabalhoFinal".lavagem_id_lavagem_seq TO balconista;
GRANT USAGE, SELECT ON SEQUENCE "TrabalhoFinal".parcela_id_parcela_seq TO balconista;

-- Permissão para executar as funções de negócio do dia a dia.
GRANT EXECUTE ON FUNCTION "TrabalhoFinal".CADASTRAR_LAVAGEM(VARCHAR, VARCHAR, VARCHAR, VARCHAR, TIMESTAMP, TEXT, DECIMAL, INT) TO balconista;
GRANT EXECUTE ON FUNCTION "TrabalhoFinal".ATUALIZAR_DADOS_CLIENTE(VARCHAR, VARCHAR, VARCHAR, VARCHAR) TO balconista;
GRANT EXECUTE ON FUNCTION "TrabalhoFinal".ADICIONAR_VALOR_EXTRA_LAVAGEM(INT, DECIMAL) TO balconista;
GRANT EXECUTE ON FUNCTION "TrabalhoFinal".REMOVER_VALOR_EXTRA_LAVAGEM(INT, DECIMAL) TO balconista; 
GRANT EXECUTE ON FUNCTION "TrabalhoFinal".REGISTRAR_PAGAMENTO_PARCELA(INT) TO balconista;

-- Permissão para executar todos os relatórios.
GRANT EXECUTE ON FUNCTION "TrabalhoFinal".relatorio_faturamento_periodo(DATE, DATE) TO balconista;
GRANT EXECUTE ON FUNCTION "TrabalhoFinal".relatorio_inadimplencia() TO balconista;
GRANT EXECUTE ON FUNCTION "TrabalhoFinal".relatorio_rentabilidade_por_servico(DATE, DATE) TO balconista;
GRANT EXECUTE ON FUNCTION "TrabalhoFinal".relatorio_ranking_clientes(DATE, DATE) TO balconista;
GRANT EXECUTE ON FUNCTION "TrabalhoFinal".relatorio_clientes_inativos(INT) TO balconista;
GRANT EXECUTE ON FUNCTION "TrabalhoFinal".relatorio_historico_cliente(VARCHAR) TO balconista;

-- Permissões para o Perfil "GERENTE"
GRANT balconista TO gerente; -- Herda todas as permissões do balconista.

-- Concede todos os privilégios restantes para o gerente.
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA "TrabalhoFinal" TO gerente;
ALTER DEFAULT PRIVILEGES IN SCHEMA "TrabalhoFinal" GRANT ALL ON TABLES TO gerente;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA "TrabalhoFinal" TO gerente;
ALTER DEFAULT PRIVILEGES IN SCHEMA "TrabalhoFinal" GRANT ALL ON FUNCTIONS TO gerente;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA "TrabalhoFinal" TO gerente;
ALTER DEFAULT PRIVILEGES IN SCHEMA "TrabalhoFinal" GRANT ALL ON SEQUENCES TO gerente;
	
----------------------------------------------------------------------
-- CRIAÇÃO DE UTILIZADORES E ATRIBUIÇÃO DE PERFIS
----------------------------------------------------------------------

CREATE USER joao WITH PASSWORD '123';
CREATE USER mariana WITH PASSWORD '456';
CREATE USER sofia WITH PASSWORD '789';

-- Atribuindo cada utilizador ao seu perfil de acesso correto (conforme sua solicitação)
GRANT balconista TO joao;    -- João agora é BALCONISTA.
GRANT operacional TO mariana; -- Mariana agora é OPERACIONAL.
GRANT gerente TO sofia;       -- Sofia continua como GERENTE.
