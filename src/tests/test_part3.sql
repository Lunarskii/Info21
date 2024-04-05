--ex01--
BEGIN;
SELECT * 
FROM get_transferred_points();
END;

--ex02--
BEGIN;
SELECT *
FROM get_checks();
END;

--ex03--
BEGIN;
SELECT *
FROM peers_not_leaving_campus('2023-05-31');
END;

--ex04--
BEGIN;
SELECT *
FROM get_points_change();
END;

--ex05--
BEGIN;
SELECT *
FROM get_points_change_2();
END;

--ex06--
BEGIN;
SELECT to_char("Day", 'DD.MM.YYYY') AS "Day", "Task"
FROM most_checked_task();
END;

--ex07--
BEGIN;
SELECT "Peer", to_char("Day", 'DD.MM.YYYY') AS "Day"
FROM find_completed_block('DO');
END;

--ex08--
BEGIN;
SELECT *
FROM recommended_reviewer_peer();
END;

--ex09--
BEGIN;
SELECT *
FROM percentage_blocks_completion('C', 'DO');
END;

--ex10--
BEGIN;
SELECT *
FROM find_percentage_of_peers_with_checks();
END;

--ex11--
BEGIN;
SELECT *
FROM define_peers (
    'C3_s21_string+',
    'C4_s21_math',
    'C8_3DViewer'
);
END;

--ex12--
BEGIN;
SELECT *
FROM find_number_of_previous_tasks();
END;

--ex13--
BEGIN;
SELECT *
FROM find_lucky_days(1);
END;

--ex14--
BEGIN;
CALL peer_with_highest_xp();
FETCH ALL FROM "ex14_cursor";
END;

--ex15--
BEGIN;
CALL peers_came_before_given_time('16:32:00'::TIME, 1);
FETCH ALL FROM "ex15_cursor";
END;

--ex16--
BEGIN;
CALL count_peers_came_out_more_than(500, 1);
FETCH ALL IN "ex16_cursor";
END;

--ex17--
BEGIN;
CALL early_entry_perc();
FETCH ALL IN "ex17_cursor";
END;
