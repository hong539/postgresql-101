---------------------------------------------------------------------------
--
-- complex.sql-
--    This file shows how to create a new user-defined type and how to
--    use this new type.
--
--
-- Portions Copyright (c) 1996-2024, PostgreSQL Global Development Group
-- Portions Copyright (c) 1994, Regents of the University of California
--
-- src/tutorial/complex.source
--
---------------------------------------------------------------------------

-----------------------------
-- Creating a new type:
--	We are going to create a new type called 'complex' which represents
--	complex numbers.
--	A user-defined type must have an input and an output function, and
--	optionally can have binary input and output functions.  All of these
--	are usually user-defined C functions.
-----------------------------

-- Assume the user defined functions are in /home/hong/postgresql-17.5/src/tutorial/complex$DLSUFFIX
-- (we do not want to assume this is in the dynamic loader search path).
-- Look at $PWD/complex.c for the source.  Note that we declare all of
-- them as STRICT, so we do not need to cope with NULL inputs in the
-- C code.  We also mark them IMMUTABLE, since they always return the
-- same outputs given the same inputs.

-- the input function 'complex_in' takes a null-terminated string (the
-- textual representation of the type) and turns it into the internal
-- (in memory) representation. You will get a message telling you 'complex'
-- does not exist yet but that's okay.

CREATE FUNCTION complex_in(cstring)
   RETURNS complex
   AS '/home/hong/postgresql-17.5/src/tutorial/complex'
   LANGUAGE C IMMUTABLE STRICT;

-- the output function 'complex_out' takes the internal representation and
-- converts it into the textual representation.

CREATE FUNCTION complex_out(complex)
   RETURNS cstring
   AS '/home/hong/postgresql-17.5/src/tutorial/complex'
   LANGUAGE C IMMUTABLE STRICT;

-- the binary input function 'complex_recv' takes a StringInfo buffer
-- and turns its contents into the internal representation.

CREATE FUNCTION complex_recv(internal)
   RETURNS complex
   AS '/home/hong/postgresql-17.5/src/tutorial/complex'
   LANGUAGE C IMMUTABLE STRICT;

-- the binary output function 'complex_send' takes the internal representation
-- and converts it into a (hopefully) platform-independent bytea string.

CREATE FUNCTION complex_send(complex)
   RETURNS bytea
   AS '/home/hong/postgresql-17.5/src/tutorial/complex'
   LANGUAGE C IMMUTABLE STRICT;


-- now, we can create the type. The internallength specifies the size of the
-- memory block required to hold the type (we need two 8-byte doubles).

CREATE TYPE complex (
   internallength = 16,
   input = complex_in,
   output = complex_out,
   receive = complex_recv,
   send = complex_send,
   alignment = double
);


-----------------------------
-- Using the new type:
--	user-defined types can be used like ordinary built-in types.
-----------------------------

-- eg. we can use it in a table

CREATE TABLE test_complex (
	a	complex,
	b	complex
);

-- data for user-defined types are just strings in the proper textual
-- representation.

INSERT INTO test_complex VALUES ('(1.0, 2.5)', '(4.2, 3.55 )');
INSERT INTO test_complex VALUES ('(33.0, 51.4)', '(100.42, 93.55)');

SELECT * FROM test_complex;

-----------------------------
-- Creating an operator for the new type:
--	Let's define an add operator for complex types. Since POSTGRES
--	supports function overloading, we'll use + as the add operator.
--	(Operator names can be reused with different numbers and types of
--	arguments.)
-----------------------------

-- first, define a function complex_add (also in complex.c)
CREATE FUNCTION complex_add(complex, complex)
   RETURNS complex
   AS '/home/hong/postgresql-17.5/src/tutorial/complex'
   LANGUAGE C IMMUTABLE STRICT;

-- we can now define the operator. We show a binary operator here but you
-- can also define a prefix operator by omitting the leftarg.
CREATE OPERATOR + (
   leftarg = complex,
   rightarg = complex,
   procedure = complex_add,
   commutator = +
);


SELECT (a + b) AS c FROM test_complex;

-- Occasionally, you may find it useful to cast the string to the desired
-- type explicitly. :: denotes a type cast.

SELECT  a + '(1.0,1.0)'::complex AS aa,
        b + '(1.0,1.0)'::complex AS bb
   FROM test_complex;


-----------------------------
-- Creating aggregate functions
--	you can also define aggregate functions. The syntax is somewhat
--	cryptic but the idea is to express the aggregate in terms of state
--	transition functions.
-----------------------------

CREATE AGGREGATE complex_sum (
   sfunc = complex_add,
   basetype = complex,
   stype = complex,
   initcond = '(0,0)'
);

SELECT complex_sum(a) FROM test_complex;


-----------------------------
-- Interfacing New Types with Indexes:
--	We cannot define a secondary index (eg. a B-tree) over the new type
--	yet. We need to create all the required operators and support
--      functions, then we can make the operator class.
-----------------------------

-- first, define the required operators
CREATE FUNCTION complex_abs_lt(complex, complex) RETURNS bool
   AS '/home/hong/postgresql-17.5/src/tutorial/complex' LANGUAGE C IMMUTABLE STRICT;
CREATE FUNCTION complex_abs_le(complex, complex) RETURNS bool
   AS '/home/hong/postgresql-17.5/src/tutorial/complex' LANGUAGE C IMMUTABLE STRICT;
CREATE FUNCTION complex_abs_eq(complex, complex) RETURNS bool
   AS '/home/hong/postgresql-17.5/src/tutorial/complex' LANGUAGE C IMMUTABLE STRICT;
CREATE FUNCTION complex_abs_ge(complex, complex) RETURNS bool
   AS '/home/hong/postgresql-17.5/src/tutorial/complex' LANGUAGE C IMMUTABLE STRICT;
CREATE FUNCTION complex_abs_gt(complex, complex) RETURNS bool
   AS '/home/hong/postgresql-17.5/src/tutorial/complex' LANGUAGE C IMMUTABLE STRICT;

CREATE OPERATOR < (
   leftarg = complex, rightarg = complex, procedure = complex_abs_lt,
   commutator = > , negator = >= ,
   restrict = scalarltsel, join = scalarltjoinsel
);
CREATE OPERATOR <= (
   leftarg = complex, rightarg = complex, procedure = complex_abs_le,
   commutator = >= , negator = > ,
   restrict = scalarlesel, join = scalarlejoinsel
);
CREATE OPERATOR = (
   leftarg = complex, rightarg = complex, procedure = complex_abs_eq,
   commutator = = ,
   -- leave out negator since we didn't create <> operator
   -- negator = <> ,
   restrict = eqsel, join = eqjoinsel
);
CREATE OPERATOR >= (
   leftarg = complex, rightarg = complex, procedure = complex_abs_ge,
   commutator = <= , negator = < ,
   restrict = scalargesel, join = scalargejoinsel
);
CREATE OPERATOR > (
   leftarg = complex, rightarg = complex, procedure = complex_abs_gt,
   commutator = < , negator = <= ,
   restrict = scalargtsel, join = scalargtjoinsel
);

-- create the support function too
CREATE FUNCTION complex_abs_cmp(complex, complex) RETURNS int4
   AS '/home/hong/postgresql-17.5/src/tutorial/complex' LANGUAGE C IMMUTABLE STRICT;

-- now we can make the operator class
CREATE OPERATOR CLASS complex_abs_ops
    DEFAULT FOR TYPE complex USING btree AS
        OPERATOR        1       < ,
        OPERATOR        2       <= ,
        OPERATOR        3       = ,
        OPERATOR        4       >= ,
        OPERATOR        5       > ,
        FUNCTION        1       complex_abs_cmp(complex, complex);


-- now, we can define a btree index on complex types. First, let's populate
-- the table. Note that postgres needs many more tuples to start using the
-- btree index during selects.
INSERT INTO test_complex VALUES ('(56.0,-22.5)', '(-43.2,-0.07)');
INSERT INTO test_complex VALUES ('(-91.9,33.6)', '(8.6,3.0)');

CREATE INDEX test_cplx_ind ON test_complex
   USING btree(a complex_abs_ops);

SELECT * from test_complex where a = '(56.0,-22.5)';
SELECT * from test_complex where a < '(56.0,-22.5)';
SELECT * from test_complex where a > '(56.0,-22.5)';


-- clean up the example
DROP TABLE test_complex;
DROP TYPE complex CASCADE;
