
------------------------------ex01------------------------------
CREATE OR REPLACE PROCEDURE add_peer_review
(
    IN reviewing_peer VARCHAR,
    IN reviewer_peer VARCHAR,
    IN task_title VARCHAR,
    IN p2p_verification_status status,
    IN event_time TIME
)
AS
$$
DECLARE
    review_id BIGINT;
BEGIN
    IF (p2p_verification_status = 'Start') THEN
        INSERT INTO checks (id, peer, task, "Date")
        VALUES ((SELECT MAX(id) + 1 FROM checks), reviewing_peer, task_title, NOW())
        RETURNING id INTO review_id;
    ELSE
        SELECT "Check"
        FROM p2p
            JOIN checks ON p2p."Check" = checks.id
        WHERE
            p2p.checkingpeer = reviewer_peer
            AND
            checks.peer = reviewing_peer
            AND
            checks.task = task_title
        INTO review_id;
    END IF;

    INSERT INTO p2p (id, "Check", checkingpeer, "State", "Time")
    VALUES ((SELECT MAX(id) + 1 FROM p2p), review_id, reviewer_peer, p2p_verification_status, event_time);
END;
$$
LANGUAGE PLPGSQL;

------------------------------ex02------------------------------
CREATE OR REPLACE PROCEDURE add_verter_review
(
    IN reviewing_peer VARCHAR,
    IN task_title VARCHAR,
    IN verter_verification_status status,
    IN event_time TIME
)
AS
$$
DECLARE
    review_id BIGINT;
BEGIN
    SELECT "Check"
    FROM p2p
        JOIN checks ON p2p."Check" = checks.id
    WHERE
        checks.peer = reviewing_peer
        AND
        checks.task = task_title
        AND
        p2p."State" = 'Success'
    ORDER BY p2p."Time" DESC
    LIMIT 1
    INTO review_id;

    IF (review_id IS NOT NULL) THEN
        INSERT INTO verter (id, "Check", "State", "Time")
        VALUES ((SELECT MAX(id) + 1 FROM verter), review_id, verter_verification_status, event_time);
    END IF;
END;
$$
LANGUAGE PLPGSQL;

------------------------------ex03------------------------------
CREATE OR REPLACE FUNCTION fnc_trg_p2p_insert_audit()
RETURNS TRIGGER
AS
$$
DECLARE
    reviewer_peer VARCHAR;
    reviewing_peer VARCHAR;
BEGIN
    SELECT
        p2p.checkingpeer,
        checks.peer
    FROM checks
        JOIN transferredpoints ON checks.peer = transferredpoints.checkedpeer
        JOIN p2p ON checks.id = p2p."Check"
    WHERE
        p2p."Check" = NEW."Check"
        AND
        p2p."State" = NEW."State"
    INTO reviewer_peer, reviewing_peer;

    INSERT INTO transferredpoints (id, checkingpeer, checkedpeer, pointsamount)
    VALUES ((SELECT MAX(id) + 1 FROM transferredpoints), reviewer_peer, reviewing_peer, 1)
    ON CONFLICT (checkingpeer, checkedpeer)
    DO UPDATE SET pointsamount = transferredpoints.pointsamount + 1;

    RETURN NULL;
END;
$$
LANGUAGE PLPGSQL;

CREATE OR REPLACE TRIGGER trg_p2p_insert_audit
    AFTER INSERT
    ON p2p
    FOR EACH ROW
    WHEN (NEW."State" = 'Start')
EXECUTE FUNCTION fnc_trg_p2p_insert_audit();

------------------------------ex04------------------------------
CREATE OR REPLACE FUNCTION fnc_trg_xp_insert_audit()
RETURNS TRIGGER
AS
$$
BEGIN
    IF (
        (SELECT tasks.maxxp
        FROM checks
            JOIN tasks ON checks.task = tasks.title
            JOIN verter ON checks.id = verter."Check"
        WHERE
            checks.id = NEW."Check"
            AND
            tasks.maxxp >= NEW.xpamount
            AND
            verter."State" = 'Success')
        IS NOT NULL
        ) THEN RETURN NEW;
    END IF;

    RETURN NULL;
END;
$$
LANGUAGE PLPGSQL;

CREATE OR REPLACE TRIGGER trg_xp_insert_audit
    BEFORE INSERT
    ON xp
    FOR EACH ROW
EXECUTE FUNCTION fnc_trg_xp_insert_audit();
