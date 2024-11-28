-- Your answers here:
-- 1
SELECT type, SUM(mount) AS total
FROM  accounts
group by type
-- 2
SELECT count(u.name) as user_w_least_two_accounts
FROM users AS u
         INNER JOIN accounts AS a ON u.id = a.user_id
WHERE a.type = 'CURRENT_ACCOUNT'
HAVING count(a.id) >= 2;
-- 3
SELECT id, mount
FROM accounts
ORDER BY mount DESC
LIMIT 5;
-- 4
DO
$$
    DECLARE
        account_balance RECORD;
    BEGIN
        FOR account_balance IN
            WITH account_balances AS (SELECT u.name,
                                             a.account_id,
                                             a.mount        AS initial_mount,
                                             COALESCE(SUM(
                                                              CASE
                                                                  WHEN m.type = 'TRANSFER' AND m.account_from = a.id
                                                                      THEN -m.mount
                                                                  WHEN m.type = 'TRANSFER' AND m.account_to = a.id
                                                                      THEN m.mount
                                                                  WHEN m.type = 'IN' AND m.account_from = a.id
                                                                      THEN m.mount
                                                                  WHEN m.type = 'OUT' AND m.account_from = a.id
                                                                      THEN -m.mount
                                                                  WHEN m.type = 'OTHER' AND m.account_from = a.id
                                                                      THEN m.mount
                                                                  ELSE 0
                                                                  END
                                                      ), 0) AS movement_total
                                      FROM users AS u
                                               INNER JOIN accounts AS a ON u.id = a.user_id
                                               LEFT JOIN movements AS m ON a.id IN (m.account_from, m.account_to)
                                      GROUP BY u.id, u.name, a.account_id, a.mount)
            SELECT account_id,
                   (initial_mount + movement_total) AS updated_balance
            FROM account_balances

            LOOP
                UPDATE accounts
                SET mount = account_balance.updated_balance
                WHERE account_id = account_balance.account_id;
            END LOOP;
    END
$$;

SELECT u.name,
       a.mount
FROM users AS u
         INNER JOIN accounts AS a
                    ON U.id = a.user_id
ORDER BY a.mount
LIMIT 3;
-- 5
---A
SELECT id, mount
FROM accounts
WHERE accounts.id = '3b79e403-c788-495a-a8ca-86ad7643afaf' OR accounts.id = 'fd244313-36e5-4a17-a27c-f8265bc46590';
---B
DO
$$
    DECLARE
        movement RECORD;
        updated_account_record RECORD;
    BEGIN
        INSERT INTO movements(id, type, account_from, account_to, mount)
        VALUES (gen_random_uuid(),
                'TRANSFER',
                '3b79e403-c788-495a-a8ca-86ad7643afaf',
                'fd244313-36e5-4a17-a27c-f8265bc46590',
                50.75)
        RETURNING * INTO movement;

        FOR updated_account_record IN
            UPDATE accounts
            SET mount = CASE
                            WHEN id = movement.account_from THEN mount - movement.mount
                            WHEN id = movement.account_to THEN mount + movement.mount
                        END
            WHERE id = movement.account_from
            OR id = movement.account_to
            RETURNING *
        LOOP
            IF updated_account_record.mount < 0 THEN
                RAISE NOTICE 'Invalid movement: Negative balance in account %. Rolling back.', updated_account_record.id;
                ROLLBACK;
                RETURN; 
            END IF;
        END LOOP;

        RAISE NOTICE 'Transaction successful: Movement ID % from % to % for %.', movement.id, movement.account_from, movement.account_to, movement.mount;
        COMMIT;


    END
$$;

---C


-- 6

-- 7

