-- Codigo para funções das tabelas --

-- Função para cadastrar dados dentro de qualquer tabela --
CREATE OR REPLACE FUNCTION CADASTRAR(
	P_NOME_TABELA TEXT,
	P_VALORES_PARA_INSERIR TEXT
)
RETURNS VOID
AS $$
BEGIN
	EXECUTE 'INSERT INTO' || P_NOME_TABELA || 'VALUES (' || P_VALORES_PARA_INSERIR || ')';

	RAISE NOTICE 'Dados inseridos corretamente na tabela %' , P_NOME_TABELA;

EXCEPTION
	WHEN OTHERS THEN
		RAISE EXCEPTION 'Erro ao inserir dados na tabela %', P_NOME_TABELA;
END;
$$
LANGUAGE PLPGSQL;

-- Função para deletar todos os dados dentro de qualquer tabela --
CREATE OR REPLACE FUNCTION DELETAR(
    P_NOME_TABELA TEXT,
    P_CONDICIONAL_DELETAR TEXT DEFAULT NULL
)
RETURNS VOID
AS $$
BEGIN
    IF (P_CONDICIONAL_DELETAR IS NULL) THEN
        -- Deleta todos os dados da tabela
        EXECUTE 'DELETE FROM ' || quote_ident(P_NOME_TABELA);
        
        RAISE NOTICE 'Todos os dados da tabela "%" foram deletados com sucesso.', P_NOME_TABELA;
    ELSE
        -- Deleta dados com base na condição fornecida
        EXECUTE 'DELETE FROM ' || quote_ident(P_NOME_TABELA) || ' WHERE ' || P_CONDICIONAL_DELETAR;
        RAISE NOTICE 'Os dados da tabela "%" com a condição "%" foram deletados com sucesso.', P_NOME_TABELA, P_CONDICIONAL_DELETAR;
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Erro ao deletar dados da tabela "%": %', P_NOME_TABELA, SQLERRM;
END;
$$
LANGUAGE PLPGSQL;

CREATE OR REPLACE FUNCTION ALTERAR (
	P_NOME_TABELA
)

