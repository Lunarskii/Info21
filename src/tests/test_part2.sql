
-------------------------TEST ex01------------------------------

CREATE OR REPLACE FUNCTION show_checks()
RETURNS TABLE (Peer VARCHAR, Task VARCHAR, Date DATE, "Time" TIME, State STATUS)
AS
$$
BEGIN
    RETURN QUERY
    SELECT
        checks.peer,
        checks.task,
        checks."Date",
        p2p."Time",
        p2p."State"
    FROM checks
        JOIN p2p ON checks.id = p2p."Check"
    WHERE "Date" = NOW()::date;
END;
$$
LANGUAGE PLPGSQL;

SELECT * FROM show_checks();
CALL add_peer_review('amatilda', 'jbelinda', 'DO2_Linux Network', 'Start', '10:00:00');
SELECT * FROM show_checks();
CALL add_peer_review('amatilda', 'jbelinda', 'DO2_Linux Network', 'Success', '11:00:00');
SELECT * FROM show_checks();

-------------------------TEST ex02------------------------------
SELECT * FROM verter ORDER BY "Time";
CALL add_verter_review('amatilda', 'DO2_Linux Network', 'Start', '12:00:00');
SELECT * FROM verter ORDER BY "Time";
CALL add_verter_review('amatilda', 'DO2_Linux Network', 'Failure', '13:00:00');
SELECT * FROM verter ORDER BY "Time";

-------------------------TEST ex03------------------------------
SELECT * FROM transferredpoints WHERE checkingpeer = 'jbelinda' AND checkedpeer = 'amatilda';
CALL add_peer_review('amatilda', 'jbelinda', 'DO3_LinuxMonitoring v1.0', 'Start', '14:00:00');
SELECT * FROM transferredpoints WHERE checkingpeer = 'jbelinda' AND checkedpeer = 'amatilda';

-------------------------TEST ex04------------------------------
CALL add_peer_review('amatilda', 'jbelinda', 'DO3_LinuxMonitoring v1.0', 'Success', '15:00:00');
CALL add_verter_review('amatilda', 'DO3_LinuxMonitoring v1.0', 'Start', '16:00:00');
CALL add_verter_review('amatilda', 'DO3_LinuxMonitoring v1.0', 'Success', '17:00:00');
SELECT * FROM xp WHERE xp."Check" = (SELECT MAX(id) FROM checks);
INSERT INTO xp VALUES ((SELECT MAX(id) + 1 FROM xp), (SELECT MAX(id) FROM checks), 350);
SELECT * FROM xp WHERE xp."Check" = (SELECT MAX(id) FROM checks);