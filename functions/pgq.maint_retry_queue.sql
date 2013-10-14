-- This file is part of the skytools-sql package.
--
-- (c) 2013 Hi-Media SA
-- (c) 2013 Geoffroy Letournel <gletournel@hi-media.com>
--
-- For the full copyright and license information, please view the LICENSE
-- file that was distributed with this source code.

-- ----------------------------------------------------------------------
-- Function: pgq.maint_retry_queue(1)
--
--      Moves events from retry queue back to the main queue.
--
-- Parameters:
--      x_queue_name        - Name of a queue
--
-- Returns:
--      Returns the number of events moved.
-- ----------------------------------------------------------------------

CREATE OR REPLACE FUNCTION pgq.maint_retry_queue(x_queue_name TEXT)
RETURNS INTEGER AS $$
    DECLARE
        cnt INTEGER := 0;
    BEGIN
        SELECT event_count INTO cnt
          FROM pgq.maint_retry_queue(x_queue_name, 10) AS f (event_count);
        RETURN cnt;
    END;
$$ LANGUAGE plpgsql;


-- ----------------------------------------------------------------------
-- Function: pgq.maint_retry_queue(2)
--
--      Moves events from retry queue back to the main queue.
--
-- Parameters:
--      x_queue_name        - Name of a queue
--      x_count             - Number of events to be moved
--
-- Returns:
--      Returns the number of events moved.
-- ----------------------------------------------------------------------

CREATE OR REPLACE FUNCTION pgq.maint_retry_queue(
    x_queue_name  TEXT,
    x_count       INTEGER
) RETURNS INTEGER AS $$
    DECLARE
        cnt INTEGER := 0;
        rec RECORD;
    BEGIN
        LOCK TABLE pgq.retry_queue IN SHARE UPDATE EXCLUSIVE MODE;

        FOR rec IN
            SELECT queue_name,
                   ev_id, ev_time, ev_owner, ev_retry, ev_type, ev_data,
                   ev_extra1, ev_extra2, ev_extra3, ev_extra4
              FROM pgq.retry_queue, pgq.queue
             WHERE ev_retry_after <= CURRENT_TIMESTAMP
               AND queue_id = ev_owner
               AND queue_name = x_queue_name
             ORDER BY ev_retry_after
             LIMIT x_count
        LOOP
            cnt := cnt + 1;

            PERFORM pgq.insert_event_raw(
                rec.queue_name,
                rec.ev_id, rec.ev_time, rec.ev_owner, rec.ev_retry,
                rec.ev_type, rec.ev_data, rec.ev_extra1, rec.ev_extra2,
                rec.ev_extra3, rec.ev_extra4
            );

            DELETE FROM pgq.retry_queue
             WHERE ev_owner = rec.ev_owner
               AND ev_id = rec.ev_id;
        END LOOP;
        RETURN cnt;
    END;
$$ LANGUAGE plpgsql;
