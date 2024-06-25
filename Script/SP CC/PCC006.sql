SET SEARCH_PATH TO CC;

DROP TYPE IF EXISTS PCC006_RESULTSET CASCADE;

CREATE TYPE PCC006_RESULTSET AS (
    CD_ERRO             NUMERIC(3,0),
    DS_ERRO             VARCHAR(255),
    NR_ORCAM            INTEGER
);

CREATE OR REPLACE FUNCTION PCC006 (
/*------------------------------------------------------------------
    Rotina de OK ADM Orçamento
-------------------------------------------------------------------*/
    ENT_NR_VRS           NUMERIC(5)  , /* Stored procedure version */
    ENT_NR_MORADIA       INTEGER     , /* Moradia                  */
    ENT_NR_ADM           INTEGER     , /* Administrador            */
    ENT_NR_MORADOR       INTEGER     , /* Morador                  */
    ENT_NR_CONTAM        INTEGER     , /* Conta Mensal             */
    ENT_NR_ORCAM         INTEGER       /* Orçamento                */
)
    RETURNS SETOF PCC006_RESULTSET
AS $$

/*-------------------------------------------------------------------
    Local variables
-------------------------------------------------------------------*/
DECLARE
    _R                   CC.PCC006_RESULTSET%Rowtype;
    _CD_ERRO             NUMERIC(3,0);
    _DS_ERRO             VARCHAR(255);
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
    RAISE EXCEPTION 'Moradia não informada.';
END IF;

IF ENT_NR_MORADOR IS NULL THEN
    RAISE EXCEPTION 'Morador não informado.';
END IF;

IF NOT EXISTS (SELECT * FROM AD.AD003 WHERE AD003_NR_MORADIA = ENT_NR_MORADIA AND AD003_IT_SITUAC = 1) THEN
    RAISE EXCEPTION 'Moradia não localizada';
END IF;

IF NOT EXISTS (SELECT * FROM AD.AD001 WHERE AD001_NR_MORADOR = ENT_NR_MORADOR AND AD001_NR_TPMOR = 1 AND AD001_IT_SITUAC = 1) THEN
    RAISE EXCEPTION 'Usuário sem privilégios de Administrador.';
END IF;

IF NOT EXISTS (SELECT * FROM AD.AD004 WHERE AD004_NR_MORADOR = ENT_NR_MORADOR AND AD004_NR_MORADIA = ENT_NR_MORADIA AND AD004_IT_SITUAC = 1) THEN
    RAISE EXCEPTION 'Morador não registrado nesta moradia.';
END IF;

IF NOT EXISTS (SELECT * FROM AD.AD003 WHERE AD003_NR_MORADIA = ENT_NR_MORADIA AND AD003_NR_ADMMOR = ENT_NR_MORADOR AND AD003_IT_SITUAC = 1) THEN
    RAISE EXCEPTION 'Morador não é Administrador desta moradia';
END IF;

IF NOT EXISTS (SELECT * FROM CC.CC001 WHERE CC001_NR_MORADIA = ENT_NR_MORADIA AND CC001_NR_CONTAM = ENT_NR_CONTAM AND CC001_IT_SITUAC = 1) THEN
    RAISE EXCEPTION 'Conta mensal não localizada.';
END IF;

IF NOT EXISTS (SELECT * FROM CC.CC003 WHERE CC003_NR_ORCAM = ENT_NR_ORCAM AND CC003_NR_CONTAM = ENT_NR_CONTAM AND CC003_NR_MORADIA = ENT_NR_MORADIA AND CC003_IT_SITUAC = 1 AND CC003_IT_OKADM = 0) THEN
    RAISE EXCEPTION 'Orçamento mensal não localizado.';
END IF;

/*-------------------------------------------------------------------
    Rotina
-------------------------------------------------------------------*/

    UPDATE
        CC.CC003
    SET
        CC003_IT_OKADM  = 1    ,
        CC003_DT_ULTATU = NOW()
    WHERE
        CC003_NR_ORCAM = ENT_NR_ORCAM;

    _RESULTADO := (SELECT CC.PCC006(1,
                                    ENT_NR_MORADIA,
                                    ENT_NR_CONTAM));

    _CD_ERRO := 0;
    CASE
        WHEN _RESULTADO.CD_ERRO = 0 THEN _DS_ERRO := CONCAT('OK - ', _RESULTADO.DS_ERRO);
        WHEN _RESULTADO.CD_ERRO != 0 THEN _DS_ERRO := CONCAT('OK - ', _RESULTADO.DS_ERRO);
    END CASE;

/*=================================================================*/
/*= RESULT SET                                                    =*/
/*=================================================================*/
FOR _R IN
    SELECT
       _CD_ERRO,
       _DS_ERRO,
       ENT_NR_ORCAM
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
