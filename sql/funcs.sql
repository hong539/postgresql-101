---------------------------------------------------------------------------
--
-- funcs.sql-
--	  Tutorial on using functions in POSTGRES.
--
--
-- Copyright (c) 1994-5, Regents of the University of California
--
-- src/tutorial/funcs.source
--
---------------------------------------------------------------------------

-----------------------------
-- Creating SQL Functions on Base Types
--	a CREATE FUNCTION statement lets you create a new function that
--	can be used in expressions (in SELECT, INSERT, etc.). We will start
--	with functions that return values of base types.
-----------------------------

--
-- let's create a simple SQL function that takes no arguments and
-- returns 1

CREATE FUNCTION one() RETURNS integer
   AS 'SELECT 1 as ONE' LANGUAGE SQL;

--
-- functions can be used in any expressions (eg. in the target list or
-- qualifications)

SELECT one() AS answer;

--
-- here's how you create a function that takes arguments. The following
-- function returns the sum of its two arguments:

CREATE FUNCTION add_em(integer, integer) RETURNS integer
   AS 'SELECT $1 + $2' LANGUAGE SQL;

SELECT add_em(1, 2) AS answer;

-----------------------------
-- Creating SQL Functions on Composite Types
--	it is also possible to create functions that return values of
--	composite types.
-----------------------------

-- before we create more sophisticated functions, let's populate an EMP
-- table

CREATE TABLE EMP (
	name		text,
	salary		integer,
	age		integer,
	cubicle		point
);

INSERT INTO EMP VALUES ('Sam', 1200, 16, '(1,1)');
INSERT INTO EMP VALUES ('Claire', 5000, 32, '(1,2)');
INSERT INTO EMP VALUES ('Andy', -1000, 2, '(1,3)');
INSERT INTO EMP VALUES ('Bill', 4200, 36, '(2,1)');
INSERT INTO EMP VALUES ('Ginger', 4800, 30, '(2,4)');

-- the argument of a function can also be a tuple. For instance,
-- double_salary takes a tuple of the EMP table

CREATE FUNCTION double_salary(EMP) RETURNS integer
   AS 'SELECT $1.salary * 2 AS salary' LANGUAGE SQL;

SELECT name, double_salary(EMP) AS dream
FROM EMP
WHERE EMP.cubicle ~= '(2,1)'::point;

-- the return value of a function can also be a tuple. However, make sure
-- that the expressions in the target list is in the same order as the
-- columns of EMP.

CREATE FUNCTION new_emp() RETURNS EMP
   AS 'SELECT ''None''::text AS name,
			  1000 AS salary,
			  25 AS age,
			  ''(2,2)''::point AS cubicle'
   LANGUAGE SQL;

-- you can then project a column out of resulting the tuple by using the
-- "function notation" for projection columns. (ie. bar(foo) is equivalent
-- to foo.bar) Note that we don't support new_emp().name at this moment.

SELECT name(new_emp()) AS nobody;

-- let's try one more function that returns tuples
CREATE FUNCTION high_pay() RETURNS setof EMP
   AS 'SELECT * FROM EMP where salary > 1500'
   LANGUAGE SQL;

SELECT name(high_pay()) AS overpaid;


-----------------------------
-- Creating SQL Functions with multiple SQL statements
--	you can also create functions that do more than just a SELECT.
-----------------------------

-- you may have noticed that Andy has a negative salary. We'll create a
-- function that removes employees with negative salaries.

SELECT * FROM EMP;

CREATE FUNCTION clean_EMP () RETURNS integer
   AS 'DELETE FROM EMP WHERE EMP.salary <= 0;
       SELECT 1 AS ignore_this'
   LANGUAGE SQL;

SELECT clean_EMP();

SELECT * FROM EMP;


-----------------------------
-- Creating C Functions
--	in addition to SQL functions, you can also create C functions.
--	See funcs.c for the definition of the C functions.
-----------------------------

CREATE FUNCTION add_one(integer) RETURNS integer
   AS '/home/hong/postgresql-17.5/src/tutorial/funcs' LANGUAGE C;

CREATE FUNCTION makepoint(point, point) RETURNS point
   AS '/home/hong/postgresql-17.5/src/tutorial/funcs' LANGUAGE C;

CREATE FUNCTION copytext(text) RETURNS text
   AS '/home/hong/postgresql-17.5/src/tutorial/funcs' LANGUAGE C;

CREATE FUNCTION c_overpaid(EMP, integer) RETURNS boolean
   AS '/home/hong/postgresql-17.5/src/tutorial/funcs' LANGUAGE C;

SELECT add_one(3) AS four;

SELECT makepoint('(1,2)'::point, '(3,4)'::point ) AS newpoint;

SELECT copytext('hello world!');

SELECT name, c_overpaid(EMP, 1500) AS overpaid
FROM EMP
WHERE name = 'Bill' or name = 'Sam';

-- remove functions that were created in this file

DROP FUNCTION c_overpaid(EMP, integer);
DROP FUNCTION copytext(text);
DROP FUNCTION makepoint(point, point);
DROP FUNCTION add_one(integer);
--DROP FUNCTION clean_EMP();
DROP FUNCTION high_pay();
DROP FUNCTION new_emp();
DROP FUNCTION add_em(integer, integer);
DROP FUNCTION one();
DROP FUNCTION double_salary(EMP);

DROP TABLE EMP;
