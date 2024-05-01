SET SEARCH_PATH TO AD;

DROP TYPE IF EXISTS PAD005_RESULTSET CASCADE;

CREATE TYPE PAD005_RESULTSET AS (
    CD_ERRO              INTEGER     ,
    DS_ERRO              VARCHAR(255),
    AD001_VC_NOME        VARCHAR     ,
    AD001_VC_SOBREN      VARCHAR     ,
    AD001_DT_ENTRADA     NUMERIC(8,0)
);

CREATE OR REPLACE FUNCTION PAD005 (
/*------------------------------------------------------------------
    Rotina de Listagem de Moradores de uma Moradia
-------------------------------------------------------------------*/
    ENT_NR_VRS           NUMERIC(5)  , /* Stored procedure version */
    ENT_NR_MORADIA       INTEGER     , /* ID Moradia               */
    ENT_NR_MORADOR       INTEGER       /* ID Morador               */
)
    RETURNS SETOF PAD005_RESULTSET
AS $$

/*-------------------------------------------------------------------
    Local variables
-------------------------------------------------------------------*/
DECLARE
    _R                   AD.PAD005_RESULTSET%Rowtype;
    _CD_ERRO             NUMERIC(3,0);
    _DS_ERRO             VARCHAR(255);

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
    RAISE EXCEPTION 'É necessário fornecer o morador.';
END IF;

IF NOT EXISTS (SELECT * FROM AD.AD003 WHERE AD003_NR_MORADIA = ENT_NR_MORADIA AND AD003_IT_SITUAC = 1) THEN
    RAISE EXCEPTION 'Moradia não localizada.';
END IF;

IF NOT EXISTS (SELECT * FROM AD.AD004 WHERE AD004_NR_MORADIA = ENT_NR_MORADIA AND AD004_NR_MORADOR = ENT_NR_MORADOR AND AD004_IT_SITUAC = 1) THEN
    RAISE EXCEPTION 'Morador não registrado nesta moradia.';
END IF;

/*=================================================================*/
/*= RESULT SET                                                    =*/
/*=================================================================*/
FOR _R IN
    SELECT
       0               ,
       NULL            ,
       AD001_VC_NOME   ,
       AD001_VC_SOBREN ,
       AD001_DT_ENTRADA
    FROM
       AD.AD001
    INNER JOIN AD.AD004 ON ( AD004_NR_MORADOR = AD001_NR_MORADOR)
    WHERE
        AD004_NR_MORADIA = ENT_NR_MORADIA
    AND AD004_IT_SITUAC  = 1
    ORDER BY
       AD001_VC_NOME
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