------------------------------ex01------------------------------
CREATE OR REPLACE FUNCTION get_transferred_points()
RETURNS TABLE("Peer1" VARCHAR, "Peer2" VARCHAR, "PointsAmount" BIGINT) AS $$
BEGIN
    RETURN QUERY
    WITH query AS (
    SELECT
        CASE WHEN CheckingPeer > CheckedPeer THEN CheckingPeer ELSE CheckedPeer END AS p1,
        CASE WHEN CheckingPeer > CheckedPeer THEN CheckedPeer ELSE CheckingPeer END AS p2,
        CASE WHEN CheckingPeer > CheckedPeer THEN PointsAmount ELSE -PointsAmount END AS PointsAmount
    FROM TransferredPoints
    )
    SELECT p1 AS Peer1, p2 AS Peer2, SUM(PointsAmount)
    FROM query
	GROUP BY p1, p2;
END;
$$ LANGUAGE plpgsql;

------------------------------ex02------------------------------
CREATE OR REPLACE FUNCTION get_checks()
RETURNS TABLE("Peer" VARCHAR, "Task" VARCHAR, "XP" BIGINT) AS $$
BEGIN
    RETURN QUERY
    SELECT Checks.Peer Peer, Checks.Task Task, XPAmount XP
    FROM XP
    JOIN Checks
    ON Checks.ID = XP."Check";
END;
$$ LANGUAGE plpgsql;

------------------------------ex03------------------------------
CREATE OR REPLACE FUNCTION peers_not_leaving_campus(day DATE)
RETURNS TABLE("Nickname" VARCHAR) AS $$
BEGIN
RETURN QUERY
    SELECT Peer
    FROM TimeTracking
    WHERE "Date" = day
    GROUP BY Peer
    HAVING COUNT("State") <= 2;
END;
$$ LANGUAGE plpgsql;

------------------------------ex04------------------------------
CREATE OR REPLACE FUNCTION get_points_change()
RETURNS TABLE ("Peer" VARCHAR, "PointsChange" BIGINT) AS $$
BEGIN
    RETURN QUERY
    WITH checking AS (
    SELECT tp.CheckingPeer AS Peer,
        SUM(tp.PointsAmount) AS PointsChange
    FROM TransferredPoints tp
    GROUP BY tp.CheckingPeer
    ),
    checked AS (
    SELECT tp.CheckedPeer AS Peer,
        SUM(tp.PointsAmount) AS PointsChange
    FROM TransferredPoints tp
    GROUP BY tp.CheckedPeer
    )
    SELECT checking.Peer, checking.PointsChange - checked.PointsChange AS d
    FROM checking
    JOIN checked
    USING(Peer)
    ORDER BY d DESC;
END;
$$ LANGUAGE plpgsql;

------------------------------ex05------------------------------
CREATE OR REPLACE FUNCTION get_points_change_2()
RETURNS TABLE ("Peer" VARCHAR, "PointsChange" BIGINT) AS $$
BEGIN
    RETURN QUERY
    WITH check_ AS (
    SELECT "Peer1" AS Peer, SUM("PointsAmount") AS PointsChange
    FROM get_transferred_points()
    GROUP BY Peer
    UNION ALL
    SELECT "Peer2" AS Peer, -SUM("PointsAmount") AS PointsChange
    FROM get_transferred_points()
    GROUP BY Peer
    )
    SELECT check_.Peer, CAST(SUM(check_.PointsChange) AS BIGINT) AS d
    FROM check_
    GROUP BY check_.Peer
    ORDER BY d DESC;
END;
$$ LANGUAGE plpgsql;

------------------------------ex06------------------------------
CREATE OR REPLACE FUNCTION most_checked_task()
RETURNS TABLE ("Day" DATE, "Task" VARCHAR) AS $$
BEGIN
    RETURN QUERY
        SELECT "Date" AS Day, Task
        FROM Checks
        GROUP BY "Date", Task
        HAVING COUNT(*) = (
            SELECT MAX(cnt)
            FROM (
                SELECT COUNT(*) AS cnt
                FROM Checks
                GROUP BY "Date", Task
            ) x
        )
        ORDER BY Day DESC;
END;
$$ LANGUAGE plpgsql;

------------------------------ex07------------------------------
CREATE OR REPLACE FUNCTION find_completed_block(block_name VARCHAR)
RETURNS TABLE ("Peer" VARCHAR, "Day" DATE ) AS $$
BEGIN
RETURN QUERY
    WITH query_tasks AS (
        SELECT Title
        FROM Tasks
        WHERE Title SIMILAR TO CONCAT(block_name, '[0-9]%')
        ORDER BY Title DESC
        LIMIT 1
    ),
    query_checks AS (
        SELECT Peer, Task, "Date" AS Day
        FROM Checks
        JOIN P2P
        ON Checks.ID = P2P."Check"
        WHERE "State" = 'Success'
    )
    SELECT Peer, Day
    FROM query_checks
    JOIN query_tasks
    ON Task = Title
    ORDER BY Day DESC;
END;
$$ LANGUAGE plpgsql;

------------------------------ex08------------------------------
CREATE OR REPLACE FUNCTION recommended_reviewer_peer()
RETURNS TABLE ("Peer" VARCHAR, "RecommendedPeer" VARCHAR) AS $$
BEGIN
RETURN QUERY
    WITH friend_recommendations AS (SELECT Peer1, recommendedpeer, COUNT(recommendedpeer) as friend_points
                                      FROM Recommendations AS r 
                                      JOIN Friends AS f ON r.Peer = f.Peer2
                                     GROUP BY 1, 2)

    SELECT Peer1 AS peer, recommendedpeer
      FROM friend_recommendations as f
     WHERE friend_points = (SELECT MAX(friend_points)
                              FROM friend_recommendations
                             WHERE Peer1 = f.Peer1)
     ORDER BY 1;
END;
$$ LANGUAGE plpgsql;

------------------------------ex09------------------------------
CREATE OR REPLACE FUNCTION percentage_blocks_completion(block1 VARCHAR, block2 VARCHAR)
RETURNS TABLE ("StartedBlock1" BIGINT, "StartedBlock2" BIGINT, "StartedBothBlocks" BIGINT, "DidntStatrAnyBlocks" BIGINT) AS $$
BEGIN
RETURN QUERY
	WITH start1 AS (
		SELECT DISTINCT Peer
		FROM Checks
		WHERE Task SIMILAR TO CONCAT(block1, '[0-9]%')
	),
	start2 AS (
		SELECT DISTINCT Peer
		FROM Checks
		WHERE Task SIMILAR TO CONCAT(block2, '[0-9]%')
	),
	start_first_only AS(
		SELECT *
		FROM start1
		LEFT JOIN start2 USING(Peer)
		WHERE start2.Peer IS NULL
	),
	start_second_only AS(
		SELECT *
		FROM start2
		LEFT JOIN start1 USING(Peer)
		WHERE start1.Peer IS NULL
	),
	start_both AS (
		SELECT *
		FROM start1
		INTERSECT
		SELECT *
		FROM start2
	),
	didnt_start AS (
		SELECT Nickname
		FROM Peers
		WHERE Nickname NOT IN (SELECT * FROM start1)
        AND Nickname NOT IN (SELECT * FROM start2)
	),
	total AS (
        SELECT COUNT(*) AS peers_count FROM Peers
    ),
    first_count AS (
        SELECT COUNT(*) AS start_first_count FROM start_first_only
    ),
    second_count AS (
        SELECT COUNT(*) AS start_second_count FROM start_second_only
    ),
    both_count AS (
        SELECT COUNT(*) AS start_both_count FROM start_both
    ),
    didnt_start_count AS (
        SELECT COUNT(*) AS didnt_start_count FROM didnt_start
    )
    SELECT
    first_count.start_first_count * 100 / total.peers_count AS StartedBlock1,
    second_count.start_second_count * 100 / total.peers_count AS StartedBlock2,
    both_count.start_both_count * 100 / total.peers_count AS StartedBothBlocks,
    didnt_start_count.didnt_start_count * 100 / total.peers_count AS DidntStatrAnyBlocks
    FROM total, first_count, second_count, both_count, didnt_start_count;
END;
$$ LANGUAGE plpgsql;

------------------------------ex10------------------------------
CREATE OR REPLACE FUNCTION find_percentage_of_peers_with_checks()
RETURNS TABLE ("SuccessfulChecks" REAL, "UnsuccessfulChecks" REAL)
AS
$$
DECLARE
    peers_count REAL := (SELECT COUNT(*) FROM peers);
BEGIN
    RETURN QUERY
    SELECT
        (COUNT(*) FILTER (WHERE "State" = 'Success')::REAL / peers_count * 100.0)::REAL AS SuccessfulChecks,
        (COUNT(*) FILTER (WHERE "State" = 'Failure')::REAL / peers_count * 100.0)::REAL AS UnsuccessfulChecks
    FROM peers
        JOIN checks ON peers.nickname = checks.peer
        JOIN verter ON checks.id = verter."Check"
    WHERE
        TO_CHAR(checks."Date", 'DD.MM') = TO_CHAR(peers.birthday, 'DD.MM')
        AND
        verter."State" IN ('Success', 'Failure');
END;
$$
LANGUAGE PLPGSQL;

------------------------------ex11------------------------------
CREATE OR REPLACE FUNCTION define_peers -- naming
(
    IN task1 VARCHAR,
    IN task2 VARCHAR,
    IN task3 VARCHAR
)
RETURNS TABLE ("Peer" VARCHAR)
AS
$$
BEGIN
    RETURN QUERY
    SELECT Peer
    FROM peers
        JOIN checks ON peers.nickname = checks.peer
        JOIN verter ON checks.id = verter."Check"
        JOIN tasks
            ON checks.task = tasks.title
            AND tasks.title IN (task1, task2, task3)
    WHERE verter."State" IN ('Success', 'Failure')
    GROUP BY Peer
    HAVING
        SUM(CASE WHEN tasks.title = task1 THEN 1 ELSE 0 END) = 1
        AND
        SUM(CASE WHEN tasks.title = task2 THEN 1 ELSE 0 END) = 1
        AND
        SUM(CASE WHEN tasks.title = task3 THEN 1 ELSE 0 END) = 0;
END;
$$
LANGUAGE PLPGSQL;

------------------------------ex12------------------------------
CREATE OR REPLACE FUNCTION find_number_of_previous_tasks()
RETURNS TABLE ("Task" VARCHAR, "PrevCount" INT)
AS
$$
BEGIN
    RETURN QUERY
    WITH RECURSIVE subquery AS
    (
        SELECT
            title,
            0 AS PrevCount
        FROM tasks
        WHERE parenttask IS NULL

        UNION ALL

        SELECT
            t.title,
            sq.PrevCount + 1
        FROM tasks AS t
            JOIN subquery AS sq ON t.parenttask = sq.title
    )
    SELECT * FROM subquery ORDER BY title;
END;
$$
LANGUAGE PLPGSQL;

------------------------------ex13------------------------------
CREATE OR REPLACE FUNCTION find_lucky_days
(
    IN N BIGINT
)
RETURNS TABLE ("Day" DATE)
AS
$$
BEGIN
    RETURN QUERY
    WITH RECURSIVE subquery
    AS
    (
        SELECT
            verter.id AS verter_id,
            checks."Date" AS day,
            (CASE WHEN verter."State" = 'Success' AND xp.xpamount >= tasks.maxxp * 0.8 THEN 1 ELSE 0 END) AS length,
            verter."Time"
        FROM verter
            JOIN checks ON verter."Check" = checks.id
            JOIN xp ON checks.id = xp."Check"
            JOIN tasks ON checks.task = tasks.title
        WHERE verter."Time" = (SELECT MIN("Time") FROM verter)

        UNION ALL

        SELECT
            v.id AS verter_id,
            checks."Date" AS day,
            (CASE
                WHEN v."State" = 'Success' AND xp.xpamount >= tasks.maxxp * 0.8 THEN
                    (CASE
                        WHEN checks."Date" = sq.Day THEN sq.length + 1
                        ELSE 1
                    END)
                WHEN v."State" = 'Start' THEN
                    (CASE
                        WHEN checks."Date" = sq.Day THEN sq.length
                        ELSE 0
                    END)
                ELSE 0
            END) AS length,
            v."Time"
        FROM verter AS v
            JOIN subquery AS sq ON v."Time" = (SELECT MIN("Time") FROM verter WHERE "Time" > (SELECT "Time" FROM verter WHERE id = sq.verter_id))
            JOIN checks ON v."Check" = checks.id
            JOIN xp ON checks.id = xp."Check"
            JOIN tasks ON checks.task = tasks.title
    )
    SELECT day
    FROM subquery
    GROUP BY day
    HAVING MAX(length) >= N
    ORDER BY day;
END;
$$
LANGUAGE PLPGSQL;

------------------------------ex14------------------------------
DROP PROCEDURE IF EXISTS peer_with_highest_xp CASCADE;

CREATE OR REPLACE PROCEDURE peer_with_highest_xp(ex14_cursor refcursor = 'ex14_cursor')
AS
$$
BEGIN
OPEN ex14_cursor FOR
       WITH max_xp AS (SELECT sum(xpamount) AS max_value
                         FROM Checks AS ch
                              JOIN XP ON ch.id = xp."Check"
                        GROUP BY peer
                        ORDER BY 1 DESC
                        LIMIT 1)
       SELECT peer,
              sum(xpamount) AS XP
         FROM Checks AS ch
              JOIN XP ON ch.id = xp."Check"
        GROUP BY peer
       HAVING sum(xpamount) = (SELECT max_value FROM max_xp);
END;
$$ LANGUAGE plpgsql;

------------------------------ex15------------------------------
DROP PROCEDURE IF EXISTS peers_came_before_given_time CASCADE;

CREATE OR REPLACE PROCEDURE peers_came_before_given_time(give_time TIME WITHOUT TIME ZONE, number_of_times INT, ex15_cursor refcursor = 'ex15_cursor')
AS
$$
BEGIN
OPEN ex15_cursor FOR
       SELECT peer
         FROM timetracking
        WHERE "Time" < give_time
        GROUP BY 1
       HAVING count("State" = 1) >= number_of_times;
END;
$$ LANGUAGE plpgsql;

------------------------------ex16------------------------------
DROP PROCEDURE IF EXISTS count_peers_came_out_more_than CASCADE;

CREATE OR REPLACE PROCEDURE count_peers_came_out_more_than(IN number_of_days BIGINT, IN number_of_times BIGINT, IN ex16_cursor refcursor default 'ex16_cursor') AS
$$
BEGIN
OPEN ex16_cursor FOR
    SELECT peer
      FROM TimeTracking
     WHERE "Date" >= (now() - (number_of_days - 1 || ' days')::INTERVAL)
            AND "Date" <= now()
     GROUP BY peer
    HAVING count("State" = 2) >= number_of_times;
END;
$$ LANGUAGE plpgsql;

------------------------------ex17------------------------------
DROP PROCEDURE IF EXISTS early_entry_perc CASCADE;

CREATE OR REPLACE PROCEDURE early_entry_perc(IN ex17_cursor refcursor = 'ex17_cursor') AS
$$
BEGIN
OPEN ex17_cursor FOR
    WITH t_total AS (SELECT EXTRACT('MONTH' FROM p.birthday) AS mnth, COUNT("State" = 1)::numeric AS total_entries
                       FROM Peers as p 
                            LEFT JOIN TimeTracking as tt ON p.nickname = tt.peer
                      GROUP BY 1),
         t_early AS (SELECT EXTRACT('MONTH' FROM p.birthday) AS mnth, COUNT("State" = 1)::numeric AS early_entries
                       FROM Peers as p 
                            LEFT JOIN TimeTracking as tt ON p.nickname = tt.peer
                      WHERE "Time" < '12:00:00'
                      GROUP BY 1)

    SELECT to_char(to_date(t_total.mnth::text, 'MM'), 'Month') AS Month, 
            COALESCE(ROUND((early_entries/total_entries)*100 , 2), 0) AS early_entries
      FROM  t_total 
            LEFT JOIN t_early USING(mnth);

END;
$$ LANGUAGE plpgsql;
