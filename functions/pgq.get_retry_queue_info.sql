-- This file is part of the skytools-sql package.
--
-- (c) 2013 Hi-Media SA
-- (c) 2013 Geoffroy Letournel <gletournel@hi-media.com>
--
-- For the full copyright and license information, please view the LICENSE
-- file that was distributed with this source code.

-- ----------------------------------------------------------------------
-- Function: pgq.get_retry_queue_info(0)
--
--      Returns info about events in retry queue for all consumers.
--
-- Returns:
--      queue_name          - Queue name
--      consumer_name       - Consumer name
--      retry_events        - Size of the retry queue
-- ----------------------------------------------------------------------

CREATE OR REPLACE FUNCTION pgq.get_retry_queue_info(
    OUT queue_name       TEXT,
    OUT consumer_name    TEXT,
    OUT retry_events     BIGINT
) RETURNS SETOF RECORD AS $$
    BEGIN
        FOR queue_name, consumer_name, retry_events
        IN
            SELECT fx.queue_name, fx.consumer_name, fx.retry_events
              FROM pgq.get_retry_queue_info(NULL, NULL) AS fx
        LOOP
            RETURN NEXT;
        END LOOP;
    END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- ----------------------------------------------------------------------
-- Function: pgq.get_retry_queue_info(1)
--
--      Returns info about events in a single retry queue for
--      all subscribed consumers.
--
-- Parameters:
--      x_queue_name        - Name of a queue (null = all)
--
-- Returns:
--      queue_name          - Queue name
--      consumer_name       - Consumer name
--      retry_events        - Size of the retry queue
-- ----------------------------------------------------------------------

CREATE OR REPLACE FUNCTION pgq.get_retry_queue_info(
    IN  x_queue_name     TEXT,
    OUT queue_name       TEXT,
    OUT consumer_name    TEXT,
    OUT retry_events     BIGINT
) RETURNS SETOF RECORD AS $$
    BEGIN
        FOR queue_name, consumer_name, retry_events
        IN
            SELECT fx.queue_name, fx.consumer_name, fx.retry_events
              FROM pgq.get_retry_queue_info(x_queue_name, NULL) AS fx
        LOOP
            RETURN NEXT;
        END LOOP;
    END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- ----------------------------------------------------------------------
-- Function: pgq.get_retry_queue_info(2)
--
--      Get info about events of a particular retry queue,
--      for a particular consumer.
--
-- Parameters:
--      x_queue_name        - Name of a queue (null = all)
--      x_consumer_name     - Name of a consumer (null = all)
--
-- Returns:
--      queue_name          - Queue name
--      consumer_name       - Consumer name
--      retry_events        - Size of the retry queue
-- ----------------------------------------------------------------------

CREATE OR REPLACE FUNCTION pgq.get_retry_queue_info(
    IN  x_queue_name     TEXT,
    IN  x_consumer_name  TEXT,
    OUT queue_name       TEXT,
    OUT consumer_name    TEXT,
    OUT retry_events     BIGINT
) RETURNS SETOF RECORD AS $$
    BEGIN
        FOR queue_name, consumer_name, retry_events
        IN
            SELECT q.queue_name, c.co_name, COALESCE(COUNT(r.ev_id), 0)
              FROM pgq.subscription s
                   JOIN pgq.consumer c ON (s.sub_consumer = c.co_id)
                   JOIN pgq.queue q ON (s.sub_queue = q.queue_id)
                   LEFT JOIN pgq.retry_queue r ON (s.sub_id = r.ev_owner)
             WHERE (x_queue_name IS NULL OR q.queue_name = x_queue_name)
               AND (x_consumer_name IS NULL OR c.co_name = x_consumer_name)
             GROUP BY q.queue_name, c.co_name
             ORDER BY q.queue_name, c.co_name
        LOOP
            RETURN NEXT;
        END LOOP;
    END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
