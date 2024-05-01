SET SEARCH_PATH TO IC;

DROP TYPE IF EXISTS PIC004_RESULTSET CASCADE;

CREATE TYPE PIC004_RESULTSET AS (
    CD_ERRO              INTEGER     ,
    DS_ERRO              VARCHAR(255),
    IC001_NR_ITEM        INTEGER     ,
    IC001_VC_ITEM        VARCHAR(40) ,
    AD001_VC_NOME        VARCHAR(30) ,
    IC001_IT_SITUAC      NUMERIC(2,0),
    IC001_DT_ULTATU      VARCHAR(10)
);

CREATE OR REPLACE FUNCTION PIC004 (
/*------------------------------------------------------------------
    Rotina de Listagem de Compras
-------------------------------------------------------------------*/
    ENT_NR_VRS           NUMERIC(5)  , /* Stored procedure version */
    ENT_NR_MORADOR       INTEGER     , /* Morador                  */
    ENT_NR_MORADIA       INTEGER     , /* Moradia                  */
    ENT_IT_SITUAC        NUMERIC(2,0)  /* Situação                 */
                                       /*    NULL  - Todos         */
                                       /*      0   - Pendentes     */
                                       /*      1   - Comprado      */
                                       /*      2   - Validado      */
)
    RETURNS SETOF PIC004_RESULTSET
AS $$

/*-------------------------------------------------------------------
    Local variables
-------------------------------------------------------------------*/
DECLARE
    _R                   IC.PIC004_RESULTSET%Rowtype;
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

IF ENT_IT_SITUAC IS NOT NULL AND ENT_IT_SITUAC > 2 THEN
    RAISE EXCEPTION 'Situação inválida.';
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
IF ENT_IT_SITUAC IS NULL THEN

    FOR _R IN
        SELECT
           0                 ,
           NULL              ,
           IC001_NR_ITEM     ,
           IC001_VC_ITEM     ,
           AD001_VC_NOME     ,
           IC001_IT_SITUAC   ,
           TO_CHAR(IC001_DT_ULTATU, 'DD.MM.YYYY')
        FROM
           IC.IC001 INNER JOIN AD.AD004 ON (IC001_NR_MORADIA = AD004_NR_MORADIA AND IC001_NR_MORADOR = AD004_NR_MORADOR)
                    INNER JOIN AD.AD001 ON (IC001_NR_MORADOR = AD001_NR_MORADOR)
        WHERE
           IC001_NR_MORADIA = ENT_NR_MORADIA
        ORDER BY
           IC001_IT_SITUAC
    LOOP
       RETURN NEXT _R;
    END LOOP;

ELSE
    
    
    FOR _R IN
        SELECT
           0                 ,
           NULL              ,
           IC001_NR_ITEM     ,
           IC001_VC_ITEM     ,
           AD001_VC_NOME     ,
           IC001_IT_SITUAC   ,
           TO_CHAR(IC001_DT_ULTATU, 'DD.MM.YYYY')
        FROM
           IC.IC001 INNER JOIN AD.AD004 ON (IC001_NR_MORADIA = AD004_NR_MORADIA AND IC001_NR_MORADOR = AD004_NR_MORADOR)
                    INNER JOIN AD.AD001 ON (IC001_NR_MORADOR = AD001_NR_MORADOR)
        WHERE
            IC001_NR_MORADIA = ENT_NR_MORADIA
        AND IC001_IT_SITUAC = ENT_IT_SITUAC
        ORDER BY
           IC001_IT_SITUAC
    LOOP
       RETURN NEXT _R;
    END LOOP;
END IF;
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