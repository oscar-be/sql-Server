USE [ESTUDOS_SQL]
GO
/****** Object:  StoredProcedure [ETL].[PR_NOTIFICA_EXECUCAO_CARGA]    Script Date: 12/17/2017 3:27:55 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [ETL_MON].[PR_NOTIFICA_EXECUCAO_CARGA]
	 @ID_CARGA_ETAPA	INT				= NULL 
	,@ID_CARGA_EXECUCAO	INT				= NULL
	,@TIPO_TERMINO		VARCHAR(500)	

AS
BEGIN

	DECLARE  @HTML 				VARCHAR(MAX)
			,@CONSULTA_TABELA	VARCHAR(MAX)
			,@ASSUNTO_HTML		VARCHAR(MAX)
			,@TABELA_HTML		VARCHAR(MAX)
			,@PROJETO_ETL		VARCHAR(MAX)
			,@DESCRICAO_ETL		VARCHAR(MAX)
			,@DESTINATARIOS		VARCHAR(MAX)
		

	IF @TIPO_TERMINO NOT IN ('SUCESSO', 'ERRO')
	BEGIN
		--RAISEERROR 'Parâmetro inválido para a variável TIPO_TERMINO. O valor dessa variável pode ser apenas ''SUCESSO'' ou ''ERRO'''
		RETURN
	END	

SET @ASSUNTO_HTML = '#TIPO_RETORNO - #PROJETO_ETL: #DESCRICAO_ETL'




SET @HTML = '
	<style>
	table {
	  width: 1500;
	  text-align: left;
	  border-collapse: collapse;
	  margin: 0 0 1em 0;
	  caption-side: 10px;
	  font-family: "Arial";
	  font-size: 80%;
	} 
	caption, td, th {
	  padding: 0.1em;
	}
	thead {
	  text-align: center;
	  font-weight: bold;
	 }
	tbody {
	  border-top: 5px solid #000;
	  border-bottom: 5px solid #000;
	}
	tFooter {
	  align: left;
	}
	tbody th, tfoot th {
	  border: 0;
	}
	th.name {
	  width: 25%;
	}
	th.location {
	  width: 20%;
	}
	th.lasteruption {
	  width: 30%;
	}
	th.eruptiontype {
	  width: 25%;
	} 
	tfoot {
	  text-align: center;
	  color: #555;
	  font-size: 0.3em;
	}
	.odd th, .odd td {
	  background: #eee;
	}
	.odd2 th, .odd2 td {
	 background: #E26B0A;
	 color: #FFFFFF;
	}
	</style>
' 	
		
	SET @HTML +=
	'<html>
	<body>
	<font face="arial" size="2">
	Processo de ETL #DESCRICAO_ETL (projeto #PROJETO_ETL) rodada com #TIPO_RETORNO.
	<br><br>#TABELA_HTML<br><br>	
	att<br>
	Data Intelligence - Database Marketing
	</font>
	</body>
	</html>'

	
	--Executa chamado em caso de erro
	IF @TIPO_TERMINO IN ('ERRO')
	BEGIN		
	
		SET @CONSULTA_TABELA =
		'(SELECT DISTINCT
			 C.PROJETO
			,C.DESCRICAO
			,INICIO_EXECUCAO =  CONVERT(VARCHAR(10), B.INICIO_EXECUCAO, 3) + '' - '' + CONVERT(VARCHAR(8), B.INICIO_EXECUCAO, 114)
			,PACKAGE_ERRO		= A.PACKAGE_NAME
			,ETAPA_PACKAGE		= A.SOURCE_NAME
			,ETAPA_TIPO			= A.SOURCE_DESCRIPTION		
			,A.SOURCE_COMPLEMENTO
			,HORA_ERRO			= CONVERT(VARCHAR(10), A.HORA_ERRO, 3) + '' - '' + CONVERT(VARCHAR(8), A.HORA_ERRO, 114)
			,DURACAO = BRAIN.DBO.FN_TEXTO_DATEDIFF(B.INICIO_EXECUCAO, A.HORA_ERRO)
			,A.SSIS_ERROR_CODE
			,A.DESC_ERRO
			,B.EXECUTADO_POR
			FROM ESTUDOS_SQL.ETL_MON.CARGA_ETAPA A
			INNER JOIN ESTUDOS_SQL.ETL_MON.CARGA_EXECUCAO B ON A.ID_CARGA_EXECUCAO = B.ID_CARGA_EXECUCAO
			INNER JOIN ESTUDOS_SQL.ETL_MON.CARGA_TIPO	  C ON B.ID_CARGA_TIPO	   = C.ID_CARGA_TIPO
			WHERE A.ID_CARGA_ETAPA = #ID_CARGA_ETAPA) A'
			
			SET @CONSULTA_TABELA = REPLACE(@CONSULTA_TABELA, '#ID_CARGA_ETAPA', @ID_CARGA_ETAPA)
			
		
			SELECT 
				 @PROJETO_ETL	= C.PROJETO	
				,@DESCRICAO_ETL	= C.DESCRICAO
				,@DESTINATARIOS	= C.DESTINATARIOS_ERRO
				FROM ETL_MON.CARGA_ETAPA A
				INNER JOIN ETL_MON.CARGA_EXECUCAO B ON A.ID_CARGA_EXECUCAO = B.ID_CARGA_EXECUCAO
				INNER JOIN ETL_MON.CARGA_TIPO	  C ON B.ID_CARGA_TIPO	   = C.ID_CARGA_TIPO
				WHERE A.ID_CARGA_ETAPA = @ID_CARGA_ETAPA
		
		
		
	END
	

		--Consulta para notificar término de execução da ETL sem erros
		IF @TIPO_TERMINO IN ('SUCESSO')
		BEGIN
			
			SET @CONSULTA_TABELA = 
			'(SELECT DISTINCT
				 B.PROJETO
				,B.DESCRICAO
				,INICIO_EXECUCAO  =  CONVERT(VARCHAR(10), A.INICIO_EXECUCAO, 3) + '' - '' + CONVERT(VARCHAR(8), A.INICIO_EXECUCAO, 114)
				,TERMINO_EXECUCAO =  CONVERT(VARCHAR(10), A.TERMINO_EXECUCAO, 3) + '' - '' + CONVERT(VARCHAR(8), A.TERMINO_EXECUCAO, 114)
				,DURACAO = BRAIN.DBO.FN_TEXTO_DATEDIFF(A.INICIO_EXECUCAO, A.TERMINO_EXECUCAO)
				,A.EXECUTADO_POR
				FROM ESTUDOS_SQL.ETL_MON.CARGA_EXECUCAO A
				INNER JOIN ESTUDOS_SQL.ETL_MON.CARGA_TIPO	  B ON A.ID_CARGA_TIPO		   = B.ID_CARGA_TIPO
				WHERE A.ID_CARGA_EXECUCAO = #ID_CARGA_EXECUCAO) A'
				
			SET @CONSULTA_TABELA = REPLACE(@CONSULTA_TABELA, '#ID_CARGA_EXECUCAO', @ID_CARGA_EXECUCAO)
				
			SELECT 
				 @PROJETO_ETL	= B.PROJETO	
				,@DESCRICAO_ETL	= B.DESCRICAO
				,@DESTINATARIOS	= B.DESTINATARIOS_SUCESSO
				FROM ETL_MON.CARGA_EXECUCAO A
				INNER JOIN ETL_MON.CARGA_TIPO	  B ON A.ID_CARGA_TIPO		   = B.ID_CARGA_TIPO
				WHERE A.ID_CARGA_EXECUCAO = @ID_CARGA_EXECUCAO			
				
		END			

	SET @ASSUNTO_HTML = REPLACE(@ASSUNTO_HTML, '#PROJETO_ETL'	, @PROJETO_ETL)
	SET @ASSUNTO_HTML = REPLACE(@ASSUNTO_HTML, '#DESCRICAO_ETL'	, @DESCRICAO_ETL)
	SET @ASSUNTO_HTML = REPLACE(@ASSUNTO_HTML, '#TIPO_RETORNO'	, BRAIN.DBO.FN_PRIMEIRA_MAIUSCULA(@TIPO_TERMINO))


	--PRINT @CONSULTA_TABELA
	
	
		
	--Gera código HTML da tabela
	EXEC ESTUDOS_SQL.[dbo].[PR_RETORNA_TABELA_HTML] 
		 @TABELA = @CONSULTA_TABELA
		,@HTML_COMPLETO = @TABELA_HTML OUTPUT

	SET @HTML = REPLACE(@HTML, '#PROJETO_ETL'	, @PROJETO_ETL)
	SET @HTML = REPLACE(@HTML, '#DESCRICAO_ETL'	, @DESCRICAO_ETL)
	SET @HTML = REPLACE(@HTML, '#TIPO_RETORNO', LOWER(@TIPO_TERMINO))
	SET @HTML = REPLACE(@HTML, '#TABELA_HTML', @TABELA_HTML)

	PRINT @HTML

	  EXEC MSDB.DBO.SP_SEND_DBMAIL    
	    @PROFILE_NAME = 'EMAIL_GENERICO'   
	   ,@RECIPIENTS   = @DESTINATARIOS    
	   ,@BODY         = @HTML
	   ,@SUBJECT      = @ASSUNTO_HTML  
	   ,@BODY_FORMAT  = 'HTML'    
		

END


	


GO
