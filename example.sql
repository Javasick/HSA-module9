# Open two mysql clients, run following scripts in window from comment prefix

###################################################################
# 1. Dirty reads

/*(1)*/ SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
/*(2)*/ START TRANSACTION;
/*(2)*/ UPDATE example SET value = 'updated1' WHERE id = 1;
/*(1)*/ SELECT * FROM example e WHERE id = 1;
# you will see updated value
# +----+----------+
# | id | value    |
# +----+----------+
# |  1 | updated1 |
# +----+----------+

###################################################################
# 1.1 Dirty reads doesn't work with READ COMMITTED isolation level

/*(1)*/ SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;
/*(1)*/ SELECT * FROM example e WHERE id = 1;
# +----+-------+
# | id | value |
# +----+-------+
# |  1 | row1  |
# +----+-------+
/*(2)*/ ROLLBACK;

###################################################################
# 2. Non-repeteable reads in READ COMMITED

/*(1)*/ SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;
/*(1)*/ START TRANSACTION;
/*(2)*/ SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;
/*(2)*/ START TRANSACTION;
/*(2)*/ UPDATE example SET value = 'updated1' WHERE id = 1;
/*(1)*/ SELECT * FROM example e WHERE id = 1;
# +----+-------+
# | id | value |
# +----+-------+
# |  1 | row1  |
# +----+-------+
/*(2)*/ COMMIT;
/*(1)*/ SELECT * FROM example e WHERE id = 1;
# +----+----------+
# | id | value    |
# +----+----------+
# |  1 | updated1 |
# +----+----------+
/*(2)*/ UPDATE example SET value = 'row1' WHERE id = 1;
/*(1)*/ ROLLBACK;

###################################################################
# 2.1 Non-repeteable reads doesn't work in REPEATABLE READ
/*(1)*/ SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
/*(1)*/ START TRANSACTION;
/*(2)*/ SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
/*(2)*/ START TRANSACTION;
/*(2)*/ UPDATE example SET value = 'updated1' WHERE id = 1;
/*(1)*/ SELECT * FROM example e WHERE id = 1;
# +----+-------+
# | id | value |
# +----+-------+
# |  1 | row1  |
# +----+-------+
/*(2)*/ COMMIT;
/*(1)*/ SELECT * FROM example e WHERE id = 1;
# +----+----------+
# | id | value    |
# +----+----------+
# |  1 | row1 |
# +----+----------+
/*(2)*/ UPDATE example SET value = 'row1' WHERE id = 1;
/*(1)*/ ROLLBACK;

###################################################################
# 3. Phantom reads in REPETEABLE READ

/*(1)*/ SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
/*(1)*/ START TRANSACTION;
/*(2)*/ SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
/*(2)*/ START TRANSACTION;
/*(1)*/ SELECT * FROM example;
# +----+-------+
# | id | value |
# +----+-------+
# |  1 | row1  |
# |  2 | row2  |
# |  3 | row3  |
# +----+-------+
/*(2)*/ INSERT INTO example(id, value) VALUES (4, 'row4') ;
/*(2)*/ COMMIT;
/*(1)*/ SELECT * FROM example;
# +----+-------+
# | id | value |
# +----+-------+
# |  1 | row1  |
# |  2 | row2  |
# |  3 | row3  |
# +----+-------+
/*(1)*/ UPDATE example SET value = 'updated';
/*(1)*/ SELECT * FROM example;
# +----+---------+
# | id | value   |
# +----+---------+
# |  1 | updated |
# |  2 | updated |
# |  3 | updated |
# |  4 | updated |
# +----+---------+
/*(1)*/ ROLLBACK;
/*(1)*/ DELETE FROM example WHERE id = 4;

###################################################################
# 3.1 Phantom reads doesn't work in SERIALIZABLE

/*(1)*/ SET SESSION TRANSACTION ISOLATION LEVEL SERIALIZABLE;
/*(1)*/ START TRANSACTION;
/*(2)*/ SET SESSION TRANSACTION ISOLATION LEVEL SERIALIZABLE;
/*(2)*/ START TRANSACTION;
/*(1)*/ SELECT * FROM example;
# +----+-------+
# | id | value |
# +----+-------+
# |  1 | row1  |
# |  2 | row2  |
# |  3 | row3  |
# +----+-------+
/*(2)*/ INSERT INTO example(id, value) VALUES (4, 'row4'); 
# query blocked by transaction 1
# ERROR 1205 (HY000): Lock wait timeout exceeded; try restarting transaction
