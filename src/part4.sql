
CREATE DATABASE test_db;
\c test_db;

CREATE SCHEMA test_schema;
SET search_path = test_schema;

CREATE TABLE user_test1 (id SERIAL PRIMARY KEY);
CREATE TABLE user_test2 (id SERIAL PRIMARY KEY);
CREATE TABLE user_test3 (id SERIAL PRIMARY KEY);
CREATE TABLE user_test4 (id SERIAL PRIMARY KEY);
CREATE TABLE user_test5 (id SERIAL PRIMARY KEY);
INSERT INTO user_test5 (id)
VALUES (1),
       (2),
       (3);

CREATE OR REPLACE FUNCTION test_function()
    RETURNS TABLE (id INT)
AS $$
BEGIN
    RETURN QUERY SELECT * FROM user_test5;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION test_function2()
    RETURNS NUMERIC
AS $$
DECLARE
    total_sum NUMERIC := 0;
    num_rows INTEGER := 0;
    avg NUMERIC := 0;
BEGIN
    SELECT SUM(id), COUNT(*) INTO total_sum, num_rows FROM user_test5;
    IF num_rows > 0 THEN
        avg := total_sum / num_rows;
    END IF;
    RETURN avg;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE PROCEDURE test_function3(value_to_delete INTEGER)
AS $$
BEGIN
    DELETE FROM user_test5 WHERE id = value_to_delete;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION test_trigger_function()
    RETURNS TRIGGER
AS $$
BEGIN
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER test_trigger
    AFTER UPDATE ON user_test5
    FOR EACH ROW
EXECUTE FUNCTION test_trigger_function();

CREATE OR REPLACE TRIGGER trg_test1
    BEFORE INSERT
    ON user_test2
    FOR EACH ROW
EXECUTE FUNCTION test_trigger_function();
CREATE OR REPLACE TRIGGER trg_test2
    BEFORE INSERT
    ON user_test3
    FOR EACH ROW
EXECUTE FUNCTION test_trigger_function();
CREATE OR REPLACE TRIGGER trg_test3
    BEFORE INSERT
    ON user_test4
    FOR EACH ROW
EXECUTE FUNCTION test_trigger_function();









------------------------------ex01------------------------------
CREATE OR REPLACE PROCEDURE drop_tables
(
    IN prefix VARCHAR
)
AS
$$
DECLARE
    table_name VARCHAR;
BEGIN
    FOR table_name IN
        SELECT info.table_name
        FROM information_schema.tables AS info
        WHERE
            info.table_schema = current_schema()
            AND
            info.table_name LIKE (prefix || '%')
    LOOP
        EXECUTE 'DROP TABLE IF EXISTS ' || quote_ident(table_name) || ' CASCADE';
    END LOOP;
END;
$$
LANGUAGE PLPGSQL;

------------------------------ex02------------------------------
CREATE OR REPLACE PROCEDURE list_of_functions
(
    OUT functions_count INT
)
AS
$$
DECLARE
    function RECORD;
BEGIN
    functions_count = 0;

    FOR function IN
        SELECT
            pg_proc.proname AS name,
            pg_get_function_arguments(pg_proc.oid) AS parameters
        FROM pg_proc
            JOIN pg_namespace ON pg_proc.pronamespace = pg_namespace.oid
        WHERE
            pg_namespace.nspname = current_schema()
            AND
            pg_proc.proargtypes = ''
            AND
            pg_proc.proretset = false
    LOOP
        functions_count = functions_count + 1;
        RAISE NOTICE '% (%) ', function.name, function.parameters;
    END LOOP;
END;
$$
LANGUAGE PLPGSQL;

------------------------------ex03------------------------------
CREATE OR REPLACE PROCEDURE drop_triggers
(
    OUT triggers_count INT
)
AS
$$
DECLARE
    trigger_name VARCHAR;
BEGIN
    triggers_count = 0;

    FOR trigger_name IN
        SELECT info.trigger_name || ' ON ' || event_object_table
        FROM information_schema.triggers AS info
        WHERE info.trigger_schema = current_schema()
    LOOP
        triggers_count = triggers_count + 1;
        EXECUTE 'DROP TRIGGER IF EXISTS ' || trigger_name;
    END LOOP;
END;
$$
LANGUAGE PLPGSQL;

------------------------------ex04------------------------------
CREATE OR REPLACE PROCEDURE list_of_types
(
    IN str VARCHAR
)
AS
$$
DECLARE
    function RECORD;
BEGIN
    FOR function IN
        SELECT
            routine_name AS name,
            routine_type AS type
        FROM information_schema.routines
        WHERE
            specific_schema = current_schema()
            AND
            routine_definition LIKE '%' || str || '%'
    LOOP
        RAISE NOTICE '% (%)', function.name, function.type;
    END LOOP;
END;
$$
LANGUAGE PLPGSQL;
