SET SEARCH_PATH TO CC;

DROP TYPE IF EXISTS PCC001_RESULTSET CASCADE;

CREATE TYPE PCC001_RESULTSET AS (
    CD_ERRO             NUMERIC(3,0),
    DS_ERRO             VARCHAR(255),
    NR_CONTAM           INTEGER
);

CREATE OR REPLACE FUNCTION PCC001 (
/*-------------------------------------------------------------------
    Rotina de CRUD Contas Mensais
--------------------------------------------------------------------*/
    ENT_NR_VRS           NUMERIC(5)   , /* Stored procedure version */
    ENT_VC_ACTION        VARCHAR(1)   , /* Action                   */
                                        /*   I - Insert             */
                                        /*   U - Update             */
                                        /*   D - Delete             */
    ENT_NR_CONTAM        INTEGER      , /* Conta mensal             */
    ENT_NR_MORADOR       INTEGER      , /* Morador                  */
    ENT_NR_MORADIA       INTEGER      , /* Moradia                  */
    ENT_NR_TPCONTA       INTEGER      , /* Tipo de conta            */
    ENT_DT_DDVENC        NUMERIC(2,0) , /* Dia vencimento           */
    ENT_DT_AMVENC        NUMERIC(6,0) , /* Mês e Ano vencimento     */
    ENT_VL_VALOR         NUMERIC(10,2)  /* Valor                    */

)
    RETURNS SETOF PCC001_RESULTSET
AS $$

/*-------------------------------------------------------------------
    Local variables
-------------------------------------------------------------------*/
DECLARE
    _R                   CC.PCC001_RESULTSET%Rowtype;
    _CD_ERRO             NUMERIC(3,0);
    _DS_ERRO             VARCHAR(255);
    _DT_DDVENC           NUMERIC(2,0);
    _NR_CONTAM           INTEGER     ;
    _RESULTADO           RECORD      ;

/*-------------------------------------------------------------------
    Function
-------------------------------------------------------------------*/
BEGIN
/*-------------------------------------------------------------------
    Validations
-------------------------------------------------------------------*/
IF NOT EXISTS (SELECT * FROM AD.AD999 WHERE AD999_IT_VRS = ENT_NR_VRS) THEN
    RAISE EXCEPTION 'Autenticação de SP negada.';
END IF;

IF ENT_NR_MORADIA IS NULL THEN
    RAISE EXCEPTION 'É necessário fornecer a moradia.';
END IF;

IF ENT_NR_MORADOR IS NULL THEN
    RAISE EXCEPTION 'É ncessário fornecer o morador.';
END IF;

IF ENT_NR_TPCONTA IS NULL THEN
    RAISE EXCEPTION 'É necessário fornecer o Tipo de Conta';
END IF;

IF ENT_VL_VALOR IS NULL THEN
    RAISE EXCEPTION 'É necessário fornecer um valor para a conta.';
END IF;

IF ENT_DT_DDVENC IS NULL THEN

    IF NOT EXISTS (SELECT * FROM AD.AD003 WHERE AD003_NR_MORADIA = ENT_NR_MORADIA AND AD003_DT_DDVENC IS NOT NULL AND AD003_IT_SITUAC = 1) THEN
        RAISE EXCEPTION 'A Data de vencimento não foi informada e a moradia não possui uma data de vencimento padrão.';
    END IF;
END IF;

IF ENT_DT_DDVENC > 31 OR ENT_DT_DDVENC < 1 THEN
    RAISE EXCEPTION 'Data de vencimento inválida.';
END IF;

IF ENT_DT_AMVENC IS NULL THEN
    RAISE EXCEPTION 'Mês e Ano de vencimento precisa ser informado.';
END IF;

IF ENT_DT_AMVENC%100 > 12 OR ENT_DT_AMVENC%100 < 1 THEN
    RAISE EXCEPTION 'Mês informado inválido.';
END IF;

IF NOT EXISTS (SELECT * FROM AD.AD001 WHERE AD001_NR_MORADOR = ENT_NR_MORADOR AND AD001_NR_TPMOR = 1 AND AD001_IT_SITUAC = 1) THEN
    RAISE EXCEPTION 'Morador não localizado ou sem privilégio de Administrador.';
END IF;

IF NOT EXISTS (SELECT * FROM AD.AD003 WHERE AD003_NR_MORADIA = ENT_NR_MORADIA AND AD003_IT_SITUAC = 1) THEN
    RAISE EXCEPTION 'Moradia não localizada.';
END IF;

IF NOT EXISTS (SELECT * FROM AD.AD003 WHERE AD003_NR_MORADIA = ENT_NR_MORADIA AND AD003_NR_ADMMOR = ENT_NR_MORADOR AND AD003_IT_SITUAC = 1) THEN
    RAISE EXCEPTION 'Morador não é Administrador desta moradia.';
END IF;

IF NOT EXISTS (SELECT * FROM AD.AD004 WHERE AD004_NR_MORADIA = ENT_NR_MORADIA AND AD004_NR_MORADOR = ENT_NR_MORADOR AND AD004_IT_SITUAC = 1) THEN
    RAISE EXCEPTION 'Morador não registrado nesta moradia.';
END IF;

IF NOT EXISTS (SELECT * FROM CC.CC002 WHERE CC002_NR_TPCONTA = ENT_NR_TPCONTA AND CC002_NR_MORADIA = ENT_NR_MORADIA AND CC002_IT_SITUAC = 1) THEN
    RAISE EXCEPTION 'Tipo de conta não localizado para esta moradia.';
END IF;

IF ENT_VC_ACTION = 'I' THEN
    IF EXISTS (SELECT * FROM CC.CC001 WHERE CC001_NR_MORADIA = ENT_NR_MORADIA AND CC001_NR_TPCONTA = ENT_NR_TPCONTA AND CC001_DT_AMVENC = ENT_DT_AMVENC AND CC001_IT_SITUAC = 1) THEN
        RAISE EXCEPTION 'Tipo de conta já cadastrada para este mês nesta moradia.';
    END IF;
END IF;

IF ENT_VC_ACTION = 'U' OR ENT_VC_ACTION = 'D' THEN

    IF ENT_NR_CONTAM IS NULL THEN
        RAISE EXCEPTION 'O identificador de conta é necessário.';
    END IF;

END IF;
/*-------------------------------------------------------------------
    CRUD
-------------------------------------------------------------------*/
IF ENT_VC_ACTION = 'I' THEN

    CASE
        WHEN ENT_DT_DDVENC IS NOT NULL THEN _DT_DDVENC := ENT_DT_DDVENC;
        WHEN ENT_DT_DDVENC IS NULL THEN _DT_DDVENC := (SELECT AD003_DT_DDVENC FROM AD.AD003 WHERE AD003_NR_MORADIA = ENT_NR_MORADIA AND AD003_IT_SITUAC = 1);
    END CASE;

    INSERT INTO CC.CC001 (
        CC001_NR_TPCONTA ,
        CC001_NR_MORADIA ,
        CC001_DT_DDVENC  ,
        CC001_DT_AMVENC  ,
        CC001_VL_VALOR   ,
        CC001_IT_SITUAC  ,
        CC001_DT_ULTATU  ,
        CC001_DT_INCLUS
    ) VALUES (
        ENT_NR_TPCONTA   ,
        ENT_NR_MORADIA   ,
        _DT_DDVENC       ,
        ENT_DT_AMVENC    ,
        ENT_VL_VALOR     ,
        1                ,
        NOW()            ,
        NOW()
    ) RETURNING CC001_NR_CONTAM INTO _NR_CONTAM;

    _RESULTADO := (SELECT CC.PCC003(ENT_NR_VRS,
                                    ENT_VC_ACTION,
                                    ENT_NR_MORADIA,
                                    _NR_CONTAM,
                                    ENT_VL_VALOR));

    _CD_ERRO := _RESULTADO.CD_ERRO;
    _DS_ERRO := _RESULTADO.DS_ERRO;

ELSIF ENT_VC_ACTION = 'U' THEN

    UPDATE
        CC.CC001
    SET
        CC001_NR_TPCONTA = ENT_NR_TPCONTA,
        CC001_DT_DDVENC  = ENT_DT_DDVENC ,
        CC001_DT_AMVENC  = ENT_DT_AMVENC ,
        CC001_VL_VALOR   = ENT_VL_VALOR  ,
        CC001_DT_ULTATU  = NOW()
    WHERE
        CC001_NR_CONTAM = ENT_NR_CONTAM;

    _RESULTADO := (SELECT CC.PCC003(ENT_NR_VRS,
                                    ENT_VC_ACTION,
                                    ENT_NR_MORADIA,
                                    ENT_NR_CONTAM,
                                    ENT_VL_VALOR));

    _CD_ERRO := _RESULTADO.CD_ERRO;
    _DS_ERRO := _RESULTADO.DS_ERRO;
    _NR_CONTAM := ENT_NR_CONTAM;

ELSIF ENT_VC_ACTION = 'D' THEN

    _RESULTADO := (SELECT CC.PCC003(ENT_NR_VRS,
                                    ENT_VC_ACTION,
                                    ENT_NR_MORADIA,
                                    ENT_NR_CONTAM,
                                    ENT_VL_VALOR));

    DELETE FROM
        CC.CC001
    WHERE
        CC001_NR_MORADIA = ENT_NR_MORADIA
    AND CC001_NR_CONTAM  = ENT_NR_CONTAM;

    _CD_ERRO := _RESULTADO.CD_ERRO;
    _DS_ERRO := _RESULTADO.DS_ERRO;
    _NR_CONTAM := ENT_NR_CONTAM;

ELSE
    RAISE EXCEPTION 'Comando não reconhecido.';
END IF;

/*=================================================================*/
/*= RESULT SET                                                    =*/
/*=================================================================*/
FOR _R IN
    SELECT
       _CD_ERRO,
       _DS_ERRO,
       _NR_CONTAM
    LOOP
       RETURN NEXT _R;
    END LOOP;

/*:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/
/*::               EXCEPTION HANDLING POSTGRES                   ::*/
/*:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/
EXCEPTION WHEN OTHERS THEN
    _CD_ERRO := -1;
    _DS_ERRO := SQLERRM;

    FOR _R IN
        SELECT
           _CD_ERRO,
           _DS_ERRO
        LOOP
           RETURN NEXT _R;
        END LOOP;
    RETURN;
END
/*-----------------------------------------------------------------*/
$$ LANGUAGE PLPGSQL;
