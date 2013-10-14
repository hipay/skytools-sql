-- This file is part of the skytools-sql package.
--
-- (c) 2013 Hi-Media SA
-- (c) 2013 Geoffroy Letournel <gletournel@hi-media.com>
--
-- For the full copyright and license information, please view the LICENSE
-- file that was distributed with this source code.
--
-- ----------------------------------------------------------------------
-- Function: pgq.get_failed_queue_info(0)
--
--      Returns info about failed events on all consumers.
--
-- Returns:
--      queue_name          - Queue name
--      consumer_name       - Consumer name
--      failed_events       - Size of the failed queue
--      last_failure        - Date of the last failed event
--      last_event_id       - ID of the last failed event
-- ----------------------------------------------------------------------

CREATE OR REPLACE FUNCTION pgq.get_failed_queue_info(
    OUT queue_name      TEXT,
    OUT consumer_name   TEXT,
    OUT failed_events   BIGINT,
    OUT last_failure    TIMESTAMPTZ,
    OUT last_event_id   BIGINT
) RETURNS SETOF RECORD AS $$
    BEGIN
        FOR queue_name,
            consumer_name,
            failed_events,
            last_failure,
            last_event_id
        IN
            SELECT fx.queue_name, fx.consumer_name,
                   fx.failed_events, fx.last_failure, fx.last_event_id
              FROM pgq.get_failed_queue_info(NULL, NULL) AS fx
        LOOP
            RETURN NEXT;
        END LOOP;
    END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ----------------------------------------------------------------------
-- Function: pgq.get_failed_queue_info(1)
--
--      Returns info about failed events on a single queue.
--
-- Parameters:
--      x_queue_name        - Name of a queue (null = all)
--
-- Returns:
--      queue_name          - Queue name
--      consumer_name       - Consumer name
--      failed_events       - Size of the failed queue
--      last_failure        - Date of the last failed event
--      last_event_id       - ID of the last failed event
-- ----------------------------------------------------------------------

CREATE OR REPLACE FUNCTION pgq.get_failed_queue_info(
    IN  x_queue_name    TEXT,
    OUT queue_name      TEXT,
    OUT consumer_name   TEXT,
    OUT failed_events   BIGINT,
    OUT last_failure    TIMESTAMPTZ,
    OUT last_event_id   BIGINT
) RETURNS SETOF RECORD AS $$
    BEGIN
        FOR queue_name,
            consumer_name,
            failed_events,
            last_failure,
            last_event_id
        IN
            SELECT fx.queue_name, fx.consumer_name,
                   fx.failed_events, fx.last_failure, fx.last_event_id
              FROM pgq.get_failed_queue_info(x_queue_name, NULL) AS fx
        LOOP
            RETURN NEXT;
        END LOOP;
    END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ----------------------------------------------------------------------
-- Function: pgq.get_failed_queue_info(2)
--
--      Get info about failed events on a particular consumer/queue.
--
-- Parameters:
--      x_queue_name        - Name of a queue (null = all)
--      x_consumer_name     - name of a consumer (null = all)
--
-- Returns:
--      queue_name          - Queue name
--      consumer_name       - Consumer name
--      failed_events       - Size of the failed queue
--      last_failure        - Date of the last failed event
--      last_event_id       - ID of the last failed event
-- ----------------------------------------------------------------------

CREATE OR REPLACE FUNCTION pgq.get_failed_queue_info(
    IN  x_queue_name    TEXT,
    IN  x_consumer_name TEXT,
    OUT queue_name      TEXT,
    OUT consumer_name   TEXT,
    OUT failed_events   BIGINT,
    OUT last_failure    TIMESTAMPTZ,
    OUT last_event_id   BIGINT
) RETURNS SETOF RECORD AS $$
    BEGIN
        FOR queue_name,
            consumer_name,
            failed_events,
            last_failure,
            last_event_id
        IN
            SELECT q.queue_name, c.co_name, COALESCE(COUNT(f.ev_id), 0),
                   MAX(f.ev_failed_time)::TIMESTAMPTZ(0), MAX(f.ev_id)
              FROM pgq.subscription s
                   JOIN pgq.consumer c ON (s.sub_consumer = c.co_id)
                   JOIN pgq.queue q ON (s.sub_queue = q.queue_id)
                   LEFT JOIN pgq.failed_queue f ON (s.sub_id = f.ev_owner)
             WHERE (x_queue_name IS NULL OR q.queue_name = x_queue_name)
               AND (x_consumer_name IS NULL OR c.co_name = x_consumer_name)
             GROUP BY q.queue_name, c.co_name
             ORDER BY q.queue_name, c.co_name
        LOOP
            RETURN NEXT;
        END LOOP;
    END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
