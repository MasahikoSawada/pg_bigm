-- complain if script is sourced in psql, rather than via ALTER EXTENSION
\echo Use "ALTER EXTENSION pg_bigm UPDATE TO '1.3'" to load this file. \quit

/* word similarity search is available in version 1.3 */
DO $$
DECLARE
    pgversion INTEGER;
BEGIN
    SELECT current_setting('server_version_num')::INTEGER INTO pgversion;
    IF pgversion >= 90600 THEN
        CREATE FUNCTION bigm_word_similarity(text,text)
	RETURNS float4
	AS 'MODULE_PATHNAME'
	LANGUAGE C STRICT IMMUTABLE PARALLEL SAFE;

	CREATE FUNCTION bigm_word_similarity_op(text,text)
	RETURNS bool
	AS 'MODULE_PATHNAME'
	LANGUAGE C STRICT STABLE PARALLEL SAFE;

	CREATE FUNCTION bigm_word_similarity_commutator_op(text,text)
	RETURNS bool
	AS 'MODULE_PATHNAME'
	LANGUAGE C STRICT STABLE PARALLEL SAFE;

	CREATE OPERATOR <=% (
	        LEFTARG = text,
	        RIGHTARG = text,
 		PROCEDURE = bigm_word_similarity_op,
		COMMUTATOR = '=%>',
        	RESTRICT = contsel,
        	JOIN = contjoinsel
	);

	CREATE OPERATOR =%> (
               LEFTARG = text,
               RIGHTARG = text,
               PROCEDURE = bigm_word_similarity_commutator_op,
               COMMUTATOR = '<=%',
               RESTRICT = contsel,
               JOIN = contjoinsel
	);

    	ALTER OPERATOR FAMILY gin_bigm_ops USING gin ADD
	      OPERATOR 3      =%> (text, text);
    END IF;
END;
$$;
