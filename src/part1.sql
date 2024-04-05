DROP TABLE IF EXISTS Peers,
                     Tasks,
                     P2P,
                     Verter,
                     Checks,
                     TransferredPoints,
                     Friends,
                     Recommendations,
                     XP,
                     TimeTracking CASCADE;
DROP TYPE IF EXISTS status CASCADE;

CREATE TABLE IF NOT EXISTS Peers(
    Nickname VARCHAR PRIMARY KEY NOT NULL UNIQUE,
    Birthday DATE
);

CREATE TABLE IF NOT EXISTS Tasks(
    Title      VARCHAR PRIMARY KEY NOT NULL UNIQUE,
	ParentTask VARCHAR REFERENCES Tasks (Title),
	MaxXP      INT     NOT NULL CHECK (MaxXP >= 0)
);

CREATE TABLE IF NOT EXISTS Checks (
	ID   SERIAL  PRIMARY KEY,
	Peer VARCHAR NOT NULL REFERENCES Peers(Nickname),
	Task VARCHAR NOT NULL REFERENCES Tasks(Title),
	"Date" DATE,
	CONSTRAINT uniq_checks UNIQUE (Peer, Task, "Date")
);

CREATE TYPE status AS ENUM ('Start', 'Success', 'Failure');

CREATE TABLE IF NOT EXISTS P2P(
	ID           SERIAL PRIMARY KEY,
	"Check"      BIGINT NOT NULL REFERENCES Checks (ID),
	CheckingPeer VARCHAR NOT NULL REFERENCES Peers (Nickname),
	"State"      status,
	"Time"       TIME NOT NULL,
	CONSTRAINT uniq_p2p UNIQUE ("Check", CheckingPeer, "State", "Time")
);

CREATE TABLE IF NOT EXISTS Verter(
	ID      SERIAL PRIMARY KEY,
	"Check" BIGINT NOT NULL REFERENCES Checks (ID),
	"State" status,
	"Time"  TIME NOT NULL,
	CONSTRAINT uniq_verter UNIQUE ("Check", "State", "Time")
);

CREATE TABLE IF NOT EXISTS TransferredPoints (
	ID			 SERIAL PRIMARY KEY,
	CheckingPeer VARCHAR NOT NULL REFERENCES Peers(Nickname),
	CheckedPeer  VARCHAR NOT NULL REFERENCES Peers(Nickname),
	PointsAmount INT NOT NULL DEFAULT 0,
	CHECK (CheckingPeer != CheckedPeer),
	CONSTRAINT unique_pairs UNIQUE (CheckingPeer, CheckedPeer)
);

CREATE TABLE IF NOT EXISTS Friends (
  	ID    SERIAL  PRIMARY KEY ,
	Peer1 VARCHAR NOT NULL REFERENCES Peers(Nickname),
	Peer2 VARCHAR NOT NULL REFERENCES Peers(Nickname),
	CHECK (Peer1 != Peer2)
);

CREATE TABLE IF NOT EXISTS Recommendations (
	ID 			    SERIAL PRIMARY KEY,
	Peer 			VARCHAR NOT NULL REFERENCES Peers(Nickname),
	RecommendedPeer VARCHAR          REFERENCES Peers(Nickname),
	CHECK (Peer != RecommendedPeer)
);

CREATE TABLE IF NOT EXISTS XP (
	ID       SERIAL PRIMARY KEY,
	"Check"  BIGINT NOT NULL REFERENCES Checks(ID),
	XPAmount BIGINT NOT NULL
);

CREATE TABLE IF NOT EXISTS TimeTracking (
	ID      SERIAL                 PRIMARY KEY,
	Peer    VARCHAR                NOT NULL REFERENCES Peers(Nickname),
	"Date"  DATE                   NOT NULL,
	"Time"  TIME WITHOUT TIME ZONE NOT NULL,
	"State" BIGINT                 NOT NULL CHECK ("State" IN (1, 2))
);

CREATE OR REPLACE FUNCTION check_tasks()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.ParentTask IS NULL AND EXISTS (
        SELECT 1, 2 FROM Tasks WHERE Title = NEW.Title AND ParentTask IS NULL
    ) THEN RAISE EXCEPTION 'Корневая задача может быть только одна';
    END IF;
        IF NEW.ParentTask IS NOT NULL AND NOT EXISTS (
            SELECT 1, 2 FROM Tasks WHERE ParentTask IS NULL
	    ) THEN RAISE EXCEPTION 'Корневой задачи нет';
	END IF;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tg_check_tasks
BEFORE INSERT OR UPDATE ON Tasks
FOR EACH ROW
EXECUTE FUNCTION check_tasks();

CREATE OR REPLACE PROCEDURE import_from_csv(
    IN table_name TEXT,
    IN file_path TEXT,
    separator CHAR(1) DEFAULT ','
)
LANGUAGE plpgsql AS $$
BEGIN
    EXECUTE 'COPY ' || table_name || ' FROM ''' || file_path || ''' WITH CSV DELIMITER ''' || separator || ''';';

END;
$$;

CREATE OR REPLACE PROCEDURE export_to_csv(
    IN table_name TEXT,
    IN file_path TEXT,
    separator CHAR(1) DEFAULT ','
)
LANGUAGE plpgsql AS $$
BEGIN
    EXECUTE 'COPY ' || table_name || ' TO ''' || file_path || ''' WITH CSV DELIMITER ''' || separator || ''';';
END;
$$;