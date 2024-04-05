
-------------------------TEST ex01------------------------------
SELECT table_name FROM information_schema.tables WHERE table_schema = current_schema();
CALL drop_tables('user');
SELECT table_name FROM information_schema.tables WHERE table_schema = current_schema();

-------------------------TEST ex02------------------------------
DO
$$
    DECLARE
        functions_count INT;
    BEGIN
        CALL list_of_functions(functions_count);
        RAISE NOTICE 'Functions count: %', functions_count;
    END
$$;

-------------------------TEST ex03------------------------------
SELECT info.trigger_name FROM information_schema.triggers AS info WHERE info.trigger_schema = current_schema();

DO
$$
    DECLARE
        triggers_count INT;
    BEGIN
        CALL drop_triggers(triggers_count);
        RAISE NOTICE 'Triggers count: %', triggers_count;
    END
$$;

SELECT info.trigger_name FROM information_schema.triggers AS info WHERE info.trigger_schema = current_schema();

-------------------------TEST ex04------------------------------
CALL list_of_types('SELECT');
CALL list_of_types('DELETE');
CALL list_of_types('INTO');
CALL list_of_types('RETURN');
CALL list_of_types('NUMERIC');

----------------------------------------------------------------
DROP DATABASE test_db;