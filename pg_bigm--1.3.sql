-- complain if script is sourced in psql, rather than via CREATE EXTENSION
\echo Use "CREATE EXTENSION pg_bigm" to load this file. \quit

CREATE FUNCTION show_bigm(text)
RETURNS _text
AS 'MODULE_PATHNAME'
LANGUAGE C STRICT IMMUTABLE;

CREATE FUNCTION bigm_similarity(text, text)
RETURNS float4
AS 'MODULE_PATHNAME'
LANGUAGE C STRICT IMMUTABLE;

CREATE FUNCTION bigm_similarity_op(text,text)
RETURNS bool
AS 'MODULE_PATHNAME'
LANGUAGE C STRICT STABLE;  -- stable because depends on pg_bigm.similarity_limit

CREATE OPERATOR =% (
        LEFTARG = text,
        RIGHTARG = text,
        PROCEDURE = bigm_similarity_op,
        COMMUTATOR = '=%',
        RESTRICT = contsel,
        JOIN = contjoinsel
);

CREATE FUNCTION bigm_word_similarity(text,text)
RETURNS float4
AS 'MODULE_PATHNAME'
LANGUAGE C STRICT IMMUTABLE PARALLEL SAFE;

CREATE FUNCTION bigm_word_similarity_op(text,text)
RETURNS bool
AS 'MODULE_PATHNAME'
LANGUAGE C STRICT STABLE PARALLEL SAFE;  -- stable because depends on pg_trgm.word_similarity_threshold

CREATE FUNCTION bigm_word_similarity_commutator_op(text,text)
RETURNS bool
AS 'MODULE_PATHNAME'
LANGUAGE C STRICT STABLE PARALLEL SAFE;  -- stable because depends on pg_trgm.word_similarity_threshold

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

-- support functions for gin
CREATE FUNCTION gin_extract_value_bigm(text, internal)
RETURNS internal
AS 'MODULE_PATHNAME'
LANGUAGE C IMMUTABLE STRICT;

CREATE FUNCTION gin_extract_query_bigm(text, internal, int2, internal, internal, internal, internal)
RETURNS internal
AS 'MODULE_PATHNAME'
LANGUAGE C IMMUTABLE STRICT;

CREATE FUNCTION gin_bigm_consistent(internal, int2, text, int4, internal, internal, internal, internal)
RETURNS bool
AS 'MODULE_PATHNAME'
LANGUAGE C IMMUTABLE STRICT;

CREATE FUNCTION gin_bigm_compare_partial(text, text, int2, internal)
RETURNS bool
AS 'MODULE_PATHNAME'
LANGUAGE C IMMUTABLE STRICT;

CREATE FUNCTION bigmtextcmp(text, text)
RETURNS int4
AS 'MODULE_PATHNAME'
LANGUAGE C STRICT IMMUTABLE;

-- create the operator class for gin
CREATE OPERATOR CLASS gin_bigm_ops
FOR TYPE text USING gin
AS
        OPERATOR        1       pg_catalog.~~ (text, text),
        OPERATOR        2       =% (text, text),
        FUNCTION        1       bigmtextcmp (text, text),
        FUNCTION        2       gin_extract_value_bigm (text, internal),
        FUNCTION        3       gin_extract_query_bigm (text, internal, int2, internal, internal, internal, internal),
        FUNCTION        4       gin_bigm_consistent (internal, int2, text, int4, internal, internal, internal, internal),
        FUNCTION        5       gin_bigm_compare_partial (text, text, int2, internal),
        STORAGE         text;

CREATE FUNCTION likequery(text)
RETURNS text
AS 'MODULE_PATHNAME'
LANGUAGE C STRICT IMMUTABLE;

CREATE FUNCTION pg_gin_pending_stats(index regclass, OUT pages int4, OUT tuples int8)
RETURNS record
AS 'MODULE_PATHNAME'
LANGUAGE C STRICT IMMUTABLE;

/* triConsistent function is available only in 9.4 or later */
DO $$
DECLARE
    pgversion INTEGER;
BEGIN
    SELECT current_setting('server_version_num')::INTEGER INTO pgversion;
    IF pgversion >= 90400 THEN
        CREATE FUNCTION gin_bigm_triconsistent(internal, int2, text, int4, internal, internal, internal)
        RETURNS "char"
        AS 'MODULE_PATHNAME'
        LANGUAGE C IMMUTABLE STRICT;
        ALTER OPERATOR FAMILY gin_bigm_ops USING gin ADD
            FUNCTION        6    (text, text) gin_bigm_triconsistent (internal, int2, text, int4, internal, internal, internal);
    END IF;
END;
$$;

DO $$
DECLARE
    pgversion INTEGER;
BEGIN
    SELECT current_setting('server_version_num')::INTEGER INTO pgversion;
    IF pgversion >= 90600 THEN
        /* Label whether the function is deemed safe for parallelism */
        ALTER FUNCTION show_bigm(text) PARALLEL SAFE;
        ALTER FUNCTION bigm_similarity(text, text) PARALLEL SAFE;
        ALTER FUNCTION bigm_similarity_op(text, text) PARALLEL SAFE;
        ALTER FUNCTION gin_extract_value_bigm(text, internal) PARALLEL SAFE;
        ALTER FUNCTION gin_extract_query_bigm(text, internal, int2, internal, internal, internal, internal) PARALLEL SAFE;
        ALTER FUNCTION gin_bigm_consistent(internal, int2, text, int4, internal, internal, internal, internal) PARALLEL SAFE;
        ALTER FUNCTION gin_bigm_compare_partial(text, text, int2, internal) PARALLEL SAFE;
        ALTER FUNCTION bigmtextcmp(text, text) PARALLEL SAFE;
        ALTER FUNCTION likequery(text) PARALLEL SAFE;
        ALTER FUNCTION pg_gin_pending_stats(index regclass) PARALLEL SAFE;
        ALTER FUNCTION gin_bigm_triconsistent(internal, int2, text, int4, internal, internal, internal) PARALLEL SAFE;
	/* Support for word similarity search */
	ALTER OPERATOR FAMILY gin_bigm_ops USING gin ADD
	      OPERATOR 3      =%> (text, text);
    END IF;
END;
$$;
