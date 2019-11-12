---------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- ############################################################################################################################################################### --
-- ############################################################################ GRUPOS ########################################################################### --
-- ############################################################################################################################################################### --
---------------------------------------------------------------------------------------------------------------------------------------------------------------------
CREATE GROUP ALUNO;
CREATE GROUP PROFESSOR;

GRANT USAGE ON SCHEMA PUBLIC TO GROUP ALUNO;
GRANT USAGE ON SCHEMA PUBLIC TO GROUP PROFESSOR;

GRANT EXECUTE ON FUNCTION USUARIO_CONSULTAR_SALDO, ATUALIZAR_SALDO, SACAR_SALDO, COMPRAR_CURSO, INSERIR_ALUNO_E_PROFESSOR TO ALUNO;
GRANT EXECUTE ON FUNCTION DELETAR_VIDEO_AULA, DELETAR_DISCIPLINA, DELETAR_MODULO, CRIAR_VIDEO_AULAS, CRIAR_DISCIPLINAS, CRIAR_MODULO, CRIAR_CURSO, PUBLICAR_CURSO, ATUALIZAR_SALDO,
SACAR_SALDO, RECEBER_SALARIO, INSERIR_ALUNO_E_PROFESSOR TO PROFESSOR;

GRANT EXECUTE ON FUNCTION PROFESSOR_DELETAR_CURSO TO PROFESSOR;

GRANT SELECT ON ALUNO TO GROUP ALUNO, PROFESSOR;

GRANT SELECT ON DISCIPLINA, VIDEO_AULA, MODULO, ALUNO_MODULO, CURSO, ALUNO_CURSO TO GROUP ALUNO;

GRANT SELECT ON PROFESSOR TO GROUP PROFESSOR;
GRANT SELECT ON CURSO TO GROUP PROFESSOR;
GRANT UPDATE ON CURSO TO GROUP PROFESSOR;
GRANT DELETE ON CURSO TO GROUP PROFESSOR;

-- SELECT FROM PROFESSOR_DELETAR_CURSO(1);
-- SELECT * FROM PROFESSOR;
-- SELECT * FROM CURSO;

---------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- ############################################################################################################################################################### --
-- ##################################################################### CRIAÇÃO DAS TABELAS ##################################################################### --
-- ############################################################################################################################################################### --
--------------------------------------------------------------------------------------------------------------------------------------------------------------------- 

CREATE TABLE ALUNO
(  
    COD_ALUNO SERIAL NOT NULL PRIMARY KEY,
    NOME VARCHAR(30) NOT NULL,
    CPF VARCHAR(11),
    DATA_NASCIMENTO DATE NOT NULL,
    EMAIL VARCHAR(30) NOT NULL,
    SENHA VARCHAR(30) NOT NULL,
    SALDO FLOAT DEFAULT 0
);

CREATE TABLE PROFESSOR
(  
    COD_PROFESSOR SERIAL NOT NULL PRIMARY KEY,
    NOME VARCHAR(30) NOT NULL,
    CPF VARCHAR(11) NOT NULL,
    DATA_NASCIMENTO DATE NOT NULL,
    EMAIL VARCHAR(30) NOT NULL,
    SENHA VARCHAR(30) NOT NULL,
    SALDO FLOAT DEFAULT 0,
    DATA_ULTIMO_PAGAMENTO DATE DEFAULT NULL
);

CREATE TABLE CURSO
(  
    COD_CURSO SERIAL NOT NULL PRIMARY KEY,
    NOME VARCHAR(60) NOT NULL,
    DESCRICAO VARCHAR(300),
    DURACAO INT DEFAULT 0,
    PRECO FLOAT,
    NUMERO_MODULOS INT DEFAULT 0,
    PUBLICADO BOOLEAN DEFAULT FALSE,
    DISPONIBILIDADE BOOLEAN DEFAULT FALSE,

    COD_PROFESSOR INT NOT NULL REFERENCES PROFESSOR(COD_PROFESSOR) ON DELETE CASCADE
);

CREATE TABLE ALUNO_CURSO
(  
    COD_ALUNO_CURSO SERIAL NOT NULL PRIMARY KEY,
    DATA_COMPRA DATE,
    NOTA_AVALIACAO FLOAT,

    COD_ALUNO INT NOT NULL REFERENCES ALUNO(COD_ALUNO) ON DELETE CASCADE,
    COD_CURSO INT NOT NULL REFERENCES CURSO(COD_CURSO) ON DELETE CASCADE
);

CREATE TABLE MODULO
(  
    COD_MODULO SERIAL NOT NULL PRIMARY KEY,
    NOME VARCHAR(100),
    DESCRICAO VARCHAR(300),
    DURACAO INT,

    COD_CURSO INT NOT NULL REFERENCES CURSO(COD_CURSO) ON DELETE CASCADE
);

CREATE TABLE ALUNO_MODULO
(
    COD_ALUNO_MODULO SERIAL NOT NULL PRIMARY KEY,
    ACESSIVEL BOOLEAN,
    META_CONCLUIDA BOOLEAN,

    COD_ALUNO INT NOT NULL REFERENCES ALUNO(COD_ALUNO) ON DELETE CASCADE,
    COD_MODULO INT NOT NULL REFERENCES MODULO(COD_MODULO) ON DELETE CASCADE
);

CREATE TABLE PRE_REQUISITO
(  
    COD_PRE_REQUISITO SERIAL NOT NULL PRIMARY KEY,

    COD_MODULO INT NOT NULL REFERENCES MODULO(COD_MODULO) ON DELETE CASCADE,
    COD_MODULO_PRE_REQUISITO INT NOT NULL REFERENCES MODULO(COD_MODULO) ON DELETE CASCADE,

    UNIQUE (COD_PRE_REQUISITO, COD_MODULO) -- PAR DE VALORES ÚNICOS (1, 2), (2, 1), PORÉM (1, 2) NOVAMENTE NÃO PODE.
);

CREATE TABLE DISCIPLINA
(  
    COD_DISCIPLINA SERIAL NOT NULL PRIMARY KEY,
    NOME VARCHAR(100),
    DESCRICAO VARCHAR(300),

    COD_MODULO INT NOT NULL REFERENCES MODULO(COD_MODULO) ON DELETE CASCADE
);

CREATE TABLE VIDEO_AULA
(  
    COD_VIDEO_AULA SERIAL PRIMARY KEY,
    NOME VARCHAR(30) NOT NULL,
    DESCRICAO VARCHAR(300),
    DURACAO FLOAT,

    COD_DISCIPLINA INT NOT NULL REFERENCES DISCIPLINA(COD_DISCIPLINA) ON DELETE CASCADE
);

CREATE TABLE ALUNO_VIDEOS_ASSISTIDOS
(  
    COD_ALUNO_VIDEO_ASSISTIDO SERIAL NOT NULL PRIMARY KEY,

    COD_ALUNO INT NOT NULL REFERENCES ALUNO(COD_ALUNO) ON DELETE CASCADE,
    COD_VIDEO_AULA INT NOT NULL REFERENCES VIDEO_AULA(COD_VIDEO_AULA) ON DELETE CASCADE
);

CREATE TABLE QUESTAO
(  
    COD_QUESTAO SERIAL NOT NULL PRIMARY KEY,
    TEXTO VARCHAR(500),

    COD_DISCIPLINA INT NOT NULL REFERENCES DISCIPLINA(COD_DISCIPLINA) ON DELETE CASCADE
);

CREATE TABLE QUESTIONARIO
(  
    COD_QUESTIONARIO SERIAL NOT NULL PRIMARY KEY,
    NOME VARCHAR(30),

    COD_DISCIPLINA INT NOT NULL REFERENCES DISCIPLINA(COD_DISCIPLINA) ON DELETE CASCADE
);

CREATE TABLE QUESTAO_QUESTIONARIO
(  
    COD_QUESTAO_QUESTIONARIO SERIAL NOT NULL PRIMARY KEY,

    COD_QUESTAO INT NOT NULL REFERENCES QUESTAO(COD_QUESTAO) ON DELETE CASCADE,
    COD_QUESTIONARIO INT NOT NULL REFERENCES QUESTIONARIO(COD_QUESTIONARIO) ON DELETE CASCADE
);

CREATE TABLE QUESTAO_ALUNO
(  
    COD_QUESTAO_ALUNO SERIAL NOT NULL PRIMARY KEY,
    RESPOSTA_ALUNO VARCHAR(500),
    RESPOSTA_CORRETA VARCHAR(13) DEFAULT 'NÃO ANALISADA',

    COD_QUESTAO INT NOT NULL REFERENCES QUESTAO(COD_QUESTAO),
    COD_ALUNO INT NOT NULL REFERENCES ALUNO(COD_ALUNO)
);




---------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- ############################################################################################################################################################### --
-- ########################################################################## FUNCTIONS ########################################################################## --
-- ############################################################################################################################################################### --
---------------------------------------------------------------------------------------------------------------------------------------------------------------------


---------------------------------------------------------------------------------------------------------------------------------------------------------------------
                      --        ####################################### FUNCTIONS AUXILIARES ########################################        --
                      -- ################################################################################################################### --
---------------------------------------------------------------------------------------------------------------------------------------------------------------------


--*****************************************************************************************************************************************************************--
----------------------------***************************  << FUNCTIONS AUXILIARES DE FUNCTIONS PRINCIPAIS >>  ****************************----------------------------
--*****************************************************************************************************************************************************************--


--|-------------------------------------------------------------------------------------------------|--
--|--- ############################### RETORNAR_TABELA_DO_USUARIO ############################## ---|----------------------------------------------------------------
--|-------------------------------------------------------------------------------------------------|--

/* RETORNA O CODIGO E A TABELA DO USUARIO ATUAL */
CREATE OR REPLACE FUNCTION RETORNAR_TABELA_DO_USUARIO()
RETURNS VARCHAR(13)
AS $$
BEGIN
	IF CURRENT_USER IN (SELECT EMAIL FROM ALUNO) THEN
		RETURN 'ALUNO';
	ELSIF CURRENT_USER IN (SELECT EMAIL FROM PROFESSOR) THEN
		RETURN 'PROFESSOR';
	ELSE
		RETURN 'SUPER USUARIO';
	END IF;

END
$$ LANGUAGE plpgsql;


--|-------------------------------------------------------------------------------------------------|--
--|--- ############################### RETORNAR_CODIGO_DO_USUARIO ############################## ---|----------------------------------------------------------------
--|-------------------------------------------------------------------------------------------------|--

/* RETORNA O CODIGO E A TABELA DO USUARIO ATUAL */
CREATE OR REPLACE FUNCTION RETORNAR_CODIGO_DO_USUARIO(TABELA TEXT)
RETURNS INT
AS $$
DECLARE
	CODIGO INT;
BEGIN
	IF TABELA = 'ALUNO' THEN
		SELECT COD_ALUNO INTO CODIGO FROM ALUNO WHERE EMAIL = CURRENT_USER;
		RETURN CODIGO;
	ELSIF TABELA = 'PROFESSOR' THEN
		SELECT COD_PROFESSOR INTO CODIGO FROM PROFESSOR WHERE EMAIL = CURRENT_USER;
		RETURN CODIGO;
	END IF;

END
$$ LANGUAGE plpgsql;


--|-------------------------------------------------------------------------------------------------|--
--|--- ####################### VERIFICAR_PERMISSAO_DA_TABELA_DO_USUARIO ######################## ---|----------------------------------------------------------------
--|-------------------------------------------------------------------------------------------------|--
CREATE OR REPLACE FUNCTION VERIFICAR_PERMISSAO_DA_TABELA_DO_USUARIO(TABELA_DO_USUARIO_REQUERIDA TEXT)
RETURNS VOID
AS $$
DECLARE
	TABELA_DO_USUARIO VARCHAR(13) := RETORNAR_TABELA_DO_USUARIO();
BEGIN
	IF TABELA_DO_USUARIO_REQUERIDA = 'ALUNO_OU_PROFESSOR' THEN
		 IF TABELA_DO_USUARIO = 'SUPER USUARIO' THEN
			RAISE EXCEPTION 'É OBRIGATÓRIO ESTAR LOGADO COMO ALUNO OU COMO PROFESSOR PARA EXECUTAR ESSA FUNÇÃO!';
		 END IF;
	ELSE
		IF TABELA_DO_USUARIO_REQUERIDA != TABELA_DO_USUARIO THEN
			IF TABELA_DO_USUARIO_REQUERIDA = 'ALUNO' THEN
				RAISE EXCEPTION 'É OBRIGATÓRIO ESTAR LOGADO COMO ALUNO PARA EXECUTAR ESSA FUNÇÃO!';
			ELSIF TABELA_DO_USUARIO_REQUERIDA = 'PROFESSOR' THEN
				RAISE EXCEPTION 'É OBRIGATÓRIO ESTAR LOGADO COMO PROFESSOR PARA EXECUTAR ESSA FUNÇÃO!';
			ELSE
				RAISE EXCEPTION 'A TABELA_DO_USUARIO_REQUERIDA SÓ PODE SER ALUNO, PROFESSOR OU ALUNO_OU_PROFESSOR!';
			END IF;
		END IF;
	END IF;
END
$$ LANGUAGE plpgsql;


--|-------------------------------------------------------------------------------------------------|--
--|--- ############################# CALCULAR_DATA_PAGAMENTO_ATUAL ############################# ---|----------------------------------------------------------------
--|-------------------------------------------------------------------------------------------------|--

/* CALCULA A DATA_ULTIMO_PAGAMENTO DO PAGAMENTO MAIS RECENTE NO DIA 01 */
CREATE OR REPLACE FUNCTION CALCULAR_DATA_PAGAMENTO_ATUAL()
RETURNS DATE
AS $$
DECLARE
	MES_DATA_PAGAMENTO_ATUAL INT;
	ANO_DATA_PAGAMENTO_ATUAL INT;
	DATA_PAGAMENTO_ATUAL DATE;
BEGIN
	MES_DATA_PAGAMENTO_ATUAL := EXTRACT(MONTH FROM DATE(NOW()));
	ANO_DATA_PAGAMENTO_ATUAL := EXTRACT(YEAR FROM DATE(NOW()));
 
	DATA_PAGAMENTO_ATUAL := CAST(CAST(ANO_DATA_PAGAMENTO_ATUAL AS VARCHAR(4)) || '-' || CAST(MES_DATA_PAGAMENTO_ATUAL AS VARCHAR(2)) || '-01' AS DATE);
	RETURN DATA_PAGAMENTO_ATUAL;
END
$$ LANGUAGE plpgsql;


--|-------------------------------------------------------------------------------------------------|--
--|--- ############################## VERIFICAR_SE_REGISTRO_EXISTE ############################# ---|----------------------------------------------------------------
--|-------------------------------------------------------------------------------------------------|--

/* VERIFICA SE EXISTE ALGUM REGISTRO DE DETERMINADA TABELA */
CREATE OR REPLACE FUNCTION VERIFICAR_SE_REGISTRO_EXISTE(COD_ANALISADO INT, TABELA TEXT)
RETURNS BOOLEAN
AS $$
DECLARE
    REGISTRO RECORD;
BEGIN
	IF TABELA = 'ALUNO' THEN
		SELECT * INTO REGISTRO FROM ALUNO WHERE COD_ALUNO = COD_ANALISADO;
		IF REGISTRO IS NOT NULL THEN
			RETURN TRUE;
		ELSE
			RETURN FALSE;
		END IF;

	ELSIF TABELA = 'PROFESSOR' THEN
		SELECT * INTO REGISTRO FROM PROFESSOR WHERE COD_PROFESSOR = COD_ANALISADO;
		IF REGISTRO IS NOT NULL THEN
			RETURN TRUE;
		ELSE
			RETURN FALSE;
		END IF;

	ELSIF TABELA = 'CURSO' THEN
		SELECT * INTO REGISTRO FROM CURSO WHERE COD_CURSO = COD_ANALISADO;
		IF REGISTRO IS NOT NULL THEN
			RETURN TRUE;
		ELSE
			RETURN FALSE;
		END IF;

	ELSIF TABELA = 'MODULO' THEN
		SELECT * INTO REGISTRO FROM MODULO WHERE COD_MODULO = COD_ANALISADO;
		IF  REGISTRO IS NOT NULL THEN
			RETURN TRUE;
		ELSE
			RETURN FALSE;
		END IF;

	ELSIF TABELA = 'DISCIPLINA' THEN
		SELECT * INTO REGISTRO FROM DISCIPLINA WHERE COD_DISCIPLINA = COD_ANALISADO;
		IF REGISTRO IS NOT NULL THEN
			RETURN TRUE;
		ELSE
			RETURN FALSE;
		END IF;

	ELSIF TABELA = 'VIDEO_AULA' THEN
		SELECT * INTO REGISTRO FROM VIDEO_AULA WHERE COD_VIDEO_AULA = COD_ANALISADO;
		IF REGISTRO IS NOT NULL THEN
			RETURN TRUE;
		ELSE
			RETURN FALSE;
		END IF;

	ELSIF TABELA = 'QUESTAO' THEN
		SELECT * INTO REGISTRO FROM QUESTAO WHERE COD_QUESTAO = COD_ANALISADO;
		IF REGISTRO IS NOT NULL THEN
			RETURN TRUE;
		ELSE
			RETURN FALSE;
		END IF;

	ELSIF TABELA = 'QUESTIONARIO' THEN
		SELECT * INTO REGISTRO FROM QUESTIONARIO WHERE COD_QUESTIONARIO = COD_ANALISADO;
		IF REGISTRO IS NOT NULL THEN
			RETURN TRUE;
		ELSE
			RETURN FALSE;
		END IF;

	ELSIF TABELA = 'QUESTAO_ALUNO' THEN
		SELECT * INTO REGISTRO FROM QUESTAO_ALUNO WHERE COD_QUESTAO_ALUNO = COD_ANALISADO;
		IF REGISTRO IS NOT NULL THEN
			RETURN TRUE;
		ELSE
			RETURN FALSE;
		END IF;
	END IF;
    
END
$$ LANGUAGE plpgsql;

--|-------------------------------------------------------------------------------------------------|--
--|--- ############################# VERIFICAR_PERMISSAO_DO_USUARIO ############################ ---|----------------------------------------------------------------
--|-------------------------------------------------------------------------------------------------|--

CREATE OR REPLACE FUNCTION VERIFICAR_PERMISSAO_DO_USUARIO(CODIGO_TABELA_VERIFICADA INT, TABELA TEXT)
RETURNS BOOLEAN
AS $$
DECLARE
	TABELA_DO_USUARIO VARCHAR(13);
	CODIGO_USUARIO_VERIFICADO INT;
	EMAIL_USUARIO_VERIFICADO TEXT;
BEGIN
	TABELA_DO_USUARIO := RETORNAR_TABELA_DO_USUARIO();
	IF TABELA = 'CURSO' THEN
		IF VERIFICAR_SE_REGISTRO_EXISTE(CODIGO_TABELA_VERIFICADA, 'CURSO') IS FALSE THEN
			RAISE EXCEPTION 'ESSE CURSO NÃO EXISTE, INSIRA UM COD_CURSO VALIDO!';

		ELSIF TABELA_DO_USUARIO = 'SUPER USUARIO' THEN
			RAISE EXCEPTION 'ESSA FUNÇÃO NÃO DEVE SER EXECUTADA POR UM SUPER USUARIO!';

		ELSIF TABELA_DO_USUARIO = 'PROFESSOR' THEN
			SELECT COD_PROFESSOR INTO CODIGO_USUARIO_VERIFICADO FROM CURSO WHERE COD_CURSO = CODIGO_TABELA_VERIFICADA;
			SELECT EMAIL INTO EMAIL_USUARIO_VERIFICADO FROM PROFESSOR WHERE COD_PROFESSOR = CODIGO_USUARIO_VERIFICADO;

			IF EMAIL_USUARIO_VERIFICADO = CURRENT_USER THEN
				RETURN TRUE;
			ELSE
				RETURN FALSE;
			END IF;
		END IF;
		
	ELSIF TABELA = 'MODULO' THEN
		IF VERIFICAR_SE_REGISTRO_EXISTE(CODIGO_TABELA_VERIFICADA, 'MODULO') IS FALSE THEN
			RAISE EXCEPTION 'ESSE MÓDULO NÃO EXISTE, INSIRA UM COD_MODULO VALIDO!';

		ELSIF TABELA_DO_USUARIO = 'SUPER USUARIO' THEN
			RAISE EXCEPTION 'ESSA FUNÇÃO NÃO DEVE SER EXECUTADA POR UM SUPER USUARIO!';

		ELSIF TABELA_DO_USUARIO = 'PROFESSOR' THEN
			SELECT COD_PROFESSOR INTO CODIGO_USUARIO_VERIFICADO FROM CURSO
			WHERE COD_CURSO = (SELECT COD_CURSO FROM MODULO WHERE COD_MODULO = CODIGO_TABELA_VERIFICADA);
			
			SELECT EMAIL INTO EMAIL_USUARIO_VERIFICADO FROM PROFESSOR WHERE COD_PROFESSOR = CODIGO_USUARIO_VERIFICADO;

			IF EMAIL_USUARIO_VERIFICADO = CURRENT_USER THEN
				RETURN TRUE;
			ELSE
				RETURN FALSE;
			END IF;
		END IF;

	ELSIF TABELA = 'DISCIPLINA' THEN
		IF VERIFICAR_SE_REGISTRO_EXISTE(CODIGO_TABELA_VERIFICADA, 'DISCIPLINA') IS FALSE THEN
			RAISE EXCEPTION 'ESSA DISCIPLINA NÃO EXISTE, INSIRA UM COD_DISCIPLINA VALIDO!';

		ELSIF TABELA_DO_USUARIO = 'SUPER USUARIO' THEN
			RAISE EXCEPTION 'ESSA FUNÇÃO NÃO DEVE SER EXECUTADA POR UM SUPER USUARIO!';

		ELSIF TABELA_DO_USUARIO = 'PROFESSOR' THEN
			SELECT COD_PROFESSOR INTO CODIGO_USUARIO_VERIFICADO FROM CURSO
				WHERE COD_CURSO = (SELECT COD_CURSO FROM MODULO WHERE COD_MODULO =
				(SELECT COD_MODULO FROM DISCIPLINA WHERE COD_DISCIPLINA = CODIGO_TABELA_VERIFICADA));
			
			SELECT EMAIL INTO EMAIL_USUARIO_VERIFICADO FROM PROFESSOR WHERE COD_PROFESSOR = CODIGO_USUARIO_VERIFICADO;

			IF EMAIL_USUARIO_VERIFICADO = CURRENT_USER THEN
				RETURN TRUE;
			ELSE
				RETURN FALSE;
			END IF;
		END IF;
	
	ELSIF TABELA = 'VIDEO_AULA' THEN
		IF VERIFICAR_SE_REGISTRO_EXISTE(CODIGO_TABELA_VERIFICADA, 'VIDEO_AULA') IS FALSE THEN
			RAISE EXCEPTION 'ESSA VIDEO_AULA NÃO EXISTE, INSIRA UM COD_VIDEO_AULA VALIDO!';

		ELSIF TABELA_DO_USUARIO = 'ALUNO' THEN
			IF (SELECT ACESSIVEL FROM ALUNO_MODULO WHERE COD_ALUNO = (SELECT COD_ALUNO
			WHERE EMAIL = CURRENT_USER) AND COD_MODULO = (SELECT COD_MODULO FROM DISCIPLINA
			WHERE COD_DISCIPLINA = (SELECT COD_DISCIPLINA FROM VIDEO_AULA WHERE COD_VIDEO_AULA =
			CODIGO_TABELA_VERIFICADA))::BOOLEAN) = TRUE THEN
				RETURN TRUE;
			ELSE
				RETURN FALSE;
			END IF;

		ELSIF TABELA_DO_USUARIO = 'PROFESSOR' THEN
			SELECT COD_PROFESSOR INTO CODIGO_USUARIO_VERIFICADO FROM CURSO
			WHERE COD_CURSO = (SELECT COD_CURSO FROM MODULO WHERE COD_MODULO =
			(SELECT COD_MODULO FROM DISCIPLINA WHERE COD_DISCIPLINA =
			(SELECT COD_DISCIPLINA FROM VIDEO_AULA WHERE COD_VIDEO_AULA = CODIGO_TABELA_VERIFICADA)));
			
			SELECT EMAIL INTO EMAIL_USUARIO_VERIFICADO FROM PROFESSOR WHERE COD_PROFESSOR = CODIGO_USUARIO_VERIFICADO;

			IF EMAIL_USUARIO_VERIFICADO = CURRENT_USER THEN
				RETURN TRUE;
			ELSE
				RETURN FALSE;
			END IF;

		ELSE
			RAISE EXCEPTION 'ESSA FUNÇÃO NÃO DEVE SER EXECUTADA POR UM SUPER USUARIO!';
		END IF;
	ELSE
		RAISE EXCEPTION 'TABELA INVÁLIDA!';
	END IF;
END
$$ LANGUAGE plpgsql;

--|-------------------------------------------------------------------------------------------------|--
--|--- ################################## ALUNO_AINDA_CURSANDO ################################# ---|----------------------------------------------------------------
--|-------------------------------------------------------------------------------------------------|--

---------------------------------------------------------------------------------------------------------------------------------------------------------------------
/* VERIFICA SE ALUNO AINDA ESTÁ CURSANDO */
CREATE OR REPLACE FUNCTION ALUNO_AINDA_CURSANDO(COD_ALUNO_ANALISADO INT, COD_CURSO_ANALISADO INT)
RETURNS BOOLEAN
AS $$
BEGIN
    IF VERIFICAR_VINCULO_ALUNO_CURSO(COD_ALUNO_ANALISADO, COD_CURSO_ANALISADO) IS TRUE
    AND PERIODO_CURSANDO_VALIDO(COD_ALUNO_ANALISADO, COD_CURSO_ANALISADO) IS TRUE THEN
        RETURN TRUE;

    ELSE
        RETURN FALSE;
    END IF;
END
$$ LANGUAGE plpgsql;

--|-------------------------------------------------------------------------------------------------|--
--|--- #################################### CURSO_DISPONIVEL ################################### ---|----------------------------------------------------------------
--|-------------------------------------------------------------------------------------------------|--

/* VERIFICA SE CURSO ESTÁ DISPONIVEL */
CREATE OR REPLACE FUNCTION CURSO_DISPONIVEL(COD_CURSO_ANALISADO INT)
RETURNS BOOLEAN
AS $$
DECLARE
    DISPONIBILIDADE_CURSO_ANALISADO BOOLEAN;
BEGIN
    SELECT DISPONIBILIDADE INTO DISPONIBILIDADE_CURSO_ANALISADO FROM CURSO WHERE COD_CURSO = COD_CURSO_ANALISADO;
    RETURN DISPONIBILIDADE_CURSO_ANALISADO;
END
$$ LANGUAGE plpgsql;

--|-------------------------------------------------------------------------------------------------|--
--|--- ############################# VERIFICAR_VINCULO_ALUNO_CURSO ############################# ---|----------------------------------------------------------------
--|-------------------------------------------------------------------------------------------------|--

---------------------------------------------------------------------------------------------------------------------------------------------------------------------
/* VERIFICA SE DETERMINADO CURSO E ALUNO JÁ ESTÃO FORMANDO UMA LINHA NA TABELA ALUNO_CURSO */
CREATE OR REPLACE FUNCTION VERIFICAR_VINCULO_ALUNO_CURSO(COD_ALUNO_ANALISADO INT, COD_CURSO_ANALISADO INT)
RETURNS BOOLEAN
AS $$
DECLARE
    ALUNO_CURSO_ANALISADO RECORD;
BEGIN
    SELECT * INTO ALUNO_CURSO_ANALISADO FROM ALUNO_CURSO WHERE COD_ALUNO_ANALISADO = COD_ALUNO AND COD_CURSO_ANALISADO = COD_CURSO;
 
    IF ALUNO_CURSO_ANALISADO IS NULL THEN
        RETURN FALSE;
    ELSE
        RETURN TRUE;
    END IF;
END
$$ LANGUAGE plpgsql;

--|-------------------------------------------------------------------------------------------------|--
--|--- ################################ PERIODO_CURSANDO_VALIDO ################################ ---|----------------------------------------------------------------
--|-------------------------------------------------------------------------------------------------|--

---------------------------------------------------------------------------------------------------------------------------------------------------------------------
/* VERIFICA SE AINDA É VÁLIDO O PERÍODO NESSE CURSO */
CREATE OR REPLACE FUNCTION PERIODO_CURSANDO_VALIDO(COD_ALUNO_ANALISADO INT, COD_CURSO_ANALISADO INT)
RETURNS BOOLEAN
AS $$
DECLARE
    DATA_COMPRA_ALUNO_CURSO_ANALISADA DATE;
    DURACAO_CURSO_ANALISADA INT;
BEGIN
    SELECT DATA_COMPRA INTO DATA_COMPRA_ALUNO_CURSO_ANALISADA FROM ALUNO_CURSO WHERE COD_ALUNO_ANALISADO = COD_ALUNO AND COD_CURSO_ANALISADO = COD_CURSO;
    SELECT DURACAO INTO DURACAO_CURSO_ANALISADA FROM CURSO WHERE COD_CURSO_ANALISADO = COD_CURSO;
   
    IF DATA_COMPRA_ALUNO_CURSO_ANALISADA + DURACAO_CURSO_ANALISADA >= DATE(NOW()) THEN  -- <<<<<<<<<<<<<<<<<<<<<<<  OBS: DEIXAR DURACAO COMO INT  <<<<<<<<<<<<<<<<<<<<<<<<<<<<
        RETURN TRUE;
    ELSE
        RETURN FALSE;
    END IF;
END
$$ LANGUAGE plpgsql;

--|-------------------------------------------------------------------------------------------------|--
--|--- #################################### ALUNO_JA_CURSOU #################################### ---|----------------------------------------------------------------
--|-------------------------------------------------------------------------------------------------|--

/* VERIFICA SE ALUNO JÁ CURSOU (E NÃO CURSA MAIS) O CURSO. */
CREATE OR REPLACE FUNCTION ALUNO_JA_CURSOU(COD_ALUNO_ANALISADO INT, COD_CURSO_ANALISADO INT)
RETURNS BOOLEAN
AS $$
BEGIN
    IF VERIFICAR_VINCULO_ALUNO_CURSO(COD_ALUNO_ANALISADO, COD_CURSO_ANALISADO) = TRUE AND PERIODO_CURSANDO_VALIDO(COD_ALUNO_ANALISADO, COD_CURSO_ANALISADO) != TRUE THEN
        RETURN TRUE;
    ELSE
        RETURN FALSE;
    END IF;
END
$$ LANGUAGE plpgsql;

--|-------------------------------------------------------------------------------------------------|--
--|--- #################################### SELECIONAR_PRECO ################################### ---|----------------------------------------------------------------
--|-------------------------------------------------------------------------------------------------|--

---------------------------------------------------------------------------------------------------------------------------------------------------------------------
/* SELECIONA O PRECO DO CURSO*/
CREATE OR REPLACE FUNCTION SELECIONAR_PRECO(COD_CURSO_ANALISADO INT)
RETURNS FLOAT
AS $$
DECLARE
    PRECO_SELECIONADO FLOAT;
BEGIN
    SELECT PRECO INTO PRECO_SELECIONADO FROM CURSO WHERE COD_CURSO_ANALISADO = COD_CURSO;
    RETURN PRECO_SELECIONADO;
END
$$ LANGUAGE plpgsql;

--|-------------------------------------------------------------------------------------------------|--
--|--- ################################### USUARIO_EXISTENTE ################################### ---|----------------------------------------------------------------
--|-------------------------------------------------------------------------------------------------|--

-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
/* USUARIO EXISTENTE NO BD DEPENDENDO DA TABELA */
CREATE OR REPLACE FUNCTION USUARIO_EXISTENTE(CPF_USUARIO TEXT, TABELA TEXT)
RETURNS TABLE (CPF VARCHAR(11))
AS $$
BEGIN
    IF TABELA = 'ALUNO' THEN
        RETURN QUERY SELECT A_L.CPF FROM ALUNO A_L WHERE A_L.CPF = CPF_USUARIO;
    END IF;
   
    IF TABELA = 'PROFESSOR' THEN
        RETURN QUERY SELECT P_F.CPF FROM PROFESSOR P_F WHERE P_F.CPF = CPF_USUARIO;
    END IF;
END
$$ LANGUAGE plpgsql;

--|-------------------------------------------------------------------------------------------------|--
--|--- ###################################### CURSO_EXISTE ##################################### ---|----------------------------------------------------------------
--|-------------------------------------------------------------------------------------------------|--

-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
/* CURSO EXISTENTE */
CREATE OR REPLACE FUNCTION CURSO_EXISTE(CODIGO_CURSO INT)
RETURNS INT
AS $$
DECLARE
    CURSO_EXISTE INT;
BEGIN
    SELECT C_R.COD_CURSO INTO CURSO_EXISTE FROM CURSO C_R WHERE C_R.COD_CURSO = CODIGO_CURSO;
   
    IF CURSO_EXISTE IS NOT NULL THEN
        RETURN CURSO_EXISTE;
       
    ELSE
        RAISE EXCEPTION 'ESSE CURSO NÃO EXISTE! INFORME O CODIGO DE UM CURSO EXISTENTE...';
    END IF;
END
$$ LANGUAGE plpgsql;

--|-------------------------------------------------------------------------------------------------|--
--|--- ##################################### MODULO_EXISTE ##################################### ---|----------------------------------------------------------------
--|-------------------------------------------------------------------------------------------------|--

-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< 
/* MODULO EXISTENTE */    -- RETORNA O COD_CURSO SE O MODULO EXISTIR
CREATE OR REPLACE FUNCTION MODULO_EXISTE(CODIGO_MODULO INT)
RETURNS INT
AS $$
DECLARE
    MODULO_EXISTE INT := (SELECT C_S.COD_CURSO FROM CURSO C_S INNER JOIN MODULO M_D ON
			  C_S.COD_CURSO = M_D.COD_CURSO WHERE M_D.COD_MODULO = CODIGO_MODULO);
BEGIN
 
    IF MODULO_EXISTE IS NOT NULL THEN
        RETURN MODULO_EXISTE;
    ELSE
        RAISE EXCEPTION 'ESSE MODULO NÃO EXISTE PARA ESSE CURSO! INFORME O CODIGO DE UM MODULO EXISTENTE...';
    END IF;
   
END
$$ LANGUAGE plpgsql;

--|-------------------------------------------------------------------------------------------------|--
--|--- ################################## DISCIPLINA_EXISTENTE ################################# ---|----------------------------------------------------------------
--|-------------------------------------------------------------------------------------------------|--

---------------------------------------------------------------------------------------------------------------------------------------------------------------------
/* DISCIPLINA EXISTENTE */
CREATE OR REPLACE FUNCTION DISCIPLINA_EXISTENTE(CODIGO_DISCIPLINA INT)
RETURNS INT
AS $$
DECLARE
    DISCIPLINA_EXISTE INT := (SELECT D_C.COD_DISCIPLINA FROM DISCIPLINA D_C WHERE D_C.COD_DISCIPLINA = CODIGO_DISCIPLINA);
BEGIN
    IF DISCIPLINA_EXISTE IS NOT NULL THEN
        RETURN DISCIPLINA_EXISTE;
    ELSE
        RAISE EXCEPTION 'ESSA DISCIPLINA NÃO EXISTE! INFORME O CODIGO DE UMA DISCIPLINA EXISTENTE...';
    END IF;
END
$$ LANGUAGE plpgsql; 


--|-------------------------------------------------------------------------------------------------|--
--|--- ################################### ALUNO_JA_ASSISTIU ################################### ---|----------------------------------------------------------------
--|-------------------------------------------------------------------------------------------------|--

/* VERIFICA SE ALUNO JÁ ASSISTIU AO VIDEO */
CREATE OR REPLACE FUNCTION ALUNO_JA_ASSISTIU(CODIGO_ALUNO TEXT, CODIGO_VIDEO_AULA INT)
RETURNS BOOLEAN
AS $$
DECLARE
	REGISTRO_VIDEO_AULA RECORD;
BEGIN
	FOR REGISTRO_VIDEO_AULA IN (SELECT * FROM ALUNO_VIDEOS_ASSISTIDOS) LOOP
		IF REGISTRO_VIDEO_AULA.COD_VIDEO_AULA = CODIGO_VIDEO_AULA AND REGISTRO_VIDEO_AULA.COD_ALUNO = CODIGO_ALUNO THEN
			RETURN TRUE;
		END IF;
	END LOOP;

	RETURN FALSE;
END
$$ LANGUAGE plpgsql;

--|-------------------------------------------------------------------------------------------------|--
--|--- ######################## VERIFICAR_VINCULO_QUESTAO_QUESTIONARIO ######################### ---|----------------------------------------------------------------
--|-------------------------------------------------------------------------------------------------|--

/* VERIFICA SE DETERMINADA QUESTÃO E QUESTIONÁRIO JÁ ESTÃO FORMANDO UMA LINHA NA TABELA QUESTAO_QUESTIONARIO */
CREATE OR REPLACE FUNCTION VERIFICAR_VINCULO_QUESTAO_QUESTIONARIO(COD_QUESTIONARIO_ANALISADO INT, COD_QUESTAO_ANALISADA INT)
RETURNS BOOLEAN
AS $$
DECLARE
    QUESTAO_QUESTIONARIO_ANALISADO RECORD;
BEGIN
    SELECT * INTO QUESTAO_QUESTIONARIO_ANALISADO FROM QUESTAO_QUESTIONARIO WHERE COD_QUESTIONARIO = COD_QUESTIONARIO_ANALISADO AND COD_QUESTAO = COD_QUESTAO_ANALISADA;
    IF QUESTAO_QUESTIONARIO_ANALISADO IS NULL THEN
        RETURN FALSE;
    ELSE
        RETURN TRUE;
    END IF;
END
$$ LANGUAGE plpgsql;

--|-------------------------------------------------------------------------------------------------|--
--|--- ############################ VERIFICAR_VINCULO_QUESTAO_ALUNO ############################ ---|----------------------------------------------------------------
--|-------------------------------------------------------------------------------------------------|--

---------------------------------------------------------------------------------------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION VERIFICAR_VINCULO_QUESTAO_ALUNO(COD_ALUNO_ANALISADO INT, COD_QUESTAO_ANALISADA INT)
RETURNS BOOLEAN
AS $$
DECLARE
    ALUNO_QUESTAO_ANALISADO RECORD;
BEGIN
    SELECT * INTO ALUNO_QUESTAO_ANALISADO FROM QUESTAO_ALUNO WHERE COD_ALUNO = COD_ALUNO_ANALISADO AND COD_QUESTAO = COD_QUESTAO_ANALISADA;
    IF ALUNO_QUESTAO_ANALISADO IS NULL THEN
        RETURN FALSE;
    ELSE
        RETURN TRUE;
    END IF;
END
$$ LANGUAGE plpgsql; 



--*****************************************************************************************************************************************************************--
----------------------------***************************  << FUNCTIONS AUXILIARES DE FUNCTIONS DE TRIGGERS >>  ***************************----------------------------
--*****************************************************************************************************************************************************************--


--|-------------------------------------------------------------------------------------------------|--
--|--- ##################################### RETORNA_IDADE ##################################### ---|----------------------------------------------------------------
--|-------------------------------------------------------------------------------------------------|--

/* RETORNA IDADE */
CREATE OR REPLACE FUNCTION RETORNA_IDADE(DATA_NASCIMENTO DATE)
RETURNS INT
AS $$
BEGIN
    RETURN EXTRACT(YEAR FROM AGE(DATA_NASCIMENTO));
END
$$ LANGUAGE plpgsql;

--|-------------------------------------------------------------------------------------------------|--
--|--- ################################ EMAIL_USUARIO_EXISTENTE ################################ ---|----------------------------------------------------------------
--|-------------------------------------------------------------------------------------------------|--

/* EMAIL EXISTENTE NO BD DEPENDENDO DA TABELA */
CREATE OR REPLACE FUNCTION EMAIL_USUARIO_EXISTENTE(EMAIL_USUARIO TEXT, TABELA TEXT)
RETURNS TABLE (EMAIL VARCHAR(30))
AS $$
BEGIN
    IF TABELA = 'ALUNO' THEN
        RETURN QUERY SELECT A_L.EMAIL FROM ALUNO A_L WHERE A_L.EMAIL = EMAIL_USUARIO;
    END IF;
   
    IF TABELA = 'PROFESSOR' THEN
        RETURN QUERY SELECT P_F.EMAIL FROM PROFESSOR P_F WHERE P_F.EMAIL = EMAIL_USUARIO;
    END IF;
END
$$ LANGUAGE plpgsql;

--|-------------------------------------------------------------------------------------------------|--
--|--- ################################### VALIDAR_DISCIPLINA ################################## ---|----------------------------------------------------------------
--|-------------------------------------------------------------------------------------------------|--


CREATE OR REPLACE FUNCTION VALIDAR_DISCIPLINA(CODIGO_DISCIPLINA INT)
RETURNS BOOLEAN
AS $$
DECLARE
    NUM_VIDEOS INT := (SELECT COUNT(*) FROM VIDEO_AULA V_A WHERE V_A.COD_DISCIPLINA = CODIGO_DISCIPLINA);
BEGIN
   
    IF NUM_VIDEOS >= 3 THEN
        RETURN TRUE;
    ELSE
        RETURN FALSE;
    END IF;
END
$$ LANGUAGE plpgsql;

--|-------------------------------------------------------------------------------------------------|--
--|--- #################################### VALIDAR_MODULO ##################################### ---|----------------------------------------------------------------
--|-------------------------------------------------------------------------------------------------|--

CREATE OR REPLACE FUNCTION VALIDAR_MODULO(CODIGO_MODULO INT)
RETURNS BOOLEAN
AS $$
DECLARE
    NUM_DISCIPLINAS_VALIDAS INT := 0;
    REGISTRO_DISCIPLINA RECORD;
BEGIN
   
    FOR REGISTRO_DISCIPLINA IN (SELECT * FROM DISCIPLINA D_P WHERE D_P.COD_MODULO = CODIGO_MODULO) LOOP
        IF VALIDAR_DISCIPLINA(REGISTRO_DISCIPLINA.COD_DISCIPLINA) = TRUE THEN
            NUM_DISCIPLINAS_VALIDAS := NUM_DISCIPLINAS_VALIDAS + 1;
        END IF;
    END LOOP;
   
    IF NUM_DISCIPLINAS_VALIDAS >= 3 THEN
        RAISE NOTICE 'TRUE';
        RETURN TRUE;
    ELSE
        RAISE NOTICE 'FALSE';
        RETURN FALSE;
    END IF;
END
$$ LANGUAGE plpgsql;
 
--|-------------------------------------------------------------------------------------------------|--
--|--- ##################################### VALIDAR_CURSO ##################################### ---|----------------------------------------------------------------
--|-------------------------------------------------------------------------------------------------|--

CREATE OR REPLACE FUNCTION VALIDAR_CURSO(CODIGO_CURSO INT)
RETURNS BOOLEAN
AS $$
DECLARE
    NUM_MODULOS_VALIDOS INT := 0;
    REGISTRO_MODULO RECORD;
BEGIN
 
    FOR REGISTRO_MODULO IN (SELECT * FROM MODULO M_D WHERE M_D.COD_CURSO = CODIGO_CURSO) LOOP
        IF VALIDAR_MODULO(REGISTRO_MODULO.COD_MODULO) = TRUE THEN
            NUM_MODULOS_VALIDOS := NUM_MODULOS_VALIDOS + 1;
        END IF;
    END LOOP;
   
    IF NUM_MODULOS_VALIDOS >= 3 THEN
        RAISE NOTICE 'TRUE';
        RETURN TRUE;
    ELSE
        RAISE NOTICE 'FALSE';
        RETURN FALSE;
    END IF;
END
$$ LANGUAGE plpgsql;

--|-------------------------------------------------------------------------------------------------|--
--|--- ################################## STATUS_ALUNO_MODULO ################################## ---|----------------------------------------------------------------
--|-------------------------------------------------------------------------------------------------|--

-- QUANDO SE INSERE OU ATUALIZA ALUNO_CURSO, FAZ-SE O MESMO COM ALUNO_MODULO
---------------------------------------------MUDAR O(S) QUE FICA(M) ACESSIVEL(IS) PRIMEIRO(S)-------------------------------------------------------------------------MUDAR------------------------------------------------------------------------------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION STATUS_ALUNO_MODULO(CODIGO_ALUNO INT, CODIGO_CURSO INT)
RETURNS VOID
AS $$
DECLARE
    REGISTRO_COD_MODULO RECORD;
    PRIMEIRO BOOLEAN := TRUE;
BEGIN
   
    FOR REGISTRO_COD_MODULO IN (SELECT * FROM CURSO C_S INNER JOIN MODULO M_D ON C_S.COD_CURSO = M_D.COD_CURSO WHERE M_D.COD_CURSO = CODIGO_CURSO) LOOP
        IF PRIMEIRO = TRUE THEN
            INSERT INTO ALUNO_MODULO VALUES (DEFAULT, TRUE, FALSE, CODIGO_ALUNO, REGISTRO_COD_MODULO.COD_MODULO);
            PRIMEIRO := FALSE;
        ELSE
            INSERT INTO ALUNO_MODULO VALUES (DEFAULT, FALSE, FALSE, CODIGO_ALUNO, REGISTRO_COD_MODULO.COD_MODULO);
        END IF;
    END LOOP;
   
END
$$ LANGUAGE plpgsql;

--|-------------------------------------------------------------------------------------------------|--
--|--- ############################# QUANTIDADE_VIDEOS_ASSISTIDOS ############################## ---|----------------------------------------------------------------
--|-------------------------------------------------------------------------------------------------|--

---------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- MUDAR NOME <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
-- OBS: MUDAR FUNÇÃO PARA ATUAR APENAS EM UM MÓDULO ESPECÍFICO????? -- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
CREATE OR REPLACE FUNCTION QUANTIDADE_VIDEOS_ASSISTIDOS(CODIGO_ALUNO INT)
RETURNS INT
AS $$
DECLARE
    REGISTRO_VIDEO_ASSISTIDO RECORD;
    CONTADOR INT := 0;
BEGIN
   
    FOR REGISTRO_VIDEO_ASSISTIDO IN (SELECT * FROM ALUNO_VIDEOS_ASSISTIDOS A_V_A WHERE A_V_A.COD_ALUNO = CODIGO_ALUNO) LOOP
        CONTADOR := CONTADOR + 1;
    END LOOP;
   
    RETURN CONTADOR;
   
END
$$ LANGUAGE plpgsql;

--|-------------------------------------------------------------------------------------------------|--
--|--- ############################### QUANTIDADE_VIDEOS_MODULO ################################ ---|----------------------------------------------------------------
--|-------------------------------------------------------------------------------------------------|--

/* ASSISTIR VIDEOS */
CREATE OR REPLACE FUNCTION QUANTIDADE_VIDEOS_MODULO(CODIGO_VIDEO_AULA INT)
RETURNS INT
AS $$
DECLARE
    MODULO INT := (SELECT D_C.COD_MODULO FROM DISCIPLINA D_C INNER JOIN VIDEO_AULA V_L ON D_C.COD_DISCIPLINA = V_L.COD_DISCIPLINA
		   WHERE V_L.COD_VIDEO_AULA = CODIGO_VIDEO_AULA);
    REGISTRO_DISCIPLINA RECORD;
    REGISTRO_VIDEO RECORD;
    CONTADOR INT := 0;
BEGIN
   
    FOR REGISTRO_DISCIPLINA IN (SELECT * FROM DISCIPLINA D_C WHERE D_C.COD_MODULO = MODULO) LOOP
        FOR REGISTRO_VIDEO IN (SELECT * FROM VIDEO_AULA V_D WHERE V_D.COD_DISCIPLINA = REGISTRO_DISCIPLINA.COD_DISCIPLINA) LOOP
            CONTADOR := CONTADOR + 1;
        END LOOP;
    END LOOP;
 
    RETURN CONTADOR;
   
END
$$ LANGUAGE plpgsql;

--|-------------------------------------------------------------------------------------------------|--
--|--- ######################### VERIFICAR_SE_MODULOS_FICAM_ACESSIVEIS ######################### ---|----------------------------------------------------------------
--|-------------------------------------------------------------------------------------------------|--

CREATE FUNCTION VERIFICAR_SE_MODULOS_FICAM_ACESSIVEIS(COD_MODULO_ALUNO_MODULO INT)
RETURNS VOID
AS $$
DECLARE
	MODULO_FICAR_ACESSIVEL BOOLEAN;

	MODULO_PRE_REQUISITO_ANALISADO RECORD;
	MODULO_ANALISADO RECORD;
	ALUNO_MODULO_VERIFICADO RECORD;
BEGIN
	FOR MODULO_PRE_REQUISITO_ANALISADO IN (SELECT * FROM PRE_REQUISITO WHERE COD_MODULO_PRE_REQUISITO = COD_MODULO_ALUNO_MODULO) LOOP
		MODULO_FICAR_ACESSIVEL := TRUE;
		FOR MODULO_ANALISADO IN (SELECT * FROM PRE_REQUISITO WHERE COD_MODULO = MODULO_PRE_REQUISITO_ANALISADO.COD_MODULO) LOOP
			FOR ALUNO_MODULO_VERIFICADO IN (SELECT * FROM ALUNO_MODULO WHERE COD_MODULO = MODULO_ANALISADO.COD_MODULO_PRE_REQUISITO) LOOP
				IF ALUNO_MODULO_VERIFICADO.META_CONCLUIDA IS FALSE THEN
					MODULO_FICAR_ACESSIVEL := FALSE;
				END IF;

			END LOOP;

		END LOOP;

		IF MODULO_FICAR_ACESSIVEL IS TRUE THEN
			UPDATE ALUNO_MODULO SET ACESSIVEL = TRUE WHERE COD_MODULO = MODULO_PRE_REQUISITO_ANALISADO.COD_MODULO;
		END IF;

	END LOOP;
END
$$ LANGUAGE plpgsql;

--|-------------------------------------------------------------------------------------------------|--
--|--- ########################### VERIFICAR_VALIDADE_PRE_REQUISITO ############################ ---|----------------------------------------------------------------
--|-------------------------------------------------------------------------------------------------|--

-- OBRIGADÃO PELO CÓDIGO, LUAN! :D
CREATE OR REPLACE FUNCTION VERIFICAR_VALIDADE_PRE_REQUISITO(COD_MODULO_ALVO INT, COD_MODULO_ANALISADO INT)
RETURNS BOOLEAN
AS $$
DECLARE
	REGISTRO_COD_MODULO_ANALISADO RECORD;
BEGIN
	IF COD_MODULO_ALVO IN (SELECT COD_MODULO_PRE_REQUISITO FROM PRE_REQUISITO WHERE COD_MODULO = COD_MODULO_ANALISADO) THEN
		RETURN FALSE;
	ELSE
		FOR REGISTRO_COD_MODULO_ANALISADO IN (SELECT COD_MODULO_PRE_REQUISITO FROM PRE_REQUISITO WHERE COD_MODULO = COD_MODULO_ANALISADO) LOOP
			IF VERIFICAR_VALIDADE_PRE_REQUISITO(COD_MODULO_ALVO, REGISTRO_COD_MODULO_ANALISADO.COD_MODULO_PRE_REQUISITO) IS FALSE THEN
				RETURN FALSE;
			END IF;
		END LOOP;
		RETURN TRUE;
	END IF;
END
$$ LANGUAGE plpgsql;


---------------------------------------------------------------------------------------------------------------------------------------------------------------------
                      --        ####################################### FUNCTIONS PRINCIPAIS ########################################        --
                      -- ################################################################################################################### --
---------------------------------------------------------------------------------------------------------------------------------------------------------------------


--*****************************************************************************************************************************************************************--
----------------------------*******************************************  << SUPER USUÁRIO >>  *******************************************----------------------------
--*****************************************************************************************************************************************************************--


--|-------------------------------------------------------------------------------------------------|--
--|--- ############################### INSERIR_ALUNO_E_PROFESSOR ############################### ---|----------------------------------------------------------------
--|-------------------------------------------------------------------------------------------------|--

/* CRIANDO FUNCTION INSERIR ALUNO E PROFESSOR */ -- SUPERUSUÁRIO
CREATE OR REPLACE FUNCTION INSERIR_ALUNO_E_PROFESSOR(NOME TEXT, CPF TEXT, DATA_NASCIMENTO DATE, EMAIL TEXT, SENHA TEXT, TABELA TEXT)
RETURNS VOID
AS $$
BEGIN
	IF TABELA = 'ALUNO' THEN
		INSERT INTO ALUNO VALUES (DEFAULT, NOME, CPF, DATA_NASCIMENTO, EMAIL, SENHA, DEFAULT);
	END IF;
 
	IF TABELA = 'PROFESSOR' THEN
		INSERT INTO PROFESSOR VALUES (DEFAULT, NOME, CPF, DATA_NASCIMENTO, EMAIL, SENHA, DEFAULT, DEFAULT);
	END IF;
END
$$ LANGUAGE plpgsql;

--|---------------------------------------------------------------------------------------|--
--|--- ########################## REMOVER_ALUNO_E_PROFESSOR ########################## ---|--------------------------------------------------------------------------
--|---------------------------------------------------------------------------------------|--

/* REMOVE ALUNO OU PROFESSOR */
CREATE OR REPLACE FUNCTION REMOVER_ALUNO_E_PROFESSOR(COD_USUARIO_DELETEADO INT)
RETURNS VOID
AS $$
BEGIN
	IF TABELA = 'ALUNO' THEN
		DELETE FROM ALUNO WHERE COD_USUARIO = COD_USUARIO_DELETADO;
	END IF;
 
	IF TABELA = 'PROFESSOR' THEN
		DELETE FROM ALUNO WHERE COD_USUARIO = COD_USUARIO_DELETADO;
	END IF;
END
$$ LANGUAGE plpgsql;



--*****************************************************************************************************************************************************************--
----------------------------*****************************************  << ALUNO # PROFESSOR >>  *****************************************----------------------------
--*****************************************************************************************************************************************************************--


--|---------------------------------------------------------------------------------------|--
--|--- ############################### CONSULTAR_SALDO ############################### ---|--------------------------------------------------------------------------
--|---------------------------------------------------------------------------------------|--

/* CONSULTA O SALDO DA TABELA */
CREATE OR REPLACE FUNCTION CONSULTAR_SALDO(CODIGO INT, TABELA TEXT)
RETURNS TEXT
AS $$
DECLARE
	SALDO_CONSULTADO FLOAT;
BEGIN
	IF TABELA = 'ALUNO' THEN
		SELECT SALDO INTO SALDO_CONSULTADO FROM ALUNO WHERE CODIGO = COD_ALUNO;
	ELSIF TABELA = 'PROFESSOR' THEN
		SELECT SALDO INTO SALDO_CONSULTADO FROM PROFESSOR WHERE CODIGO = COD_PROFESSOR;
	END IF;
   
	IF SALDO_CONSULTADO = 0 THEN
		RETURN 'SEM SALDO!';
	ELSE
		RETURN 'SEU SALDO É DE R$ ' || CAST(SALDO_SACADO AS TEXT) || '!';
	END IF;
END
$$ LANGUAGE plpgsql;

--|---------------------------------------------------------------------------------------|--
--|--- ############################### ATUALIZAR_SALDO ############################### ---|--------------------------------------------------------------------------
--|---------------------------------------------------------------------------------------|--

/* ATUALIZA SALDO INCREMENTANDO O VALOR DE SALDO A ALTERAR */
CREATE OR REPLACE FUNCTION ATUALIZAR_SALDO(VALOR_SALDO_A_ALTERAR FLOAT, CODIGO INT, TABELA TEXT)
RETURNS VOID
AS $$
DECLARE
	SALDO_USUARIO INT;
BEGIN
	
    IF TABELA = 'ALUNO' THEN
	SELECT SALDO INTO SALDO_USUARIO FROM ALUNO WHERE COD_ALUNO = CODIGO;
	IF VALOR_SALDO_A_ALTERAR + SALDO_USUARIO >= 0 THEN
		UPDATE ALUNO SET SALDO = SALDO + VALOR_SALDO_A_ALTERAR WHERE COD_ALUNO = CODIGO;
	ELSE
		RAISE EXCEPTION 'SAQUE ACIMA DO VALOR DISPONÍVEL INVÁLIDO!';
	END IF;
    ELSIF TABELA = 'PROFESSOR' THEN
	SELECT SALDO INTO SALDO_USUARIO FROM PROFESSOR WHERE COD_PROFESSOR = CODIGO;
	IF VALOR_SALDO_A_ALTERAR + SALDO_USUARIO >= 0 THEN
		UPDATE PROFESSOR SET SALDO = SALDO + VALOR_SALDO_A_ALTERAR WHERE COD_PROFESSOR = CODIGO;
        ELSE
		RAISE EXCEPTION 'SAQUE ACIMA DO VALOR DISPONÍVEL INVÁLIDO!';
	END IF;
    END IF;
END
$$ LANGUAGE plpgsql;

--|-----------------------------------------------------------------------------------|--
--|--- ############################### SACAR_SALDO ############################### ---|------------------------------------------------------------------------------
--|-----------------------------------------------------------------------------------|--
 
/* SACA TODO O SALDO DA TABELA */
CREATE OR REPLACE FUNCTION SACAR_SALDO(CODIGO INT, TABELA TEXT)
RETURNS TEXT
AS $$
DECLARE
    SALDO_SACADO FLOAT;
BEGIN
    IF TABELA = 'ALUNO' THEN
        SELECT SALDO INTO SALDO_SACADO FROM ALUNO WHERE CODIGO = COD_ALUNO;
    ELSIF TABELA = 'PROFESSOR' THEN
        SELECT SALDO INTO SALDO_SACADO FROM PROFESSOR WHERE CODIGO = COD_PROFESSOR;
    END IF;
   
    IF SALDO_SACADO = 0 THEN
        RETURN 'SEM SALDO!';
    ELSE
        PERFORM ATUALIZAR_SALDO(-SALDO_SACADO, CODIGO, TABELA);
        RETURN 'FORAM SACADOS R$ ' || CAST(SALDO_SACADO AS TEXT) || '!';
    END IF;
END
$$ LANGUAGE plpgsql;



--*****************************************************************************************************************************************************************--
----------------------------*********************************************  << PROFESSOR >>  *********************************************----------------------------
--*****************************************************************************************************************************************************************--


--|---------------------------------------------------------------------------------------|--
--|--- ############################### RECEBER_SALARIO ############################### ---|--------------------------------------------------------------------------
--|---------------------------------------------------------------------------------------|--

/* FAZ O PROFESSOR RECEBER O SALÁRIO */
CREATE OR REPLACE FUNCTION RECEBER_SALARIO(COD_PROFESSOR_ANALISADO INT)
RETURNS VOID
AS $$
DECLARE
    DATA_ULTIMO_PAGAMENTO_ANALISADO DATE;
    DATA_PAGAMENTO_ATUAL DATE;
    SALARIO_A_PAGAR FLOAT;
BEGIN
    SELECT DATA_ULTIMO_PAGAMENTO INTO DATA_ULTIMO_PAGAMENTO_ANALISADO FROM PROFESSOR WHERE COD_PROFESSOR = COD_PROFESSOR_ANALISADO;
    DATA_PAGAMENTO_ATUAL := CALCULAR_DATA_PAGAMENTO_ATUAL();
 
    SELECT COALESCE(SUM(PRECO), 0) INTO SALARIO_A_PAGAR FROM ALUNO_CURSO INNER JOIN CURSO ON ALUNO_CURSO.COD_CURSO = CURSO.COD_CURSO
           WHERE COD_PROFESSOR = COD_PROFESSOR_ANALISADO AND DATA_COMPRA < DATA_PAGAMENTO_ATUAL AND DATA_COMPRA >= DATA_ULTIMO_PAGAMENTO_ANALISADO;
    UPDATE PROFESSOR SET SALDO = SALDO + SALARIO_A_PAGAR, DATA_ULTIMO_PAGAMENTO = DATA_PAGAMENTO_ATUAL WHERE COD_PROFESSOR = COD_PROFESSOR_ANALISADO;
END
$$ LANGUAGE plpgsql;



--*****************************************************************************************************************************************************************--
----------------------------************************************  << ALUNO_CURSO # CURSO # ALUNO >>  ************************************----------------------------
--*****************************************************************************************************************************************************************--


--|-------------------------------------------------------------------------------------|--
--|--- ############################### COMPRAR_CURSO ############################### ---|----------------------------------------------------------------------------
--|-------------------------------------------------------------------------------------|--

/* INSERIR OU ATUALIZAR ALUNO_CURSO QUANDO ALUNO FOR COMPRAR O CURSO */
CREATE OR REPLACE FUNCTION COMPRAR_CURSO(COD_ALUNO_ANALISADO INT, COD_CURSO_ANALISADO INT)
RETURNS VOID
AS $$
BEGIN
    IF VERIFICAR_SE_REGISTRO_EXISTE(COD_ALUNO_ANALISADO, 'ALUNO') IS FALSE THEN
        RAISE EXCEPTION 'ESSE ALUNO AINDA NÃO FOI CADASTRADO!';
 
    ELSIF VERIFICAR_SE_REGISTRO_EXISTE(COD_CURSO_ANALISADO, 'CURSO') IS FALSE THEN
        RAISE EXCEPTION 'ESSE CURSO AINDA NÃO FOI CADASTRADO!';
 
    ELSIF ALUNO_AINDA_CURSANDO(COD_ALUNO_ANALISADO, COD_CURSO_ANALISADO) IS TRUE THEN
        RAISE EXCEPTION 'VOCÊ AINDA ESTÁ CURSANDO ESSE CURSO. COMPRA DO CURSO REJEITADA!';
 
    ELSIF CURSO_DISPONIVEL(COD_CURSO_ANALISADO) != TRUE THEN
        RAISE EXCEPTION 'CURSO INDISPONÍVEL PARA NOVAS COMPRAS!';
 
    ELSIF ALUNO_JA_CURSOU(COD_ALUNO_ANALISADO, COD_CURSO_ANALISADO) = TRUE THEN
        PERFORM ATUALIZAR_SALDO(-SELECIONAR_PRECO(COD_CURSO_ANALISADO), COD_ALUNO_ANALISADO, 'ALUNO');
        UPDATE ALUNO_CURSO SET DATA_COMPRA = DATE(NOW()), NOTA_AVALIACAO = NULL WHERE COD_ALUNO = COD_ALUNO_ANALISADO AND COD_CURSO = COD_CURSO_ANALISADO;
 
    ELSE
        PERFORM ATUALIZAR_SALDO(-SELECIONAR_PRECO(COD_CURSO_ANALISADO), COD_ALUNO_ANALISADO, 'ALUNO');
        INSERT INTO ALUNO_CURSO VALUES (DEFAULT, DATE(NOW()), NULL, COD_ALUNO_ANALISADO, COD_CURSO_ANALISADO);
    END IF;
 
END
$$ LANGUAGE plpgsql;



--*****************************************************************************************************************************************************************--
----------------------------*****************************************  << CURSO # PROFESSOR >>  *****************************************----------------------------
--*****************************************************************************************************************************************************************--


--|-----------------------------------------------------------------------------------------|--
--|--- ################################## CRIAR_CURSO ################################## ---|------------------------------------------------------------------------
--------------------------------------------------------------------------------------------|--

/* CRIAR CURSO */
CREATE OR REPLACE FUNCTION CRIAR_CURSO(COD_PROFESSOR INT, NOME_CURSO TEXT, DESCRICAO TEXT, PRECO FLOAT)
RETURNS VOID
AS $$
BEGIN
	INSERT INTO CURSO VALUES (DEFAULT, NOME_CURSO, DESCRICAO, DEFAULT, PRECO, DEFAULT, DEFAULT, DEFAULT, COD_PROFESSOR);
END
$$ LANGUAGE plpgsql;

--|-----------------------------------------------------------------------------------------|--
--|--- ################################# DELETAR_CURSO ################################# ---|------------------------------------------------------------------------
--------------------------------------------------------------------------------------------|--

/* DELETAR CURSO */
CREATE OR REPLACE FUNCTION DELETAR_CURSO(COD_CURSO_DELETADO INT)
RETURNS VOID
AS $$
BEGIN
	IF VERIFICAR_SE_REGISTRO_EXISTE(COD_CURSO_DELETADO, 'CURSO') IS FALSE THEN
		RAISE EXCEPTION 'ESSE CURSO NÃO EXISTE, INSIRA UM COD_CURSO VALIDO!';
	END IF;
	
	DELETE FROM CURSO WHERE COD_CURSO = COD_CURSO_DELETADO;
END
$$ LANGUAGE plpgsql;

--|--------------------------------------------------------------------------------------|--
--|--- ############################### PUBLICAR_CURSO ############################### ---|---------------------------------------------------------------------------
--|--------------------------------------------------------------------------------------|--
--------------------------------------------------------------------------------------------------OBS: FALTA VERIFICAR SE PROFS É DO CURSO.--------------------------------------------------------------------------------------------------------

/* PUBLICAR CURSO */
CREATE OR REPLACE FUNCTION PUBLICAR_CURSO(CODIGO_CURSO INT)
RETURNS VOID
AS $$
DECLARE
	DISPONIBILIDADE BOOLEAN := (SELECT C_S.DISPONIBILIDADE FROM CURSO C_S WHERE C_S.COD_CURSO = CODIGO_CURSO);
BEGIN

	IF VERIFICAR_SE_REGISTRO_EXISTE(CODIGO_CURSO, 'CURSO') IS FALSE THEN
		RAISE EXCEPTION 'ESSE CURSO NÃO EXISTE, INSIRA UM COD_CURSO VALIDO!';
	ELSE
		IF DISPONIBILIDADE = FALSE THEN
			RAISE EXCEPTION 'O CURSO NÃO ATENDE OS REQUISITOS NO MOMENTO. PARA SER PUBLICADO, ATENDA OS REQUISITOS!';
		ELSE
			UPDATE CURSO SET PUBLICADO = TRUE WHERE COD_CURSO = CODIGO_CURSO;
		END IF;
	END IF;
   
END
$$ LANGUAGE plpgsql;



--*****************************************************************************************************************************************************************--
----------------------------*****************************************  << MODULO # PROFESSOR >>  ****************************************----------------------------
--*****************************************************************************************************************************************************************--


--|-----------------------------------------------------------------------------------------|--
--|--- ################################# CRIAR_MODULO ################################## ---|------------------------------------------------------------------------
--|-----------------------------------------------------------------------------------------|--

/* CRIAR MODULOS */
CREATE OR REPLACE FUNCTION CRIAR_MODULO(CODIGO_CURSO INT, NOME_MODULO TEXT[], DESCRICAO_MODULO TEXT[], DURACAO_MODULO INT[])
RETURNS VOID
AS $$
DECLARE
	CONTADOR INT := 1;
BEGIN
	IF VERIFICAR_SE_REGISTRO_EXISTE(CODIGO_CURSO, 'CURSO') IS FALSE THEN
		RAISE EXCEPTION 'ESSE CURSO NÃO EXISTE, INSIRA UM COD_CURSO VALIDO!';
	ELSE
		WHILE CONTADOR <= ARRAY_LENGTH(NOME_MODULO,1) LOOP
			INSERT INTO MODULO VALUES (DEFAULT, NOME_MODULO[CONTADOR], DESCRICAO_MODULO[CONTADOR], DURACAO_MODULO[CONTADOR], CODIGO_CURSO);
			CONTADOR := CONTADOR + 1;
		END LOOP;
	END IF;
END
$$ LANGUAGE plpgsql;

--|--------------------------------------------------------------------------------------|--
--|--- ############################### DELETAR_MODULO ############################### ---|---------------------------------------------------------------------------
--|--------------------------------------------------------------------------------------|--

/* DELETANDO MODULO */
CREATE OR REPLACE FUNCTION DELETAR_MODULO(CODIGO_MODULO INT)
RETURNS VOID
AS $$
BEGIN
	IF VERIFICAR_SE_REGISTRO_EXISTE(CODIGO_MODULO, 'MODULO') IS FALSE THEN
		RAISE EXCEPTION 'ESSE MODULO NÃO EXISTE, INSIRA UM COD_MODULO VALIDO!';
	ELSE
		DELETE FROM MODULO M_D WHERE M_D.COD_MODULO = CODIGO_MODULO;
	END IF;   
END
$$ LANGUAGE plpgsql;


--*****************************************************************************************************************************************************************--
----------------------------*************************************  << PRE_REQUISITO # PROFESSOR >>  *************************************----------------------------
--*****************************************************************************************************************************************************************--

--|--------------------------------------------------------------------------------------|--
--|--- ############################# CRIAR_PRE_REQUISITO ############################ ---|---------------------------------------------------------------------------
--|--------------------------------------------------------------------------------------|--

/* CRIAR PRE_REQUISITO */
CREATE OR REPLACE FUNCTION CRIAR_PRE_REQUISITO(COD_MODULO INT, COD_MODULO_PRE_REQUISITO INT)
RETURNS VOID
AS $$
BEGIN
	IF VERIFICAR_SE_REGISTRO_EXISTE(CODIGO_MODULO, 'MODULO') IS FALSE THEN
		RAISE EXCEPTION 'ESSE MODULO NÃO EXISTE, INSIRA UM COD_MODULO VALIDO!';
	ELSIF VERIFICAR_SE_REGISTRO_EXISTE(CODIGO_MODULO_PRE_REQUISITO, 'MODULO') IS FALSE THEN
		RAISE EXCEPTION 'ESSE MODULO NÃO EXISTE, INSIRA UM COD_MODULO_PRE_REQUISITO VALIDO!';
	ELSE
		INSERT INTO PRE_REQUISITO VALUES (DEFAULT, COD_MODULO, COD_MODULO_PRE_REQUISITO);
	END IF;
END
$$ LANGUAGE plpgsql;



--*****************************************************************************************************************************************************************--
----------------------------***************************************  << DISCIPLINA # PROFESSOR >>  **************************************----------------------------
--*****************************************************************************************************************************************************************--


--|------------------------------------------------------------------------------------------|--
--|--- ############################### CRIAR_DISCIPLINAS ################################ ---|-----------------------------------------------------------------------
--|------------------------------------------------------------------------------------------|--

/* CRIA DISCIPLINAS PARA ALGUM MODULO */
CREATE OR REPLACE FUNCTION CRIAR_DISCIPLINAS(CODIGO_MODULO INT, NOME_DISCIPLINA TEXT[], DESCRICAO_DISCIPLINA TEXT[])
RETURNS VOID
AS $$
DECLARE
	CONTADOR INT := 1;
BEGIN
	IF VERIFICAR_SE_REGISTRO_EXISTE(CODIGO_MODULO, 'MODULO') IS FALSE THEN
		RAISE EXCEPTION 'ESSE MÓDULO NÃO EXISTE, INSIRA UM COD_MODULO VALIDO!';
	ELSE
                WHILE CONTADOR <= ARRAY_LENGTH(NOME_DISCIPLINA,1) LOOP
			INSERT INTO DISCIPLINA VALUES (DEFAULT, NOME_DISCIPLINA[CONTADOR], DESCRICAO_DISCIPLINA[CONTADOR], CODIGO_MODULO);
			CONTADOR := CONTADOR + 1;
                END LOOP;
	END IF;
END
$$ LANGUAGE plpgsql;

--|------------------------------------------------------------------------------------------|--
--|--- ############################### DELETAR_DISCIPLINA ############################### ---|-----------------------------------------------------------------------
--|------------------------------------------------------------------------------------------|--

/* DELETANDO DISCIPLINA */
CREATE OR REPLACE FUNCTION DELETAR_DISCIPLINA(CODIGO_DISCIPLINA INT)
RETURNS VOID
AS $$
BEGIN
	IF VERIFICAR_SE_REGISTRO_EXISTE(CODIGO_DISCIPLINA, 'DISCIPLINA') IS FALSE THEN
		RAISE EXCEPTION 'ESSA DISCIPLINA NÃO EXISTE, INSIRA UM COD_DISCIPLINA VALIDO!';
	ELSE
		DELETE FROM DISCIPLINA D_C WHERE D_C.COD_DISCIPLINA = CODIGO_DISCIPLINA;
	END IF;
END
$$ LANGUAGE plpgsql;



--*****************************************************************************************************************************************************************--
----------------------------***************************************  << VIDEO_AULA # PROFESSOR >>  **************************************----------------------------
--*****************************************************************************************************************************************************************--


--|------------------------------------------------------------------------------------------|--
--|--- ############################### CRIAR_VIDEO_AULAS ################################ ---|-----------------------------------------------------------------------
--|------------------------------------------------------------------------------------------|--

/* ADICIONANDO VIDEO AULAS AS DISCIPLINAS  */
CREATE OR REPLACE FUNCTION CRIAR_VIDEO_AULAS(CODIGO_DISCIPLINA INT, TITULO_VIDEO TEXT[], DESCRICAO TEXT[], DURACAO INT[])
RETURNS VOID
AS $$
DECLARE
	CONTADOR INT := 1;
BEGIN
	IF VERIFICAR_SE_REGISTRO_EXISTE(CODIGO_DISCIPLINA, 'DISCIPLINA') IS FALSE THEN
		RAISE EXCEPTION 'ESSA DISCIPLINA NÃO EXISTE, INSIRA UM COD_DISCIPLINA VALIDO!';
	ELSE
		WHILE CONTADOR <= ARRAY_LENGTH(TITULO_VIDEO,1) LOOP -- NO ARRAY LENGHT, ESSE "1" SIGNIFICA A QUANTIDADE DE COLUNAS DA ARRAY.
			INSERT INTO VIDEO_AULA VALUES (DEFAULT, TITULO_VIDEO[CONTADOR], DESCRICAO[CONTADOR], DURACAO[CONTADOR], CODIGO_DISCIPLINA);
			CONTADOR := CONTADOR + 1;
		END LOOP;
	END IF;
END
$$ LANGUAGE plpgsql;

--|------------------------------------------------------------------------------------------|--
--|--- ############################### DELETAR_VIDEO_AULA ############################### ---|-----------------------------------------------------------------------
--|------------------------------------------------------------------------------------------|--

/* DELETANDO VIDEO */
CREATE OR REPLACE FUNCTION DELETAR_VIDEO_AULA(CODIGO_VIDEO_AULA INT)
RETURNS VOID
AS $$
BEGIN
	IF VERIFICAR_SE_REGISTRO_EXISTE(CODIGO_VIDEO_AULA, 'VIDEO_AULA') IS FALSE THEN
		RAISE EXCEPTION 'ESSE VIDEO NÃO EXISTE, INSIRA UM COD_VIDEO_AULA VALIDO!';
	ELSE
		DELETE FROM VIDEO_AULA V_A WHERE V_A.COD_VIDEO_AULA = CODIGO_VIDEO_AULA;
	END IF;
END
$$ LANGUAGE plpgsql;



--*****************************************************************************************************************************************************************--
----------------------------**************************************  << ALUNO_VIDEOS_ASSISTIDOS >>  **************************************----------------------------
--*****************************************************************************************************************************************************************--


--|------------------------------------------------------------------------------------------|--
--|--- ############################## ASSISTIR_VIDEO_AULA ############################### ---|-----------------------------------------------------------------------
--|------------------------------------------------------------------------------------------|--

/* ASSISTIR VIDEOS */
CREATE OR REPLACE FUNCTION ASSISTIR_VIDEO_AULA(CODIGO_ALUNO INT, CODIGO_VIDEO_AULA INT)
RETURNS VOID
AS $$
DECLARE
	CODIGO_MODULO INT := (SELECT D_C.COD_MODULO FROM DISCIPLINA D_C INNER JOIN VIDEO_AULA V_L ON D_C.COD_DISCIPLINA =
			     V_L.COD_DISCIPLINA WHERE V_L.COD_VIDEO_AULA = CODIGO_VIDEO_AULA);

	MODULO_ACESSIVEL BOOLEAN := (SELECT A_M.ACESSIVEL FROM ALUNO_MODULO A_M INNER JOIN MODULO M_D ON
				    A_M.COD_MODULO = M_D.COD_MODULO WHERE A_M.COD_MODULO = CODIGO_MODULO
				    AND A_M.COD_ALUNO = CODIGO_ALUNO);

	CODIGO_CURSO INT := (SELECT C_S.COD_CURSO FROM CURSO C_S INNER JOIN MODULO M_D ON C_S.COD_CURSO = M_D.COD_CURSO
			    WHERE M_D.COD_MODULO = CODIGO_MODULO);
BEGIN
	IF VERIFICAR_SE_REGISTRO_EXISTE(CODIGO_ALUNO, 'ALUNO') IS FALSE THEN
		RAISE EXCEPTION 'ESSE ALUNO NÃO EXISTE, INSIRA UM COD_ALUNO VALIDO!';
	ELSE
		IF VERIFICAR_SE_REGISTRO_EXISTE(CODIGO_VIDEO_AULA, 'VIDEO_AULA') IS FALSE THEN
			RAISE EXCEPTION 'ESSA VIDEO_AULA NÃO EXISTE, INSIRA UM COD_VIDEO_AULA!';
		ELSE
			IF MODULO_ACESSIVEL IS FALSE THEN
				RAISE EXCEPTION 'ESSE ALUNO NÃO ATINGIU A META OBRIGATORIA DOS MÓDULOS QUE SÃO PRE_REQUISITO PARA ACESSAR ESSE MÓDULO!';
			ELSE
				IF ALUNO_AINDA_CURSANDO(CODIGO_ALUNO, CODIGO_CURSO) IS FALSE THEN
					RAISE EXCEPTION 'ESSE ALUNO NÃO ESTÁ CURSANDO O CURSO DESSA VIDEO_AULA!';
				ELSE
					IF ALUNO_JA_ASSISTIU(CODIGO_ALUNO, CODIGO_VIDEO_AULA) IS FALSE THEN
						INSERT INTO ALUNO_VIDEOS_ASSISTIDOS VALUES (DEFAULT, ALUNO_EXISTE, CODIGO_VIDEO_AULA);
					END IF;
				END IF;
			END IF;
		END IF;		
	END IF;
END
$$ LANGUAGE plpgsql;



--*****************************************************************************************************************************************************************--
----------------------------****************************************  << QUESTAO # PROFESSOR >>  ****************************************----------------------------
--*****************************************************************************************************************************************************************--


--|------------------------------------------------------------------------------------------|--
--|--- ################################# CRIAR_QUESTAO ################################## ---|-----------------------------------------------------------------------
--|------------------------------------------------------------------------------------------|--

CREATE OR REPLACE FUNCTION CRIAR_QUESTAO(CODIGO_DISCIPLINA INT, TEXTO_INSERIDO TEXT)
RETURNS VOID
AS $$
BEGIN

	IF VERIFICAR_SE_REGISTRO_EXISTE(CODIGO_DISCIPLINA, 'DISCIPLINA') IS FALSE THEN
		RAISE EXCEPTION 'ESSA DISCIPLINA NÃO EXISTE, INSIRA UM COD_DISCIPLINA VALIDO!';
	ELSE	
		INSERT INTO QUESTAO VALUES (DEFAULT, TEXTO_INSERIDO, CODIGO_DISCIPLINA);
	END IF;
END
$$ LANGUAGE plpgsql;

--|------------------------------------------------------------------------------------------|--
--|--- ################################# DELETAR_QUESTAO ################################ ---|-----------------------------------------------------------------------
--|------------------------------------------------------------------------------------------|--

CREATE OR REPLACE FUNCTION DELETAR_QUESTAO(CODIGO_QUESTAO INT)
RETURNS VOID
AS $$
BEGIN
	IF VERIFICAR_SE_REGISTRO_EXISTE(CODIGO_QUESTAO, 'QUESTAO') IS FALSE THEN
		RAISE EXCEPTION 'ESSA QUESTÃO AINDA NÃO FOI CADASTRADA!';
	ELSE
		DELETE FROM QUESTAO WHERE COD_QUESTAO = CODIGO_QUESTAO;
	END IF;
END
$$ LANGUAGE plpgsql;

--|------------------------------------------------------------------------------------------|--
--|--- ########################### LISTAR_QUESTOES_DOS_ALUNOS ########################### ---|-----------------------------------------------------------------------
--|------------------------------------------------------------------------------------------|--

CREATE OR REPLACE FUNCTION LISTAR_QUESTOES_DOS_ALUNOS(COD_PROFESSOR_ANALISADO INT)
RETURNS TABLE(COD_QUESTAO_ALUNO INT, RESPOSTA_CORRETA VARCHAR(13), TEXTO VARCHAR(500), RESPOSTA_ALUNO VARCHAR(500))
AS $$
BEGIN
    IF VERIFICAR_SE_REGISTRO_EXISTE(COD_PROFESSOR_ANALISADO, 'PROFESSOR') IS FALSE THEN
        RAISE EXCEPTION 'ESSE PROFESSOR AINDA NÃO FOI CADASTRADO!';
    END IF;
   
    RETURN QUERY SELECT Q_A.COD_QUESTAO_ALUNO, Q_A.RESPOSTA_CORRETA, Q.TEXTO, Q_A.RESPOSTA_ALUNO FROM QUESTAO_ALUNO Q_A
    INNER JOIN QUESTAO Q ON Q_A.COD_QUESTAO = Q.COD_QUESTAO INNER JOIN QUESTAO_QUESTIONARIO Q_Q ON Q.COD_QUESTAO = Q_Q.COD_QUESTAO
    INNER JOIN QUESTIONARIO Q_R ON Q_Q.COD_QUESTIONARIO = Q_R.COD_QUESTIONARIO INNER JOIN DISCIPLINA D_C ON Q_R.COD_DISCIPLINA = D_C.COD_DISCIPLINA
    INNER JOIN MODULO M_D ON D_C.COD_MODULO = M_D.COD_MODULO INNER JOIN CURSO C_R ON M_D.COD_CURSO = C_R.COD_CURSO
    WHERE C_R.COD_PROFESSOR = COD_PROFESSOR_ANALISADO
    ORDER BY C_R.COD_CURSO, M_D.COD_MODULO, D_C.COD_DISCIPLINA, Q_R.COD_QUESTIONARIO, Q_Q.COD_QUESTAO_QUESTIONARIO, Q_Q.COD_QUESTAO, Q_A.COD_QUESTAO_ALUNO;
END
$$ LANGUAGE plpgsql;

--|------------------------------------------------------------------------------------------|--
--|--- ################################# CORRIGIR_QUESTAO ################################ --|-----------------------------------------------------------------------
--|------------------------------------------------------------------------------------------|--

CREATE OR REPLACE FUNCTION CORRIGIR_QUESTAO(COD_PROFESSOR_ANALISADO INT, COD_QUESTAO_ALUNO_CORRIGIDA INT, RESPOSTA_CORRETA_INSERIDA TEXT)
RETURNS VOID
AS $$
BEGIN
    IF VERIFICAR_SE_REGISTRO_EXISTE(COD_PROFESSOR_ANALISADO, 'PROFESSOR') IS FALSE THEN
        RAISE EXCEPTION 'ESSE PROFESSOR AINDA NÃO FOI CADASTRADO!';
    ELSIF VERIFICAR_SE_REGISTRO_EXISTE(COD_QUESTAO_ALUNO_CORRIGIDA, 'QUESTAO_ALUNO') IS FALSE THEN
        RAISE EXCEPTION 'ESSE VÍNCULO QUESTÃO_ALUNO AINDA NÃO FOI CADASTRADO!';
    ELSIF (COD_QUESTAO_ALUNO_CORRIGIDA IN (SELECT COD_QUESTAO_ALUNO FROM LISTAR_QUESTOES_DOS_ALUNOS(COD_PROFESSOR_ANALISADO))) IS FALSE THEN
        RAISE EXCEPTION 'VOCÊ NÃO TEM PERMISSÃO PARA MANIPULAÇÃO ESSE VÍNCULO QUESTÃO_ALUNO! ESSA QUESTÃO AINDA NÃO FOI POSTA EM UM QUESTIONÁRIO DE UM CURSO SEU!';
    ELSIF NOT (RESPOSTA_CORRETA_INSERIDA ILIKE 'CORRETA' OR RESPOSTA_CORRETA_INSERIDA ILIKE 'INCORRETA') THEN
        RAISE EXCEPTION 'DEVE-SE INFORMAR A RESPOSTA DO ALUNO APENAS COMO "CORRETA" OU "INCORRETA"';
    ELSE
        UPDATE QUESTAO_ALUNO SET RESPOSTA_CORRETA = RESPOSTA_CORRETA_INSERIDA WHERE COD_QUESTAO_ALUNO = COD_QUESTAO_ALUNO_CORRIGIDA;
    END IF;
END
$$ LANGUAGE plpgsql;



--*****************************************************************************************************************************************************************--
----------------------------*************************************  << QUESTIONARIO # PROFESSOR >>  **************************************----------------------------
--*****************************************************************************************************************************************************************--


--|------------------------------------------------------------------------------------------|--
--|--- ############################### CRIAR_QUESTIONARIO ############################### ---|-----------------------------------------------------------------------
--|------------------------------------------------------------------------------------------|--
 
CREATE OR REPLACE FUNCTION CRIAR_QUESTIONARIO(NOME_INSERIDO TEXT, COD_DISCIPLINA_INSERIDA INT)
RETURNS VOID
AS $$
BEGIN
    IF VERIFICAR_SE_REGISTRO_EXISTE(COD_DISCIPLINA_INSERIDA, 'DISCIPLINA') IS FALSE THEN
        RAISE EXCEPTION 'ESSA DISCIPLINA AINDA NÃO FOI CADASTRADA!';
    ELSE
        INSERT INTO QUESTIONARIO VALUES (DEFAULT, NOME_INSERIDO, COD_DISCIPLINA_INSERIDA);
    END IF;
END
$$ LANGUAGE plpgsql;
 
--|------------------------------------------------------------------------------------------|---
--|--- ############################## DELETAR_QUESTIONARIO ############################## ---|-----------------------------------------------------------------------
--|------------------------------------------------------------------------------------------|---

CREATE OR REPLACE FUNCTION DELETAR_QUESTIONARIO(COD_QUESTIONARIO_DELETADO INT)
RETURNS VOID
AS $$
BEGIN
    IF VERIFICAR_SE_REGISTRO_EXISTE(COD_QUESTIONARIO_DELETADO, 'QUESTIONARIO') IS FALSE THEN
        RAISE EXCEPTION 'ESSE QUESTIONARIO AINDA NÃO FOI CADASTRADO!';
    ELSE
        DELETE FROM QUESTIONARIO WHERE COD_QUESTIONARIO = COD_QUESTIONARIO_DELETADO;
    END IF;
END
$$ LANGUAGE plpgsql;



--*****************************************************************************************************************************************************************--
----------------------------*********************************  << QUESTAO_QUESTIONARIO # PROFESSOR >>  **********************************----------------------------
--*****************************************************************************************************************************************************************--


--|------------------------------------------------------------------------------------------|--
--|--- ######################## VINCULAR_QUESTAO_A_QUESTIONARIO ######################### ---|-----------------------------------------------------------------------
--|------------------------------------------------------------------------------------------|--

CREATE OR REPLACE FUNCTION VINCULAR_QUESTAO_A_QUESTIONARIO(COD_QUESTIONARIO_VINCULADO INT, COD_QUESTAO_VINCULADA INT)
RETURNS VOID
AS $$
DECLARE
    COD_DISCIPLINA_DO_QUESTIONARIO_VINCULADO INT := (SELECT COD_DISCIPLINA FROM QUESTIONARIO WHERE COD_QUESTIONARIO = COD_QUESTIONARIO_VINCULADO);
    COD_DISCIPLINA_DA_QUESTAO_VINCULADA INT := (SELECT COD_DISCIPLINA FROM QUESTAO WHERE COD_QUESTAO = COD_QUESTAO_VINCULADA);
BEGIN
    --------------------------------------------------------------------------------------------------------------------------------
    --------------------------------------------------------------------------------------------------------------------------------
    --------------------------------------------------------------------------------------------------------------------------------
    --------------------------------------------------------------------------------------------------------------------------------
    ------------------------- VERIFICAR SE A DISCIPLINA É DO PROFESSOR (TEM QUE RECEBER O COD_PROFESSOR) ---------------------------
    --------------------------------------------------------------------------------------------------------------------------------
    --------------------------------------------------------------------------------------------------------------------------------
    --------------------------------------------------------------------------------------------------------------------------------
    --------------------------------------------------------------------------------------------------------------------------------
    IF VERIFICAR_SE_REGISTRO_EXISTE(COD_QUESTIONARIO_VINCULADO, 'QUESTIONARIO') IS FALSE THEN
        RAISE EXCEPTION 'ESSE QUESTIONARIO AINDA NÃO FOI CADASTRADO!';
    ELSIF VERIFICAR_SE_REGISTRO_EXISTE(COD_QUESTAO_VINCULADA, 'QUESTAO') IS FALSE THEN
        RAISE EXCEPTION 'ESSA QUESTAO AINDA NÃO FOI CADASTRADA!';
    ELSIF COD_DISCIPLINA_DO_QUESTIONARIO_VINCULADO != COD_DISCIPLINA_DA_QUESTAO_VINCULADA THEN
        RAISE EXCEPTION 'NÃO SE PODE VINCULAR UMA QUESTAO A UM QUESTIONARIO DE OUTRA DISCIPLINA!';
    ELSIF VERIFICAR_VINCULO_QUESTAO_QUESTIONARIO(COD_QUESTIONARIO_VINCULADO, COD_QUESTAO_VINCULADA) IS TRUE THEN
        RAISE EXCEPTION 'ESSA QUESTÃO JÁ ESTÁ VINCULADA A ESSE QUESTIONÁRIO!';
    ELSE
        INSERT INTO QUESTAO_QUESTIONARIO VALUES (DEFAULT, COD_QUESTAO_VINCULADA, COD_QUESTIONARIO_VINCULADO);
    END IF;
END
$$ LANGUAGE plpgsql;



--*****************************************************************************************************************************************************************--
----------------------------******************************************  << QUESTAO # ALUNO >>  ******************************************----------------------------
--*****************************************************************************************************************************************************************--


--|------------------------------------------------------------------------------------------|---
--|--- ########################## SUBMETER_RESPOSTA_DE_QUESTAO ########################## ---|-----------------------------------------------------------------------
--|------------------------------------------------------------------------------------------|---
CREATE OR REPLACE FUNCTION SUBMETER_RESPOSTA_DE_QUESTAO(COD_ALUNO_ANALISADO INT, COD_QUESTAO_SUBMETIDA INT, RESPOSTA_ALUNO_SUBMETIDA TEXT)
RETURNS VOID
AS $$
BEGIN
    IF VERIFICAR_SE_REGISTRO_EXISTE(COD_ALUNO_ANALISADO, 'ALUNO') IS FALSE THEN
        RAISE EXCEPTION 'ESSE ALUNO AINDA NÃO FOI CADASTRADO!';
    ELSIF VERIFICAR_SE_REGISTRO_EXISTE(COD_QUESTAO_SUBMETIDA, 'QUESTAO') IS FALSE THEN
        RAISE EXCEPTION 'ESSA QUESTAO AINDA NÃO FOI CADASTRADA!';
    ELSIF VERIFICAR_VINCULO_QUESTAO_ALUNO(COD_ALUNO_ANALISADO, COD_QUESTAO_SUBMETIDA) IS TRUE THEN
        UPDATE QUESTAO_ALUNO SET RESPOSTA_ALUNO = RESPOSTA_ALUNO_SUBMETIDA, RESPOSTA_CORRETA = DEFAULT
        WHERE COD_ALUNO = COD_ALUNO_ANALISADO AND COD_QUESTAO = COD_QUESTAO_SUBMETIDA;
    ELSE
        INSERT INTO QUESTAO_ALUNO VALUES (DEFAULT, RESPOSTA_ALUNO_SUBMETIDA, DEFAULT, COD_QUESTAO_SUBMETIDA, COD_ALUNO_ANALISADO);
    END IF;
END
$$ LANGUAGE plpgsql;




---------------------------------------------------------------------------------------------------------------------------------------------------------------------
                      --        ####################################### FUNCTIONS DE USUÁRIOS #######################################        --
                      -- ################################################################################################################### --
---------------------------------------------------------------------------------------------------------------------------------------------------------------------


--*****************************************************************************************************************************************************************--
----------------------------*****************************************  << ALUNO # PROFESSOR >>  *****************************************----------------------------
--*****************************************************************************************************************************************************************--


--|---------------------------------------------------------------------------------------|--
--|--- ############################ USUARIO_CONSULTAR_SALDO ############################ ---|--------------------------------------------------------------------------
--|---------------------------------------------------------------------------------------|--

/* CONSULTA O SALDO DO ALUNO QUE É O USUÁRIO ATUAL */
CREATE OR REPLACE FUNCTION USUARIO_CONSULTAR_SALDO()
RETURNS TEXT
AS $$
DECLARE
	TABELA_USUARIO VARCHAR(13);
	CODIGO_USUARIO INT;
BEGIN
	PERFORM VERIFICAR_PERMISSAO_DA_TABELA_DO_USUARIO('ALUNO_OU_PROFESSOR');
	
	TABELA_USUARIO := RETORNAR_TABELA_DO_USUARIO();
	CODIGO_USUARIO := RETORNAR_CODIGO_DO_USUARIO(TABELA_USUARIO);
	
	RETURN CONSULTAR_SALDO(CODIGO_USUARIO, TABELA_USUARIO);
END
$$ LANGUAGE plpgsql;


--|---------------------------------------------------------------------------------------|--
--|--- ########################### USUARIO_ATUALIZAR_SALDO ########################### ---|--------------------------------------------------------------------------
--|---------------------------------------------------------------------------------------|--

/* USUARIO ATUALIZA SALDO INCREMENTANDO O VALOR DE SALDO A ALTERAR */
CREATE OR REPLACE FUNCTION USUARIO_ATUALIZAR_SALDO(VALOR_SALDO_A_ALTERAR FLOAT)
RETURNS VOID
AS $$
DECLARE
	TABELA_USUARIO VARCHAR(13);
	CODIGO_USUARIO INT;
BEGIN
	PERFORM VERIFICAR_PERMISSAO_DA_TABELA_DO_USUARIO('ALUNO_OU_PROFESSOR');
	
	TABELA_USUARIO := RETORNAR_TABELA_DO_USUARIO();
	CODIGO_USUARIO := RETORNAR_CODIGO_DO_USUARIO(TABELA_USUARIO);
	
	PERFORM ATUALIZAR_SALDO(VALOR_SALDO_A_ALTERAR, CODIGO_USUARIO, TABELA_USUARIO);
END
$$ LANGUAGE plpgsql;

--|-----------------------------------------------------------------------------------|--
--|--- ########################### USUARIO_SACAR_SALDO ########################### ---|------------------------------------------------------------------------------
--|-----------------------------------------------------------------------------------|--
 
/* USUARIO SACA TODO O SALDO DA TABELA */
CREATE OR REPLACE FUNCTION USUARIO_SACAR_SALDO(CODIGO INT, TABELA TEXT)
RETURNS TEXT
AS $$
DECLARE
	TABELA_USUARIO VARCHAR(13);
	CODIGO_USUARIO INT;
BEGIN
	PERFORM VERIFICAR_PERMISSAO_DA_TABELA_DO_USUARIO('ALUNO_OU_PROFESSOR');
	
	TABELA_USUARIO := RETORNAR_TABELA_DO_USUARIO();
	CODIGO_USUARIO := RETORNAR_CODIGO_DO_USUARIO(TABELA_USUARIO);
	
	RETURN SACAR_SALDO(CODIGO_USUARIO, TABELA_USUARIO);
END
$$ LANGUAGE plpgsql;



--*****************************************************************************************************************************************************************--
----------------------------*********************************************  << PROFESSOR >>  *********************************************----------------------------
--*****************************************************************************************************************************************************************--


--|---------------------------------------------------------------------------------------|--
--|--- ########################## PROFESSOR_RECEBER_SALARIO ########################## ---|--------------------------------------------------------------------------
--|---------------------------------------------------------------------------------------|--

/* FAZ O PROFESSOR RECEBER O SALÁRIO */
CREATE OR REPLACE FUNCTION PROFESSOR_RECEBER_SALARIO()
RETURNS VOID
AS $$
DECLARE
	CODIGO_USUARIO INT;
BEGIN
	PERFORM VERIFICAR_PERMISSAO_DA_TABELA_DO_USUARIO('PROFESSOR');

	CODIGO_USUARIO := RETORNAR_CODIGO_DO_USUARIO('PROFESSOR');
	
	PERFORM RECEBER_SALARIO(CODIGO_USUARIO);
END
$$ LANGUAGE plpgsql;



--*****************************************************************************************************************************************************************--
----------------------------************************************  << ALUNO_CURSO # CURSO # ALUNO >>  ************************************----------------------------
--*****************************************************************************************************************************************************************--


--|-------------------------------------------------------------------------------------|--
--|--- ############################ ALUNO_COMPRAR_CURSO ############################ ---|----------------------------------------------------------------------------
--|-------------------------------------------------------------------------------------|--

/* INSERIR OU ATUALIZAR ALUNO_CURSO QUANDO ALUNO FOR COMPRAR O CURSO */
CREATE OR REPLACE FUNCTION ALUNO_COMPRAR_CURSO(COD_CURSO_ANALISADO INT)
RETURNS VOID
AS $$
DECLARE
	CODIGO_USUARIO INT;
BEGIN
	PERFORM VERIFICAR_PERMISSAO_DA_TABELA_DO_USUARIO('ALUNO');
	
	CODIGO_USUARIO := RETORNAR_CODIGO_DO_USUARIO('ALUNO');

	PERFORM COMPRAR_CURSO(CODIGO_USUARIO, COD_CURSO_ANALISADO);
END
$$ LANGUAGE plpgsql;



--*****************************************************************************************************************************************************************--
----------------------------*****************************************  << CURSO # PROFESSOR >>  *****************************************----------------------------
--*****************************************************************************************************************************************************************--


--|-----------------------------------------------------------------------------------------|--
--|--- ############################# PROFESSOR_CRIAR_CURSO ############################# ---|------------------------------------------------------------------------
--------------------------------------------------------------------------------------------|--

/* CRIAR CURSO */
CREATE OR REPLACE FUNCTION PROFESSOR_CRIAR_CURSO(NOME_CURSO TEXT, DESCRICAO TEXT, PRECO FLOAT)
RETURNS VOID
AS $$
DECLARE
	CODIGO_USUARIO INT;
BEGIN
	PERFORM VERIFICAR_PERMISSAO_DA_TABELA_DO_USUARIO('PROFESSOR');
	
	CODIGO_USUARIO := RETORNAR_CODIGO_DO_USUARIO('PROFESSOR');

	PERFORM CRIAR_CURSO(CODIGO_USUARIO, NOME_CURSO, DESCRICAO, PRECO);
END
$$ LANGUAGE plpgsql;

--|-----------------------------------------------------------------------------------------|--
--|--- ############################ PROFESSOR_DELETAR_CURSO ############################ ---|------------------------------------------------------------------------
--------------------------------------------------------------------------------------------|--

/* DELETAR CURSO */
CREATE OR REPLACE FUNCTION PROFESSOR_DELETAR_CURSO(COD_CURSO_DELETADO INT)
RETURNS VOID
AS $$
BEGIN
	PERFORM VERIFICAR_PERMISSAO_DA_TABELA_DO_USUARIO('PROFESSOR');
	
	IF VERIFICAR_PERMISSAO_DO_USUARIO(COD_CURSO_DELETADO, 'CURSO') = FALSE THEN
		RAISE EXCEPTION 'NÃO É PERMITIDO QUE UM PROFESSOR DELETE O CURSO DE OUTRO!';
	ELSE
		PERFORM DELETAR_CURSO(COD_CURSO_DELETADO);
	END IF;
END
$$ LANGUAGE plpgsql;

--|--------------------------------------------------------------------------------------|--
--|--- ########################## PROFESSOR_PUBLICAR_CURSO ########################## ---|---------------------------------------------------------------------------
--|--------------------------------------------------------------------------------------|--

/* PROFESSOR PUBLICAR CURSO */
CREATE OR REPLACE FUNCTION PROFESSOR_PUBLICAR_CURSO(CODIGO_CURSO INT)
RETURNS VOID
AS $$
BEGIN
	PERFORM VERIFICAR_PERMISSAO_DA_TABELA_DO_USUARIO('PROFESSOR');
	
	IF VERIFICAR_PERMISSAO_DO_USUARIO(CODIGO_CURSO, 'CURSO') IS TRUE THEN
		PERFORM PUBLICAR_CURSO(CODIGO_CURSO);
	ELSE
		RAISE EXCEPTION 'NÃO É PERMITIDO QUE UM PROFESSOR PUBLIQUE O CURSO DE OUTRO!';
	END IF;
END
$$ LANGUAGE plpgsql;

--*****************************************************************************************************************************************************************--
----------------------------*****************************************  << MODULO # PROFESSOR >>  ****************************************----------------------------
--*****************************************************************************************************************************************************************--


--|-----------------------------------------------------------------------------------------|--
--|--- ############################ PROFESSOR_CRIAR_MODULO ############################# ---|------------------------------------------------------------------------
--|-----------------------------------------------------------------------------------------|--

/* CRIAR MODULOS */
CREATE OR REPLACE FUNCTION PROFESSOR_CRIAR_MODULO(CODIGO_CURSO INT, NOME_MODULO TEXT[], DESCRICAO_MODULO TEXT[], DURACAO_MODULO INT[])
RETURNS VOID
AS $$
BEGIN
	PERFORM VERIFICAR_PERMISSAO_DA_TABELA_DO_USUARIO('PROFESSOR');

	IF VERIFICAR_PERMISSAO_DO_USUARIO(CODIGO_CURSO, 'CURSO') IS TRUE THEN
		PERFORM CRIAR_MODULO(CODIGO_CURSO, NOME_MODULO, DESCRICAO_MODULO, DURACAO_MODULO);
	ELSE
		RAISE EXCEPTION 'NÃO É PERMITIDO QUE UM PROFESSOR CRIE MÓDULOS NO CURSO DE OUTRO!';
	END IF;
END
$$ LANGUAGE plpgsql;

--|--------------------------------------------------------------------------------------|--
--|--- ############################### PROFESSOR_DELETAR_MODULO ############################### ---|---------------------------------------------------------------------------
--|--------------------------------------------------------------------------------------|--

/* DELETANDO MODULO */
CREATE OR REPLACE FUNCTION PROFESSOR_DELETAR_MODULO(CODIGO_MODULO INT)
RETURNS VOID
AS $$
BEGIN
	PERFORM VERIFICAR_PERMISSAO_DA_TABELA_DO_USUARIO('PROFESSOR');
	
	IF VERIFICAR_PERMISSAO_DO_USUARIO(CODIGO_MODULO, 'MODULO') IS TRUE THEN
		PERFORM DELETAR_MODULO(CODIGO_MODULO);
	ELSE
		RAISE EXCEPTION 'NÃO É PERMITIDO QUE UM PROFESSOR REMOVA UM MÓDULO NO CURSO DE OUTRO!';
	END IF;
END
$$ LANGUAGE plpgsql;


--*****************************************************************************************************************************************************************--
----------------------------*************************************  << PRE_REQUISITO # PROFESSOR >>  *************************************----------------------------
--*****************************************************************************************************************************************************************--

--|--------------------------------------------------------------------------------------|--
--|--- ######################## PROFESSOR_CRIAR_PRE_REQUISITO ####################### ---|---------------------------------------------------------------------------
--|--------------------------------------------------------------------------------------|--

/* CRIAR PRE_REQUISITO */
CREATE OR REPLACE FUNCTION PROFESSOR_CRIAR_PRE_REQUISITO(COD_MODULO INT, COD_MODULO_PRE_REQUISITO INT)
RETURNS VOID
AS $$
BEGIN
	PERFORM VERIFICAR_PERMISSAO_DA_TABELA_DO_USUARIO('PROFESSOR');

	IF VERIFICAR_PERMISSAO_DO_USUARIO(CODIGO_MODULO, 'MODULO') IS TRUE THEN
		IF VERIFICAR_PERMISSAO_DO_USUARIO(CODIGO_MODULO_PRE_REQUISITO, 'MODULO') IS TRUE THEN
			PERFORM CRIAR_PRE_REQUISITO(COD_MODULO, COD_MODULO_PRE_REQUISITO);
		ELSE
			RAISE EXCEPTION 'NÃO É PERMITIDO QUE UM PROFESSOR USE UM MÓDULO DO CURSO DE OUTRO NO COD_MODULO_PRE_REQUISITO!';
		END IF;
	ELSE
		RAISE EXCEPTION 'NÃO É PERMITIDO QUE UM PROFESSOR USE UM MÓDULO DO CURSO DE OUTRO NO COD_MODULO!';
	END IF;
END
$$ LANGUAGE plpgsql;



--*****************************************************************************************************************************************************************--
----------------------------***************************************  << DISCIPLINA # PROFESSOR >>  **************************************----------------------------
--*****************************************************************************************************************************************************************--


--|------------------------------------------------------------------------------------------|--
--|--- ########################## PROFESSOR_CRIAR_DISCIPLINAS ########################### ---|-----------------------------------------------------------------------
--|------------------------------------------------------------------------------------------|--

/* CRIA DISCIPLINAS PARA ALGUM MODULO */
CREATE OR REPLACE FUNCTION PROFESSOR_CRIAR_DISCIPLINAS(CODIGO_MODULO INT, NOME_DISCIPLINA TEXT[], DESCRICAO_DISCIPLINA TEXT[])
RETURNS VOID
AS $$
BEGIN
	PERFORM VERIFICAR_PERMISSAO_DA_TABELA_DO_USUARIO('PROFESSOR');

	IF VERIFICAR_PERMISSAO_DO_USUARIO(CODIGO_MODULO, 'MODULO') IS TRUE THEN
		PERFORM CRIAR_DISCIPLINAS(CODIGO_MODULO, NOME_DISCIPLINA, DESCRICAO_DISCIPLINA);
	ELSE
		RAISE EXCEPTION 'NÃO É PERMITIDO QUE UM PROFESSOR CRIE DISCIPLINAS EM UM MÓDULO DO CURSO DE OUTRO!';
	END IF;
END
$$ LANGUAGE plpgsql;

--|------------------------------------------------------------------------------------------|--
--|--- ########################## PROFESSOR_DELETAR_DISCIPLINA ########################## ---|-----------------------------------------------------------------------
--|------------------------------------------------------------------------------------------|--

/* DELETANDO DISCIPLINA */
CREATE OR REPLACE FUNCTION PROFESSOR_DELETAR_DISCIPLINA(CODIGO_DISCIPLINA INT)
RETURNS VOID
AS $$
BEGIN
	PERFORM VERIFICAR_PERMISSAO_DA_TABELA_DO_USUARIO('PROFESSOR');

	IF VERIFICAR_PERMISSAO_DO_USUARIO(CODIGO_DISCIPLINA, 'DISCIPLINA') IS TRUE THEN
		PERFORM DELETAR_DISCIPLINA(CODIGO_DISCIPLINA);
	ELSE
		RAISE EXCEPTION 'NÃO É PERMITIDO QUE UM PROFESSOR REMOVA UMA DISCIPLINA EM UM MÓDULO DO CURSO DE OUTRO!';
	END IF;
END
$$ LANGUAGE plpgsql;



--*****************************************************************************************************************************************************************--
----------------------------***************************************  << VIDEO_AULA # PROFESSOR >>  **************************************----------------------------
--*****************************************************************************************************************************************************************--


--|------------------------------------------------------------------------------------------|--
--|--- ########################## PROFESSOR_CRIAR_VIDEO_AULAS ########################### ---|-----------------------------------------------------------------------
--|------------------------------------------------------------------------------------------|--

/* ADICIONANDO VIDEO AULAS AS DISCIPLINAS  */
CREATE OR REPLACE FUNCTION PROFESSOR_CRIAR_VIDEO_AULAS(CODIGO_DISCIPLINA INT, TITULO_VIDEO TEXT[], DESCRICAO TEXT[], DURACAO INT[])
RETURNS VOID
AS $$
BEGIN
	PERFORM VERIFICAR_PERMISSAO_DA_TABELA_DO_USUARIO('PROFESSOR');

	IF VERIFICAR_PERMISSAO_DO_USUARIO(CODIGO_DISCIPLINA, 'DISCIPLINA') IS TRUE THEN
		PERFORM CRIAR_VIDEO_AULAS(CODIGO_DISCIPLINA, TITULO_VIDEO, DESCRICAO, DURACAO);
	ELSE
		RAISE EXCEPTION 'NÃO É PERMITIDO QUE UM PROFESSOR CRIE VIDEO_AULAS EM UMA DISCIPLINA EM UM MÓDULO DO CURSO DE OUTRO!';
	END IF;
END
$$ LANGUAGE plpgsql;

--|------------------------------------------------------------------------------------------|--
--|--- ########################## PROFESSOR_DELETAR_VIDEO_AULA ########################## ---|-----------------------------------------------------------------------
--|------------------------------------------------------------------------------------------|--

/* DELETANDO VIDEO */
CREATE OR REPLACE FUNCTION PROFESSOR_DELETAR_VIDEO_AULA(CODIGO_VIDEO_AULA INT)
RETURNS VOID
AS $$

BEGIN
	PERFORM VERIFICAR_PERMISSAO_DA_TABELA_DO_USUARIO('PROFESSOR');

	IF VERIFICAR_PERMISSAO_DO_USUARIO(CODIGO_VIDEO_AULA, 'VIDEO_AULA') IS TRUE THEN
		PERFORM DELETAR_VIDEO_AULA(CODIGO_VIDEO_AULA);
	ELSE
		RAISE EXCEPTION 'NÃO É PERMITIDO QUE UM PROFESSOR REMOVA UMA VIDEO_AULA EM UMA DISCIPLINA EM UM MÓDULO DO CURSO DE OUTRO!';
	END IF;
END
$$ LANGUAGE plpgsql;



--*****************************************************************************************************************************************************************--
----------------------------**************************************  << ALUNO_VIDEOS_ASSISTIDOS >>  **************************************----------------------------
--*****************************************************************************************************************************************************************--


--|------------------------------------------------------------------------------------------|--
--|--- ############################## ALUNO_ASSISTIR_VIDEO_AULA ############################### ---|-----------------------------------------------------------------------
--|------------------------------------------------------------------------------------------|--

/* ASSISTIR VIDEOS */
CREATE OR REPLACE FUNCTION ALUNO_ASSISTIR_VIDEO_AULA(CODIGO_VIDEO_AULA INT)
RETURNS VOID
AS $$
DECLARE
	CODIGO_USUARIO INT;
BEGIN
	PERFORM VERIFICAR_PERMISSAO_DA_TABELA_DO_USUARIO('ALUNO');
	
	CODIGO_USUARIO := RETORNAR_CODIGO_DO_USUARIO('ALUNO');

	PERFORM ASSISTIR_VIDEO_AULA(CODIGO_USUARIO, CODIGO_VIDEO_AULA);
END
$$ LANGUAGE plpgsql;


--*****************************************************************************************************************************************************************--
----------------------------****************************************  << QUESTAO # PROFESSOR >>  ****************************************----------------------------
--*****************************************************************************************************************************************************************--


--|------------------------------------------------------------------------------------------|--
--|--- ############################ PROFESSOR_CRIAR_QUESTAO ############################# ---|-----------------------------------------------------------------------
--|------------------------------------------------------------------------------------------|--

CREATE OR REPLACE FUNCTION PROFESSOR_CRIAR_QUESTAO(CODIGO_DISCIPLINA INT, TEXTO_INSERIDO TEXT)
RETURNS VOID
AS $$
BEGIN
	PERFORM VERIFICAR_PERMISSAO_DA_TABELA_DO_USUARIO('PROFESSOR');

	IF VERIFICAR_PERMISSAO_DO_USUARIO(CODIGO_DISCIPLINA, 'DISCIPLINA') IS TRUE THEN
		PERFORM CRIAR_QUESTAO(CODIGO_DISCIPLINA, TEXTO_INSERIDO);
	ELSE
		RAISE EXCEPTION 'NÃO É PERMITIDO QUE UM PROFESSOR CRIE QUESTOES EM UMA DISCIPLINA EM UM MÓDULO DO CURSO DE OUTRO!';
	END IF;
END
$$ LANGUAGE plpgsql;

--|------------------------------------------------------------------------------------------|--
--|--- ############################ PROFESSOR_DELETAR_QUESTAO ########################### ---|-----------------------------------------------------------------------
--|------------------------------------------------------------------------------------------|--

CREATE OR REPLACE FUNCTION PROFESSOR_DELETAR_QUESTAO(CODIGO_QUESTAO INT)
RETURNS VOID
AS $$
BEGIN
	PERFORM VERIFICAR_PERMISSAO_DA_TABELA_DO_USUARIO('PROFESSOR');
	
	IF VERIFICAR_PERMISSAO_DO_USUARIO(CODIGO_QUESTAO, 'QUESTAO') IS FALSE THEN
		RAISE EXCEPTION 'NÃO É PERMITIDO QUE UM PROFESSOR REMOVA UMA QUESTAO EM UMA DISCIPLINA EM UM MÓDULO DO CURSO DE OUTRO!';
	ELSE
		DELETE FROM QUESTAO WHERE COD_QUESTAO = COD_QUESTAO_DELETADA;
	END IF;
END
$$ LANGUAGE plpgsql;

--|------------------------------------------------------------------------------------------|--
--|--- ########################### LISTAR_QUESTOES_DOS_ALUNOS ########################### ---|-----------------------------------------------------------------------
--|------------------------------------------------------------------------------------------|--

CREATE OR REPLACE FUNCTION LISTAR_QUESTOES_DOS_ALUNOS(COD_PROFESSOR_ANALISADO INT)
RETURNS TABLE(COD_QUESTAO_ALUNO INT, RESPOSTA_CORRETA VARCHAR(13), TEXTO VARCHAR(500), RESPOSTA_ALUNO VARCHAR(500))
AS $$
BEGIN
    IF VERIFICAR_SE_REGISTRO_EXISTE(COD_PROFESSOR_ANALISADO, 'PROFESSOR') IS FALSE THEN
        RAISE EXCEPTION 'ESSE PROFESSOR AINDA NÃO FOI CADASTRADO!';
    END IF;
   
    RETURN QUERY SELECT Q_A.COD_QUESTAO_ALUNO, Q_A.RESPOSTA_CORRETA, Q.TEXTO, Q_A.RESPOSTA_ALUNO FROM QUESTAO_ALUNO Q_A
    INNER JOIN QUESTAO Q ON Q_A.COD_QUESTAO = Q.COD_QUESTAO INNER JOIN QUESTAO_QUESTIONARIO Q_Q ON Q.COD_QUESTAO = Q_Q.COD_QUESTAO
    INNER JOIN QUESTIONARIO Q_R ON Q_Q.COD_QUESTIONARIO = Q_R.COD_QUESTIONARIO INNER JOIN DISCIPLINA D_C ON Q_R.COD_DISCIPLINA = D_C.COD_DISCIPLINA
    INNER JOIN MODULO M_D ON D_C.COD_MODULO = M_D.COD_MODULO INNER JOIN CURSO C_R ON M_D.COD_CURSO = C_R.COD_CURSO
    WHERE C_R.COD_PROFESSOR = COD_PROFESSOR_ANALISADO
    ORDER BY C_R.COD_CURSO, M_D.COD_MODULO, D_C.COD_DISCIPLINA, Q_R.COD_QUESTIONARIO, Q_Q.COD_QUESTAO_QUESTIONARIO, Q_Q.COD_QUESTAO, Q_A.COD_QUESTAO_ALUNO;
END
$$ LANGUAGE plpgsql;

--|------------------------------------------------------------------------------------------|--
--|--- ################################# CORRIGIR_QUESTAO ################################ --|-----------------------------------------------------------------------
--|------------------------------------------------------------------------------------------|--

CREATE OR REPLACE FUNCTION CORRIGIR_QUESTAO(COD_PROFESSOR_ANALISADO INT, COD_QUESTAO_ALUNO_CORRIGIDA INT, RESPOSTA_CORRETA_INSERIDA TEXT)
RETURNS VOID
AS $$
BEGIN
    IF VERIFICAR_SE_REGISTRO_EXISTE(COD_PROFESSOR_ANALISADO, 'PROFESSOR') IS FALSE THEN
        RAISE EXCEPTION 'ESSE PROFESSOR AINDA NÃO FOI CADASTRADO!';
    ELSIF VERIFICAR_SE_REGISTRO_EXISTE(COD_QUESTAO_ALUNO_CORRIGIDA, 'QUESTAO_ALUNO') IS FALSE THEN
        RAISE EXCEPTION 'ESSE VÍNCULO QUESTÃO_ALUNO AINDA NÃO FOI CADASTRADO!';
    ELSIF (COD_QUESTAO_ALUNO_CORRIGIDA IN (SELECT COD_QUESTAO_ALUNO FROM LISTAR_QUESTOES_DOS_ALUNOS(COD_PROFESSOR_ANALISADO))) IS FALSE THEN
        RAISE EXCEPTION 'VOCÊ NÃO TEM PERMISSÃO PARA MANIPULAÇÃO ESSE VÍNCULO QUESTÃO_ALUNO! ESSA QUESTÃO AINDA NÃO FOI POSTA EM UM QUESTIONÁRIO DE UM CURSO SEU!';
    ELSIF NOT (RESPOSTA_CORRETA_INSERIDA ILIKE 'CORRETA' OR RESPOSTA_CORRETA_INSERIDA ILIKE 'INCORRETA') THEN
        RAISE EXCEPTION 'DEVE-SE INFORMAR A RESPOSTA DO ALUNO APENAS COMO "CORRETA" OU "INCORRETA"';
    ELSE
        UPDATE QUESTAO_ALUNO SET RESPOSTA_CORRETA = RESPOSTA_CORRETA_INSERIDA WHERE COD_QUESTAO_ALUNO = COD_QUESTAO_ALUNO_CORRIGIDA;
    END IF;
END
$$ LANGUAGE plpgsql;



--*****************************************************************************************************************************************************************--
----------------------------*************************************  << QUESTIONARIO # PROFESSOR >>  **************************************----------------------------
--*****************************************************************************************************************************************************************--


--|------------------------------------------------------------------------------------------|--
--|--- ############################### CRIAR_QUESTIONARIO ############################### ---|-----------------------------------------------------------------------
--|------------------------------------------------------------------------------------------|--
 
CREATE OR REPLACE FUNCTION CRIAR_QUESTIONARIO(NOME_INSERIDO TEXT, COD_DISCIPLINA_INSERIDA INT)
RETURNS VOID
AS $$
BEGIN
    IF VERIFICAR_SE_REGISTRO_EXISTE(COD_DISCIPLINA_INSERIDA, 'DISCIPLINA') IS FALSE THEN
        RAISE EXCEPTION 'ESSA DISCIPLINA AINDA NÃO FOI CADASTRADA!';
    ELSE
        INSERT INTO QUESTIONARIO VALUES (DEFAULT, NOME_INSERIDO, COD_DISCIPLINA_INSERIDA);
    END IF;
END
$$ LANGUAGE plpgsql;
 
--|------------------------------------------------------------------------------------------|---
--|--- ############################## DELETAR_QUESTIONARIO ############################## ---|-----------------------------------------------------------------------
--|------------------------------------------------------------------------------------------|---

CREATE OR REPLACE FUNCTION DELETAR_QUESTIONARIO(COD_QUESTIONARIO_DELETADO INT)
RETURNS VOID
AS $$
BEGIN
    IF VERIFICAR_SE_REGISTRO_EXISTE(COD_QUESTIONARIO_DELETADO, 'QUESTIONARIO') IS FALSE THEN
        RAISE EXCEPTION 'ESSE QUESTIONARIO AINDA NÃO FOI CADASTRADO!';
    ELSE
        DELETE FROM QUESTIONARIO WHERE COD_QUESTIONARIO = COD_QUESTIONARIO_DELETADO;
    END IF;
END
$$ LANGUAGE plpgsql;



--*****************************************************************************************************************************************************************--
----------------------------*********************************  << QUESTAO_QUESTIONARIO # PROFESSOR >>  **********************************----------------------------
--*****************************************************************************************************************************************************************--


--|------------------------------------------------------------------------------------------|--
--|--- ######################## VINCULAR_QUESTAO_A_QUESTIONARIO ######################### ---|-----------------------------------------------------------------------
--|------------------------------------------------------------------------------------------|--

CREATE OR REPLACE FUNCTION VINCULAR_QUESTAO_A_QUESTIONARIO(COD_QUESTIONARIO_VINCULADO INT, COD_QUESTAO_VINCULADA INT)
RETURNS VOID
AS $$
DECLARE
    COD_DISCIPLINA_DO_QUESTIONARIO_VINCULADO INT := (SELECT COD_DISCIPLINA FROM QUESTIONARIO WHERE COD_QUESTIONARIO = COD_QUESTIONARIO_VINCULADO);
    COD_DISCIPLINA_DA_QUESTAO_VINCULADA INT := (SELECT COD_DISCIPLINA FROM QUESTAO WHERE COD_QUESTAO = COD_QUESTAO_VINCULADA);
BEGIN
    --------------------------------------------------------------------------------------------------------------------------------
    --------------------------------------------------------------------------------------------------------------------------------
    --------------------------------------------------------------------------------------------------------------------------------
    --------------------------------------------------------------------------------------------------------------------------------
    ------------------------- VERIFICAR SE A DISCIPLINA É DO PROFESSOR (TEM QUE RECEBER O COD_PROFESSOR) ---------------------------
    --------------------------------------------------------------------------------------------------------------------------------
    --------------------------------------------------------------------------------------------------------------------------------
    --------------------------------------------------------------------------------------------------------------------------------
    --------------------------------------------------------------------------------------------------------------------------------
    IF VERIFICAR_SE_REGISTRO_EXISTE(COD_QUESTIONARIO_VINCULADO, 'QUESTIONARIO') IS FALSE THEN
        RAISE EXCEPTION 'ESSE QUESTIONARIO AINDA NÃO FOI CADASTRADO!';
    ELSIF VERIFICAR_SE_REGISTRO_EXISTE(COD_QUESTAO_VINCULADA, 'QUESTAO') IS FALSE THEN
        RAISE EXCEPTION 'ESSA QUESTAO AINDA NÃO FOI CADASTRADA!';
    ELSIF COD_DISCIPLINA_DO_QUESTIONARIO_VINCULADO != COD_DISCIPLINA_DA_QUESTAO_VINCULADA THEN
        RAISE EXCEPTION 'NÃO SE PODE VINCULAR UMA QUESTAO A UM QUESTIONARIO DE OUTRA DISCIPLINA!';
    ELSIF VERIFICAR_VINCULO_QUESTAO_QUESTIONARIO(COD_QUESTIONARIO_VINCULADO, COD_QUESTAO_VINCULADA) IS TRUE THEN
        RAISE EXCEPTION 'ESSA QUESTÃO JÁ ESTÁ VINCULADA A ESSE QUESTIONÁRIO!';
    ELSE
        INSERT INTO QUESTAO_QUESTIONARIO VALUES (DEFAULT, COD_QUESTAO_VINCULADA, COD_QUESTIONARIO_VINCULADO);
    END IF;
END
$$ LANGUAGE plpgsql;



--*****************************************************************************************************************************************************************--
----------------------------******************************************  << QUESTAO # ALUNO >>  ******************************************----------------------------
--*****************************************************************************************************************************************************************--


--|------------------------------------------------------------------------------------------|---
--|--- ########################## SUBMETER_RESPOSTA_DE_QUESTAO ########################## ---|-----------------------------------------------------------------------
--|------------------------------------------------------------------------------------------|---
CREATE OR REPLACE FUNCTION SUBMETER_RESPOSTA_DE_QUESTAO(COD_ALUNO_ANALISADO INT, COD_QUESTAO_SUBMETIDA INT, RESPOSTA_ALUNO_SUBMETIDA TEXT)
RETURNS VOID
AS $$
BEGIN
    IF VERIFICAR_SE_REGISTRO_EXISTE(COD_ALUNO_ANALISADO, 'ALUNO') IS FALSE THEN
        RAISE EXCEPTION 'ESSE ALUNO AINDA NÃO FOI CADASTRADO!';
    ELSIF VERIFICAR_SE_REGISTRO_EXISTE(COD_QUESTAO_SUBMETIDA, 'QUESTAO') IS FALSE THEN
        RAISE EXCEPTION 'ESSA QUESTAO AINDA NÃO FOI CADASTRADA!';
    ELSIF VERIFICAR_VINCULO_QUESTAO_ALUNO(COD_ALUNO_ANALISADO, COD_QUESTAO_SUBMETIDA) IS TRUE THEN
        UPDATE QUESTAO_ALUNO SET RESPOSTA_ALUNO = RESPOSTA_ALUNO_SUBMETIDA, RESPOSTA_CORRETA = DEFAULT
        WHERE COD_ALUNO = COD_ALUNO_ANALISADO AND COD_QUESTAO = COD_QUESTAO_SUBMETIDA;
    ELSE
        INSERT INTO QUESTAO_ALUNO VALUES (DEFAULT, RESPOSTA_ALUNO_SUBMETIDA, DEFAULT, COD_QUESTAO_SUBMETIDA, COD_ALUNO_ANALISADO);
    END IF;
END
$$ LANGUAGE plpgsql;




---------------------------------------------------------------------------------------------------------------------------------------------------------------------
                      --        ####################################### FUNCTIONS DE TRIGGERS #######################################        --
                      -- ################################################################################################################### --
---------------------------------------------------------------------------------------------------------------------------------------------------------------------

--|------------------------------------------------------------------------------------------|---
--|--- ################################ VERIFICA_INSERCAO ############################### ---|-----------------------------------------------------------------------
--|------------------------------------------------------------------------------------------|---

/* FUNCTION REGRA DE NEGOCIO DA INSERÇÃO */
CREATE OR REPLACE FUNCTION VERIFICA_INSERCAO_ALUNO()
RETURNS TRIGGER
AS $$
DECLARE
    IDADE INT := RETORNA_IDADE(NEW.DATA_NASCIMENTO);
    CPF_ALUNO_EXISTENTE TEXT := USUARIO_EXISTENTE(NEW.CPF, 'ALUNO');
    EMAIL_ALUNO_EXISTENTE TEXT := EMAIL_USUARIO_EXISTENTE(NEW.EMAIL, 'ALUNO');
    CPF_PROFESSOR_EXISTENTE TEXT := USUARIO_EXISTENTE(NEW.CPF, 'PROFESSOR');
    EMAIL_PROFESSOR_EXISTENTE TEXT := EMAIL_USUARIO_EXISTENTE(NEW.EMAIL, 'PROFESSOR');
BEGIN
   
    IF IDADE < 18 THEN
        RAISE EXCEPTION 'VOCÊ É MENOR DE IDADE, CADASTRO REJEITADO!';
 
    ELSIF NEW.CPF = CPF_ALUNO_EXISTENTE THEN
        RAISE EXCEPTION 'JÁ EXISTE UM ALUNO CADASTRADO COM ESSE CPF, INSIRA UM CPF VALIDO.';
   
    ELSIF NEW.EMAIL = EMAIL_ALUNO_EXISTENTE THEN
        RAISE EXCEPTION 'ESSE EMAIL JÁ CONSTA EM UM CADASTRO ALUNO, INSIRA UM EMAIL VALIDO.';
   
    ELSIF NEW.CPF = CPF_PROFESSOR_EXISTENTE THEN
        RAISE EXCEPTION 'JÁ EXISTE UM PROFESSOR CADASTRADO COM ESSE CPF, INSIRA UM CPF VALIDO.';
   
    ELSIF NEW.EMAIL = EMAIL_PROFESSOR_EXISTENTE THEN
        RAISE EXCEPTION 'ESSE EMAIL JÁ CONSTA EM UM CADASTRO PROFESSOR, INSIRA UM EMAIL VALIDO.';
    END IF;

    EXECUTE FORMAT('CREATE USER "%s" LOGIN PASSWORD ''%s'' IN GROUP ALUNO', NEW.EMAIL, NEW.SENHA);
   
    RETURN NEW;
END
$$ LANGUAGE plpgsql;

/* FUNCTION REGRA DE NEGOCIO DA INSERÇÃO */
CREATE OR REPLACE FUNCTION VERIFICA_INSERCAO_PROFESSOR()
RETURNS TRIGGER
AS $$
DECLARE
    IDADE INT := RETORNA_IDADE(NEW.DATA_NASCIMENTO);
    CPF_ALUNO_EXISTENTE TEXT := USUARIO_EXISTENTE(NEW.CPF, 'ALUNO');
    EMAIL_ALUNO_EXISTENTE TEXT := EMAIL_USUARIO_EXISTENTE(NEW.EMAIL, 'ALUNO');
    CPF_PROFESSOR_EXISTENTE TEXT := USUARIO_EXISTENTE(NEW.CPF, 'PROFESSOR');
    EMAIL_PROFESSOR_EXISTENTE TEXT := EMAIL_USUARIO_EXISTENTE(NEW.EMAIL, 'PROFESSOR');
BEGIN
   
    IF IDADE < 18 THEN
        RAISE EXCEPTION 'VOCÊ É MENOR DE IDADE, CADASTRO REJEITADO!';
 
    ELSIF NEW.CPF = CPF_ALUNO_EXISTENTE THEN
        RAISE EXCEPTION 'JÁ EXISTE UM ALUNO CADASTRADO COM ESSE CPF, INSIRA UM CPF VALIDO.';
   
    ELSIF NEW.EMAIL = EMAIL_ALUNO_EXISTENTE THEN
        RAISE EXCEPTION 'ESSE EMAIL JÁ CONSTA EM UM CADASTRO ALUNO, INSIRA UM EMAIL VALIDO.';
   
    ELSIF NEW.CPF = CPF_PROFESSOR_EXISTENTE THEN
        RAISE EXCEPTION 'JÁ EXISTE UM PROFESSOR CADASTRADO COM ESSE CPF, INSIRA UM CPF VALIDO.';
   
    ELSIF NEW.EMAIL = EMAIL_PROFESSOR_EXISTENTE THEN
        RAISE EXCEPTION 'ESSE EMAIL JÁ CONSTA EM UM CADASTRO PROFESSOR, INSIRA UM EMAIL VALIDO.';
    END IF;

    EXECUTE FORMAT('CREATE USER "%s" LOGIN PASSWORD ''%s'' IN GROUP PROFESSOR', NEW.EMAIL, NEW.SENHA);
   
    RETURN NEW;
END
$$ LANGUAGE plpgsql;

--|------------------------------------------------------------------------------------------|---
--|--- ################################ VERIFICA_DELECAO ################################ ---|-----------------------------------------------------------------------
--|------------------------------------------------------------------------------------------|---

CREATE OR REPLACE FUNCTION VERIFICA_DELECAO()
RETURNS TRIGGER
AS $$
BEGIN
	EXECUTE FORMAT('DROP USER "%s"', OLD.EMAIL);
	RETURN OLD;
END
$$ LANGUAGE plpgsql;

--|------------------------------------------------------------------------------------------|---
--|--- ############################# EVENTO_RECEBER_SALARIO ############################# ---|-----------------------------------------------------------------------
--|------------------------------------------------------------------------------------------|---

CREATE OR REPLACE FUNCTION EVENTO_RECEBER_SALARIO()
RETURNS TRIGGER
AS $$
DECLARE
    COD_PROFESSOR_ANALISADO INT;
BEGIN
    SELECT P_F.COD_PROFESSOR INTO COD_PROFESSOR_ANALISADO FROM ALUNO_CURSO A_C INNER JOIN CURSO C_R ON A_C.COD_CURSO = C_R.COD_CURSO INNER JOIN PROFESSOR P_F ON C_R.COD_PROFESSOR = P_F.COD_PROFESSOR WHERE A_C.COD_ALUNO_CURSO = NEW.COD_ALUNO_CURSO;
    PERFORM RECEBER_SALARIO(COD_PROFESSOR_ANALISADO);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

--|------------------------------------------------------------------------------------------|---
--|--- ############################### EVENTO_MODULO_CURSO ############################## ---|-----------------------------------------------------------------------
--|------------------------------------------------------------------------------------------|---

CREATE OR REPLACE FUNCTION EVENTO_MODULO_CURSO()
RETURNS TRIGGER
AS $$
BEGIN
   
    IF TG_OP = 'DELETE' THEN
        IF VALIDAR_CURSO(OLD.COD_CURSO) = FALSE THEN
            UPDATE CURSO SET DISPONIBILIDADE = FALSE WHERE COD_CURSO = OLD.COD_CURSO;
            UPDATE CURSO SET PUBLICADO = FALSE WHERE COD_CURSO = OLD.COD_CURSO;
        END IF;
    END IF;
   
    RETURN NEW;
 
END
$$ LANGUAGE plpgsql;

--|------------------------------------------------------------------------------------------|---
--|--- ############################### EVENTOS_ALUNO_CURSO ############################## ---|-----------------------------------------------------------------------
--|------------------------------------------------------------------------------------------|---
CREATE OR REPLACE FUNCTION EVENTOS_ALUNO_CURSO()
RETURNS TRIGGER
AS $$
BEGIN
   
    IF TG_OP = 'INSERT' THEN
        PERFORM STATUS_ALUNO_MODULO(NEW.COD_ALUNO, NEW.COD_CURSO);
    END IF;
   
    RETURN NEW;
 
END
$$ LANGUAGE plpgsql;

--|------------------------------------------------------------------------------------------|---
--|--- ########################## EVENTO_MODULO_META_CONCLUIDA ########################## ---|-----------------------------------------------------------------------
--|------------------------------------------------------------------------------------------|---

CREATE OR REPLACE FUNCTION EVENTO_MODULO_META_CONCLUIDA()
RETURNS TRIGGER
AS $$
DECLARE
    CODIGO_MODULO INT := (SELECT M_D.COD_MODULO FROM MODULO M_D INNER JOIN DISCIPLINA D_C ON
                          M_D.COD_MODULO = D_C.COD_MODULO INNER JOIN VIDEO_AULA V_L ON D_C.COD_DISCIPLINA = V_L.COD_DISCIPLINA
                          WHERE V_L.COD_VIDEO_AULA = NEW.COD_VIDEO_AULA);
    CODIGO_ALUNO INT := (SELECT A_L.COD_ALUNO FROM ALUNO A_L INNER JOIN ALUNO_CURSO A_C ON
                         A_L.COD_ALUNO = A_C.COD_ALUNO WHERE A_C.COD_ALUNO = NEW.COD_ALUNO);
    META_MODULO_PORCENTAGEM FLOAT := TRUNC((QUANTIDADE_VIDEOS_ASSISTIDOS(CODIGO_ALUNO)::DECIMAL / QUANTIDADE_VIDEOS_MODULO(NEW.COD_VIDEO_AULA)::DECIMAL), 1);
BEGIN
   
    IF TG_OP = 'INSERT' THEN
        RAISE NOTICE 'QUANTIDADE VIDEOS MODULO: %', QUANTIDADE_VIDEOS_MODULO(NEW.COD_VIDEO_AULA);
        RAISE NOTICE 'QUANTIDADE VIDEOS ASSISTIDOS: %', QUANTIDADE_VIDEOS_ASSISTIDOS(CODIGO_ALUNO);
        RAISE NOTICE 'RESULTADO DIVISÃO: %', META_MODULO_PORCENTAGEM;
        IF META_MODULO_PORCENTAGEM >= 0.6 THEN
            UPDATE ALUNO_MODULO SET META_CONCLUIDA = TRUE WHERE COD_ALUNO = NEW.COD_ALUNO AND COD_MODULO = CODIGO_MODULO;
        END IF;
    END IF;
    RETURN NEW;
 
END
$$ LANGUAGE plpgsql;

--|------------------------------------------------------------------------------------------|---
--|--- ############################# ATIVACAO_PRE_REQUISITO ############################# ---|-----------------------------------------------------------------------
--|------------------------------------------------------------------------------------------|---

CREATE OR REPLACE FUNCTION ATIVACAO_PRE_REQUISITO()
RETURNS TRIGGER
AS $$
BEGIN
	IF OLD.META_CONCLUIDA IS FALSE AND NEW.META_CONCLUIDA IS TRUE THEN
		PERFORM VERIFICAR_SE_MODULOS_FICAM_ACESSIVEIS(NEW.COD_MODULO);
	END IF;
	
	RETURN NEW;
END
$$ LANGUAGE plpgsql;

--|------------------------------------------------------------------------------------------|---
--|--- ####################### EVENTO_INSERT_UPDATE_PRE_REQUISITO ####################### ---|-----------------------------------------------------------------------
--|------------------------------------------------------------------------------------------|---

CREATE OR REPLACE FUNCTION EVENTO_INSERT_UPDATE_PRE_REQUISITO()
RETURNS TRIGGER
AS $$
BEGIN
	IF VERIFICAR_VALIDADE_PRE_REQUISITO(NEW.COD_MODULO, NEW.COD_MODULO_PRE_REQUISITO) IS FALSE THEN
		RAISE EXCEPTION 'VOCÊ NÃO PODE FAZER ESSA RELAÇÃO MODULO - MODULO_PRE_REQUISITO. PRE-REQUITOS ENTRAM EM IMPASSE!';
	ELSE
		RETURN NEW;
	END IF;
	
END
$$ LANGUAGE plpgsql;

--|------------------------------------------------------------------------------------------|---
--|--- ############################ EVENTO_DISCIPLINA_CURSO ############################# ---|-----------------------------------------------------------------------
--|------------------------------------------------------------------------------------------|---

CREATE OR REPLACE FUNCTION EVENTO_DISCIPLINA_CURSO()
RETURNS TRIGGER
AS $$
DECLARE
    OLD_COD_CURSO INT := (SELECT COD_CURSO FROM MODULO M_D WHERE M_D.COD_MODULO = OLD.COD_MODULO);
BEGIN
   
    IF TG_OP = 'DELETE' THEN
        IF VALIDAR_CURSO(OLD_COD_CURSO) = FALSE THEN
            UPDATE CURSO SET DISPONIBILIDADE = FALSE WHERE COD_CURSO = OLD_COD_CURSO;
            UPDATE CURSO SET PUBLICADO = FALSE WHERE COD_CURSO = OLD_COD_CURSO;
        END IF;
    END IF;
 
    RETURN NEW;
   
END
$$ LANGUAGE plpgsql;

--|------------------------------------------------------------------------------------------|---
--|--- ############################### EVENTO_VIDEO_CURSO ############################### ---|-----------------------------------------------------------------------
--|------------------------------------------------------------------------------------------|---

CREATE OR REPLACE FUNCTION EVENTO_VIDEO_CURSO()
RETURNS TRIGGER
AS $$
DECLARE
	NEW_COD_CURSO INT;
	OLD_COD_CURSO INT;
BEGIN
   
    IF TG_OP = 'INSERT' THEN
	SELECT M_D.COD_CURSO INTO NEW_COD_CURSO FROM MODULO M_D WHERE M_D.COD_MODULO = (SELECT D_C.COD_MODULO FROM DISCIPLINA D_C WHERE D_C.COD_DISCIPLINA = NEW.COD_DISCIPLINA);
        IF VALIDAR_CURSO(NEW_COD_CURSO) = TRUE THEN
            UPDATE CURSO SET DISPONIBILIDADE = TRUE WHERE COD_CURSO = NEW_COD_CURSO;
        END IF;
       
    ELSIF TG_OP = 'DELETE' THEN
	SELECT COD_CURSO INTO OLD_COD_CURSO FROM MODULO M_D WHERE M_D.COD_MODULO = (SELECT D_C.COD_MODULO FROM DISCIPLINA D_C WHERE D_C.COD_DISCIPLINA = OLD.COD_DISCIPLINA);
        IF VALIDAR_CURSO(NEW_COD_CURSO) = FALSE THEN
            UPDATE CURSO SET DISPONIBILIDADE = FALSE WHERE COD_CURSO = OLD_COD_CURSO;
            UPDATE CURSO SET PUBLICADO = FALSE WHERE COD_CURSO = OLD_COD_CURSO;
        END IF;
    END IF;
   
    RETURN NEW;
 
END
$$ LANGUAGE plpgsql;



--|------------------------------------------------------------------------------------------|---
--|--- ############################ VERIFICAR_INSERT_QUESTAO ############################ ---|-----------------------------------------------------------------------
--|------------------------------------------------------------------------------------------|---

CREATE OR REPLACE FUNCTION VERIFICAR_INSERT_QUESTAO()
RETURNS TRIGGER
AS $$
BEGIN
	IF TG_OP = 'INSERT' THEN
		IF LENGTH(NEW.TEXTO) < 10 THEN
			RAISE EXCEPTION 'TEXTO DA QUESTÃO MUITO CURTO (MENOS DE 10 CARACTERES) INVÁLIDO!';
		END IF;
	END IF;
   
	RETURN NEW;
 
END
$$ LANGUAGE plpgsql;


---------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- ############################################################################################################################################################### --
-- ########################################################################## TRIGGERS ########################################################################### --
-- ############################################################################################################################################################### --
---------------------------------------------------------------------------------------------------------------------------------------------------------------------


--*****************************************************************************************************************************************************************--
----------------------------**********************************************  << ALUNO >>  ************************************************----------------------------
--*****************************************************************************************************************************************************************--


--|------------------------------------------------------------------------------------------|---
--|--- ############################ EVENTOS_DE_INSERCAO_ALUNO ########################### ---|-----------------------------------------------------------------------
--|------------------------------------------------------------------------------------------|---

/* TRIGGER INSERT ALUNO */
CREATE TRIGGER EVENTOS_DE_INSERCAO_ALUNO
BEFORE INSERT ON ALUNO
FOR EACH ROW
EXECUTE PROCEDURE VERIFICA_INSERCAO_ALUNO();

--|------------------------------------------------------------------------------------------|---
--|--- ############################ EVENTOS_DE_DELECAO_ALUNO ############################ ---|-----------------------------------------------------------------------
--|------------------------------------------------------------------------------------------|---

/* TRIGGER DELETE ALUNO */
CREATE TRIGGER EVENTOS_DE_DELECAO_ALUNO
BEFORE DELETE ON ALUNO
FOR EACH ROW
EXECUTE PROCEDURE VERIFICA_DELECAO();



--*****************************************************************************************************************************************************************--
----------------------------********************************************  << PROFESSOR >>  **********************************************----------------------------
--*****************************************************************************************************************************************************************--


--|------------------------------------------------------------------------------------------|---
--|--- ########################## EVENTOS_DE_INSERCAO_PROFESSOR ######################### ---|-----------------------------------------------------------------------
--|------------------------------------------------------------------------------------------|---

/* TRIGGER INSERT PROFESSOR */
CREATE TRIGGER EVENTOS_DE_INSERCAO_PROFESSOR
BEFORE INSERT ON PROFESSOR
FOR EACH ROW
EXECUTE PROCEDURE VERIFICA_INSERCAO_PROFESSOR();



--*****************************************************************************************************************************************************************--
----------------------------**********************************************  << CURSO >>  ************************************************----------------------------
--*****************************************************************************************************************************************************************--




--*****************************************************************************************************************************************************************--
----------------------------*********************************************  << ALUNO_CURSO >>  ********************************************----------------------------
--*****************************************************************************************************************************************************************--


--|------------------------------------------------------------------------------------------|---
--|--- ############################### EVENTO_ALUNO_CURSO ############################### ---|-----------------------------------------------------------------------
--|------------------------------------------------------------------------------------------|---

CREATE TRIGGER EVENTO_ALUNO_CURSO
AFTER INSERT OR UPDATE ON ALUNO_CURSO
FOR EACH ROW
EXECUTE PROCEDURE EVENTOS_ALUNO_CURSO();

/* UPDATE QUANDO FOR SATISFEITO A MEDIA DE VIDEOS ASSISTIDOS PELO MODULO PARA ALTERAR O BOOLEAN
META_CONCLUIDA */

--|------------------------------------------------------------------------------------------|---
--|--- ####################### ALUNO_ATIVAR_EVENTO_RECEBER_SALARIO ###################### ---|-----------------------------------------------------------------------
--|------------------------------------------------------------------------------------------|---

CREATE TRIGGER ALUNO_ATIVAR_EVENTO_RECEBER_SALARIO
AFTER INSERT OR UPDATE
ON ALUNO_CURSO FOR EACH ROW
EXECUTE PROCEDURE EVENTO_RECEBER_SALARIO();



--*****************************************************************************************************************************************************************--
----------------------------**********************************************  << MODULO >>  ***********************************************----------------------------
--*****************************************************************************************************************************************************************--


--|------------------------------------------------------------------------------------------|---
--|--- ################### EVENTO_ANALISA_DISPONIBILIDADE_CURSO_MODULO ################## ---|-----------------------------------------------------------------------
--|------------------------------------------------------------------------------------------|---

CREATE TRIGGER EVENTO_ANALISA_DISPONIBILIDADE_CURSO_MODULO
AFTER DELETE ON MODULO
FOR EACH ROW
EXECUTE PROCEDURE EVENTO_MODULO_CURSO();



--*****************************************************************************************************************************************************************--
----------------------------*******************************************  << ALUNO_MODULO >>  ********************************************----------------------------
--*****************************************************************************************************************************************************************--


--|------------------------------------------------------------------------------------------|---
--|--- ######################### TRIGGER_ATIVACAO_PRE_REQUISITO ######################### ---|-----------------------------------------------------------------------
--|------------------------------------------------------------------------------------------|---

CREATE TRIGGER TRIGGER_ATIVACAO_PRE_REQUISITO
AFTER UPDATE
ON ALUNO_MODULO FOR EACH ROW
EXECUTE PROCEDURE ATIVACAO_PRE_REQUISITO();



--*****************************************************************************************************************************************************************--
----------------------------*******************************************  << PRE_REQUISITO >>  *******************************************----------------------------
--*****************************************************************************************************************************************************************--


--|------------------------------------------------------------------------------------------|---
--|--- ############################## TRIGGER_PRE_REQUISITO ############################# ---|-----------------------------------------------------------------------
--|------------------------------------------------------------------------------------------|---

CREATE TRIGGER TRIGGER_PRE_REQUISITO
BEFORE INSERT OR UPDATE
ON PRE_REQUISITO FOR EACH ROW
EXECUTE PROCEDURE EVENTO_INSERT_UPDATE_PRE_REQUISITO();

-- DROP TRIGGER TRIGGER_PRE_REQUISITO ON PRE_REQUISITO


--*****************************************************************************************************************************************************************--
----------------------------********************************************  << DISCIPLINA >>  *********************************************----------------------------
--*****************************************************************************************************************************************************************--


--|------------------------------------------------------------------------------------------|---
--|--- ################# EVENTO_ANALISA_DISPONIBILIDADE_CURSO_DISCIPLINA ################ ---|-----------------------------------------------------------------------
--|------------------------------------------------------------------------------------------|---

CREATE TRIGGER EVENTO_ANALISA_DISPONIBILIDADE_CURSO_DISCIPLINA
AFTER DELETE ON DISCIPLINA
FOR EACH ROW
EXECUTE PROCEDURE EVENTO_DISCIPLINA_CURSO();



--*****************************************************************************************************************************************************************--
----------------------------********************************************  << VIDEO_AULA >>  *********************************************----------------------------
--*****************************************************************************************************************************************************************--


--|------------------------------------------------------------------------------------------|---
--|--- ################### EVENTO_ANALISA_DISPONIBILIDADE_CURSO_VIDEO ################### ---|-----------------------------------------------------------------------
--|------------------------------------------------------------------------------------------|---

CREATE TRIGGER EVENTO_ANALISA_DISPONIBILIDADE_CURSO_VIDEO
AFTER INSERT OR DELETE ON VIDEO_AULA
FOR EACH ROW
EXECUTE PROCEDURE EVENTO_VIDEO_CURSO();



--*****************************************************************************************************************************************************************--
----------------------------*************************************  << ALUNO_VIDEOS_ASSISTIDOS >>  ***************************************----------------------------
--*****************************************************************************************************************************************************************--


--|------------------------------------------------------------------------------------------|---
--|--- ############################## MODULO_META_CONLUIDA ############################## ---|-----------------------------------------------------------------------
--|------------------------------------------------------------------------------------------|---

CREATE TRIGGER MODULO_META_CONLUIDA
AFTER INSERT ON ALUNO_VIDEOS_ASSISTIDOS
FOR EACH ROW
EXECUTE PROCEDURE EVENTO_MODULO_META_CONCLUIDA();



--*****************************************************************************************************************************************************************--
----------------------------*********************************************  << QUESTAO >>  ***********************************************----------------------------
--*****************************************************************************************************************************************************************--


--|------------------------------------------------------------------------------------------|---
--|--- ############################# EVENTO_INSERT_QUESTAO ############################## ---|-----------------------------------------------------------------------
--|------------------------------------------------------------------------------------------|---

CREATE TRIGGER EVENTO_INSERT_QUESTAO
BEFORE INSERT ON QUESTAO
FOR EACH ROW
EXECUTE PROCEDURE VERIFICAR_INSERT_QUESTAO();



--*****************************************************************************************************************************************************************--
----------------------------*******************************************  << QUESTIONARIO >>  ********************************************----------------------------
--*****************************************************************************************************************************************************************--




--*****************************************************************************************************************************************************************--
----------------------------***************************************  << QUESTAO_QUESTIONARIO >>  ****************************************----------------------------
--*****************************************************************************************************************************************************************--




--*****************************************************************************************************************************************************************--
----------------------------******************************************  << QUESTAO_ALUNO >>  ********************************************----------------------------
--*****************************************************************************************************************************************************************--





---------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- ############################################################################################################################################################### --
-- ################################################################### FUNÇÕES AINDA NÃO USADAS ################################################################## --
-- ############################################################################################################################################################### --
---------------------------------------------------------------------------------------------------------------------------------------------------------------------


 
/* RETORNA COD_PROFESSOR */
CREATE OR REPLACE FUNCTION RETORNA_COD_PROFESSOR(CPF_PROFESSOR TEXT)
RETURNS TABLE (PROFESSOR_CODIGO INT)
AS $$
BEGIN
    RETURN QUERY SELECT COD_PROFESSOR FROM PROFESSOR P_F WHERE P_F.CPF = CPF_PROFESSOR;
END
$$ LANGUAGE plpgsql;
 

---------------------------------------------------------------------------------------------------------------------------------------------------------------------
/* MODULO ACESSÍVEL */
CREATE OR REPLACE FUNCTION MODULO_STATUS_ALUNO(CODIGO_MODULO INT)
RETURNS BOOLEAN
AS $$
DECLARE
    STATUS BOOLEAN;
BEGIN
    SELECT M_D.ACESSIVEL INTO STATUS FROM MODULO M_D WHERE M_D.COD_MODULO = CODIGO_MODULO;
    RETURN STATUS;
END
$$ LANGUAGE plpgsql;


---------------------------------------------------------------------------------------------------------------------------------------------------------------------

/* VERIFICA SE DETERMINADO SALDO É SUFICIENTE TENDO EM VISTA O VALOR REQUERIDO */
CREATE OR REPLACE FUNCTION SALDO_SUFICIENTE_PARA_COMPRA(SALDO FLOAT, VALOR_REQUERIDO FLOAT)
RETURNS BOOLEAN
AS $$
BEGIN
    IF SALDO >= VALOR_REQUERIDO THEN
        RETURN TRUE;
    ELSE
        RETURN FALSE;
    END IF;
    RETURN FALSE;
END
$$ LANGUAGE plpgsql;

---------------------------------------------------------------------------------------------------------------------------------------------------------------------
/* SELECIONA O SALDO DA TABELA */
CREATE OR REPLACE FUNCTION SELECIONAR_SALDO(COD_ANALISADO INT, TABELA TEXT)
RETURNS FLOAT
AS $$
DECLARE
    SALDO_SELECIONADO FLOAT;
BEGIN
    IF TABELA = 'ALUNO' THEN
        SELECT SALDO INTO SALDO_SELECIONADO FROM ALUNO WHERE COD_ANALISADO = COD_ALUNO;
    ELSIF TABELA = 'PROFESSOR' THEN
        SELECT SALDO INTO SALDO_SELECIONADO FROM PROFESSOR WHERE COD_ANALISADO = COD_PROFESSOR;
    END IF;
    RETURN SALDO_SELECIONADO;
END
$$ LANGUAGE plpgsql;


---------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- ############################################################################################################################################################### --
-- ########################################################################## EXECUÇÕES ########################################################################## --
-- ############################################################################################################################################################### --
---------------------------------------------------------------------------------------------------------------------------------------------------------------------

 
SELECT * FROM ALUNO_MODULO
SELECT * FROM PRE_REQUISITO
SELECT * FROM ALUNO_CURSO
SELECT * FROM ALUNO
SELECT * FROM PROFESSOR
SELECT * FROM CURSO
SELECT * FROM MODULO
SELECT * FROM DISCIPLINA
SELECT * FROM VIDEO_AULA
SELECT * FROM ALUNO_VIDEOS_ASSISTIDOS
SELECT * FROM QUESTAO
SELECT * FROM QUESTIONARIO


/* PARAMENTROS COD_USUARIO, NOME, CPF, DATA_NASCIMENTO, EMAIL, SENHA, TABELA */
SELECT FROM INSERIR_ALUNO_E_PROFESSOR
('NELSON', '11223344555', '1992-07-23', 'NELSON@GMAIL.COM', '123', 'ALUNO'); -- COD_ALUNO: 1
SELECT FROM INSERIR_ALUNO_E_PROFESSOR
('CARLOS', '22334455666', '1990-01-23', 'CARLOS@GMAIL.COM', '123', 'ALUNO'); -- COD_ALUNO: 2
SELECT FROM INSERIR_ALUNO_E_PROFESSOR
('FELIPE', '33445566777', '2000-06-09', 'FELIPE@GMAIL.COM', '123', 'ALUNO'); -- COD_ALUNO: 3
SELECT FROM INSERIR_ALUNO_E_PROFESSOR
('JOHN', '44556677888', '2000-02-10', 'JOHN@GMAIL.COM', '123', 'ALUNO'); -- COD_ALUNO: 4
SELECT FROM INSERIR_ALUNO_E_PROFESSOR
('ELCY', '55667788999', '1998-10-08', 'ELCY@GMAIL.COM', '123', 'ALUNO'); -- COD_ALUNO: 5

SELECT FROM INSERIR_ALUNO_E_PROFESSOR
('GEOVANE', '12345678912', '1986-05-02', 'GEOVANE@GMAIL.COM', '123', 'PROFESSOR'); -- COD_PROFESSOR: 1
SELECT FROM INSERIR_ALUNO_E_PROFESSOR
('VILARINHO', '23456789123', '1999-03-10', 'VILARINHO@GMAIL.COM', '123', 'PROFESSOR'); -- COD_PROFESSOR: 2
SELECT FROM INSERIR_ALUNO_E_PROFESSOR
('LUAN', '34567891234', '2000-08-10', 'LUAN@GMAIL.COM', '123', 'PROFESSOR'); -- COD_PROFESSOR: 3


/* PARAMENTROS: COD_PROFESSOR, NOME_CURSO, DESCRICAO, PRECO */
SELECT FROM CRIAR_CURSO
(1, 'PROGRAMACAO', 'APRENDENDO ALGORITMOS E PROGRAMACAO', 250); -- COD_CURSO: 1
SELECT FROM CRIAR_CURSO
(2, 'JOGOS', 'APRENDENDO PROGRAMACAO PARA JOGOS', 150); -- COD_CURSO: 2
SELECT FROM CRIAR_CURSO
(3, 'MATEMATICA', 'APRENDENDO A FAZER CALCULOS', 100); -- COD_CURSO: 3
SELECT FROM CRIAR_CURSO
(3, 'PROGRAMACAO SEM GRAFOS', 'APRENDENDO A PROGRAMAR SEM GRAFOS', 200); -- COD_CURSO: 4


/* PARAMETROS: CODIGO_CURSO, NOME_MODULO(ARRAY), DESCRICAO_MODULO(ARRAY), DURACAO_MODULO(ARRAY) */
SELECT FROM CRIAR_MODULO
(3,
ARRAY ['MODULO 1(MATEMATICA)', 'MODULO 2(MATEMATICA)', 'MODULO 3(MATEMATICA)'],
ARRAY ['DESCRICAO 1(MATEMATICA)', 'DESCRICAO 2(MATEMATICA)', 'DESCRICAO 3(MATEMATICA)'],
ARRAY [10, 20, 30]);  -- COD_MODULO: 1, 2, 3


/* PARAMETROS: CODIGO_MODULO, NOME_DISCIPLINA(ARRAY), DESCRICAO_DISCIPLINA(ARRAY) */
SELECT FROM CRIAR_DISCIPLINAS
(1,
ARRAY ['APRENDENDO A SOMAR', 'APRENDENDO A DIVIDIR', 'APRENDENDO A SUBTRAIR'],
ARRAY ['DESCRICAO 1', 'DESCRICAO 2', 'DESCRICAO 3']);  -- COD_DISCIPLINA: 1, 2, 3

SELECT FROM CRIAR_DISCIPLINAS
(2,
ARRAY ['APRENDENDO A DERIVADA', 'APRENDENDO A BASKARA', 'APRENDENDO A ALGEBRA'],
ARRAY ['DESCRICAO 1', 'DESCRICAO 2', 'DESCRICAO 3']);  -- COD_DISCIPLINA: 4, 5, 6

SELECT FROM CRIAR_DISCIPLINAS
(3,
ARRAY ['APRENDENDO A EQUAÇÃO', 'APRENDENDO GEOMETRIA', 'APRENDENDO A PRODUTO CARTEZIADO'],
ARRAY ['DESCRICAO 1', 'DESCRICAO 2', 'DESCRICAO 3']);  -- COD_DISCIPLINA: 7, 8, 9


/* PARAMETROS: CODIGO_DISCIPLINA, TITULO_VIDEO(ARRAY), DESCRICAO(ARRAY), DURACAO(ARRAY)
ADICIONAR O CODIGO DA DISCIPLINA DOS MODULOS VINGENTES */
SELECT FROM CRIAR_VIDEO_AULAS
(1,
ARRAY ['VIDEO 1', 'VIDEO 2', 'VIDEO 3'],
ARRAY ['DESCRICAO 1', 'DESCRICAO 2', 'DESCRICAO 3'],
ARRAY [10, 5, 3]);  -- COD_VIDEO_AULA: 1, 2, 3

SELECT FROM CRIAR_VIDEO_AULAS
(2,
ARRAY ['VIDEO 1', 'VIDEO 2', 'VIDEO 3'],
ARRAY ['DESCRICAO 1', 'DESCRICAO 2', 'DESCRICAO 3'],
ARRAY [20, 10, 8]);  -- COD_VIDEO_AULA: 4, 5, 6

SELECT FROM CRIAR_VIDEO_AULAS
(3,
ARRAY ['VIDEO 1', 'VIDEO 2', 'VIDEO 3'],
ARRAY ['DESCRICAO 1', 'DESCRICAO 2', 'DESCRICAO 3'],
ARRAY [2, 15, 10]);  -- COD_VIDEO_AULA: 7, 8, 9

SELECT FROM CRIAR_VIDEO_AULAS
(4,
ARRAY ['VIDEO 1', 'VIDEO 2', 'VIDEO 3'],
ARRAY ['DESCRICAO 1', 'DESCRICAO 2', 'DESCRICAO 3'],
ARRAY [15, 15, 4]);  -- COD_VIDEO_AULA: 10, 11, 12

SELECT FROM CRIAR_VIDEO_AULAS
(5,
ARRAY ['VIDEO 1', 'VIDEO 2', 'VIDEO 3'],
ARRAY ['DESCRICAO 1', 'DESCRICAO 2', 'DESCRICAO 3'],
ARRAY [6, 2, 14]);  -- COD_VIDEO_AULA: 13, 14, 15

SELECT FROM CRIAR_VIDEO_AULAS
(6,
ARRAY ['VIDEO 1', 'VIDEO 2', 'VIDEO 3'],
ARRAY ['DESCRICAO 1', 'DESCRICAO 2', 'DESCRICAO 3'],
ARRAY [30, 15, 20]);  -- COD_VIDEO_AULA: 16, 17, 18

SELECT FROM CRIAR_VIDEO_AULAS
(7,
ARRAY ['VIDEO 1', 'VIDEO 2', 'VIDEO 3'],
ARRAY ['DESCRICAO 1', 'DESCRICAO 2', 'DESCRICAO 3'],
ARRAY [16, 4, 18]);  -- COD_VIDEO_AULA: 19, 20, 21

SELECT FROM CRIAR_VIDEO_AULAS
(8,
ARRAY ['VIDEO 1', 'VIDEO 2', 'VIDEO 3'],
ARRAY ['DESCRICAO 1', 'DESCRICAO 2', 'DESCRICAO 3'],
ARRAY [4, 6, 8]);  -- COD_VIDEO_AULA: 22, 23, 24

SELECT FROM CRIAR_VIDEO_AULAS
(9,
ARRAY ['VIDEO 1', 'VIDEO 2', 'VIDEO 3'],
ARRAY ['DESCRICAO 1', 'DESCRICAO 2', 'DESCRICAO 3'],
ARRAY [18, 25, 15]);  -- COD_VIDEO_AULA: 25, 26, 27


/* PARÂMETROS: TEXTO_INSERIDO, COD_DISCIPLINA_INSERIDA */
SELECT FROM CRIAR_QUESTAO ('QUANTO É 1 + 1?', 1);
SELECT FROM CRIAR_QUESTAO ('QUANTO É 100 + 50?', 1);
SELECT FROM CRIAR_QUESTAO ('QUANTO É 60 + 1030?', 1);

SELECT FROM CRIAR_QUESTAO ('QUANTO É 100 / 5?', 2);
SELECT FROM CRIAR_QUESTAO ('QUANTO É 10 / 2?', 2);
SELECT FROM CRIAR_QUESTAO ('QUANTO É 1080 / 360?', 2);

SELECT FROM CRIAR_QUESTAO ('QUANTO É 1050 - 45?', 3);
SELECT FROM CRIAR_QUESTAO ('QUANTO É 12 - 3?', 3);
SELECT FROM CRIAR_QUESTAO ('QUANTO É 400 - 120?', 3);
SELECT FROM CRIAR_QUESTAO ('QUANTO É 10000 - 800?', 3);


/* PARÂMETROS: COD_QUESTAO_DELETADA */
SELECT FROM DELETAR_QUESTAO(10);


/* PARÂMETROS: COD_PROFESSOR_ANALISADO */
SELECT * FROM LISTAR_QUESTOES_DOS_ALUNOS(3);


/* PARAMETROS: COD_PROFESSOR_ANALISADO, COD_QUESTAO_ALUNO_CORRIGIDA, RESPOSTA_CORRETA_INSERIDA */
SELECT FROM CORRIGIR_QUESTAO(3, 1, 'CORRETA');


/* PARÂMETROS: NOME_INSERIDO, COD_DISCIPLINA_INSERIDA */
SELECT FROM CRIAR_QUESTIONARIO('SOMA: PRIMEIRA ATIVIDADE', 1);
SELECT FROM CRIAR_QUESTIONARIO('SOMA: SEGUNDA ATIVIDADE', 1);

SELECT FROM CRIAR_QUESTIONARIO('DIVISÃO: ATIVIDADE', 2);

SELECT FROM CRIAR_QUESTIONARIO('SUBTRACAO: PRIMEIRA ATIVIDADE', 3);
SELECT FROM CRIAR_QUESTIONARIO('SUBTRACAO: SEGUNDA ATIVIDADE', 3);
SELECT FROM CRIAR_QUESTIONARIO('SUBTRACAO: TERCEIRA ATIVIDADE', 3);
SELECT FROM CRIAR_QUESTIONARIO('SUBTRACAO: QUARTA ATIVIDADE', 3);


/* PARÂMETROS: COD_QUESTIONARIO_DELETADO */
SELECT FROM DELETAR_QUESTIONARIO(7);


/* PARÂMETROS: COD_QUESTIONARIO_VINCULADO, COD_QUESTAO_VINCULADA */
SELECT VINCULAR_QUESTAO_A_QUESTIONARIO(1, 1);
SELECT VINCULAR_QUESTAO_A_QUESTIONARIO(1, 2);
SELECT VINCULAR_QUESTAO_A_QUESTIONARIO(2, 3);

SELECT VINCULAR_QUESTAO_A_QUESTIONARIO(3, 4);
SELECT VINCULAR_QUESTAO_A_QUESTIONARIO(3, 5);
SELECT VINCULAR_QUESTAO_A_QUESTIONARIO(3, 6);

SELECT VINCULAR_QUESTAO_A_QUESTIONARIO(4, 7);
SELECT VINCULAR_QUESTAO_A_QUESTIONARIO(5, 8);
SELECT VINCULAR_QUESTAO_A_QUESTIONARIO(6, 9);


/* PARÂMETROS: COD_ALUNO_ANALISADO, COD_QUESTAO_SUBMETIDA, RESPOSTA_ALUNO_SUBMETIDA */
SELECT FROM SUBMETER_RESPOSTA_DE_QUESTAO(1, 1, '2');
SELECT FROM SUBMETER_RESPOSTA_DE_QUESTAO(1, 5, '50');
SELECT FROM SUBMETER_RESPOSTA_DE_QUESTAO(1, 5, '5');
SELECT FROM SUBMETER_RESPOSTA_DE_QUESTAO(1, 7, '1005');


/* PARAMETROS: CPF_PROFESSOR, CODIGO_VIDEO_AULA */
SELECT FROM DELETAR_VIDEO_AULA('34567891234', 30);

SELECT FROM CRIAR_VIDEO_AULAS
('34567891234', 4,
ARRAY ['VIDEO 1'],
ARRAY ['DESCRICAO 1'],
ARRAY [3]);

SELECT * FROM CURSO

SELECT * FROM VIDEO_AULA

SELECT * FROM ALUNO_MODULO

SELECT * FROM PRE_REQUISITO


SELECT FROM ASSISTIR_VIDEO_AULA('11223344555', 2);

DELETE FROM ALUNO_VIDEOS_ASSISTIDOS WHERE COD_VIDEO_AULA = 2;

SELECT * FROM ALUNO_VIDEOS_ASSISTIDOS;


UPDATE ALUNO_MODULO SET ACESSIVEL = FALSE WHERE COD_ALUNO_MODULO = 2
UPDATE ALUNO_MODULO SET META_CONCLUIDA = FALSE WHERE COD_ALUNO_MODULO = 1

UPDATE ALUNO_MODULO SET META_CONCLUIDA = TRUE WHERE COD_ALUNO_MODULO = 1
UPDATE ALUNO_MODULO SET META_CONCLUIDA = TRUE WHERE COD_ALUNO_MODULO = 3



/* PARAMETROS: CPF_PROFESSOR, COD_DISCIPLINA */
SELECT FROM DELETAR_DISCIPLINA('34567891234', 1);
 
/* PARAMETROS: CPF_PROFESSOR, COD_MODULO */
SELECT FROM DELETAR_MODULO('34567891234', 1);
 
/* PARAMETROS: CPF_PROFESSOR, COD_CURSO*/
SELECT FROM PUBLICAR_CURSO('34567891234', 3);

/* PARÂMETROS: VALOR_SALDO_A_ALTERAR, CODIGO, TABELA */
SELECT FROM ATUALIZAR_SALDO(2000, 1, 'ALUNO')

/* PARAMETROS: COD_ALUNO, COD_CURSO*/
SELECT FROM COMPRAR_CURSO(1, 3);
 
/* PARAMETROS: CODIGO_VIDEO_AULA */
SELECT FROM ALUNO_ASSISTIR_VIDEO_AULA(1);



-- PRE_REQUSITO
INSERT INTO PRE_REQUISITO VALUES (1, 2, 1);
INSERT INTO PRE_REQUISITO VALUES (2, 2, 3);




SELECT * FROM PRE_REQUISITO
DELETE FROM PRE_REQUISITO WHERE COD_PRE_REQUESITO = 2


INSERT INTO PRE_REQUISITO VALUES (2, 3, 2);
INSERT INTO PRE_REQUISITO VALUES (3, 1, 2);
INSERT INTO PRE_REQUISITO VALUES (4, 2, 3);

INSERT INTO PRE_REQUISITO VALUES (3, 3, 2);

INSERT INTO PRE_REQUISITO VALUES (2, 1, 3);
INSERT INTO PRE_REQUISITO VALUES (3, 3, 1);
INSERT INTO PRE_REQUISITO VALUES (4, 4, 1);

INSERT INTO PRE_REQUISITO VALUES (2, 3, 2);
INSERT INTO PRE_REQUISITO VALUES (3, 3, 1);

-------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------

SELECT * FROM PROFESSOR;

SELECT * FROM CURSO;

SELECT * FROM MODULO; 
SELECT * FROM PRE_REQUESITO;


INSERT INTO PROFESSOR VALUES (1, 'PROFS', '123456', '1998-08-08', 'OPROFS321@GMAIL.COM', '123', 10000, '2000-01-01');

INSERT INTO CURSO VALUES (1, 'CURSO', 'CURSO CURSO', 1000, 200, 15, TRUE, TRUE, 1);

INSERT INTO MODULO VALUES (1, 'MATEMATICA', 'DESCRICAO', 100, 1);
INSERT INTO MODULO VALUES (2, 'PORTUGUES', 'DESCRICAO', 120, 1);
INSERT INTO MODULO VALUES (3, 'CIENCIAS', 'DESCRICAO', 150, 1);
INSERT INTO MODULO VALUES (4, 'HISTORIA', 'DESCRICAO', 50, 1);
INSERT INTO MODULO VALUES (5, 'GEOGRAFIA', 'DESCRICAO', 180, 1);



-- DROP TRIGGER TRIGGER_PRE_REQUISITO ON PRE_REQUISITO



SELECT * FROM ALUNO_MODULO; 
SELECT * FROM PRE_REQUISITO;

DELETE FROM PRE_REQUISITO;

-- DÁ CERTO
INSERT INTO PRE_REQUISITO VALUES (100, 2, 1);
INSERT INTO PRE_REQUISITO VALUES (101, 3, 1);
INSERT INTO PRE_REQUISITO VALUES (102, 3, 2);
---------------------------------------------
INSERT INTO PRE_REQUISITO VALUES (100, 4, 1);
INSERT INTO PRE_REQUISITO VALUES (101, 1, 2);
INSERT INTO PRE_REQUISITO VALUES (102, 4, 2);
INSERT INTO PRE_REQUISITO VALUES (103, 3, 1);
INSERT INTO PRE_REQUISITO VALUES (104, 5, 3);
INSERT INTO PRE_REQUISITO VALUES (105, 5, 4);


-- NÃO DÁ CERTO
INSERT INTO PRE_REQUISITO VALUES (100, 4, 1);
INSERT INTO PRE_REQUISITO VALUES (101, 1, 2);
INSERT INTO PRE_REQUISITO VALUES (102, 4, 2);
INSERT INTO PRE_REQUISITO VALUES (103, 3, 1);
INSERT INTO PRE_REQUISITO VALUES (104, 5, 3);
INSERT INTO PRE_REQUISITO VALUES (105, 5, 4);
INSERT INTO PRE_REQUISITO VALUES (105, 2, 5);


-- VERIFICAR SE O VALOR TA NA LISTA
SELECT ARRAY[1] <@ ARRAY [1,2,4]

