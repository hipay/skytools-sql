Scripts and add-ons for SkyTools
================================

SkyTools is a toolset for PostgreSQL that includes a queuing mechanism called PgQ.

Features
--------

* Retrieving info about failed events
* Retrieving info about events to be processed again later
* Performing maintenance on a particular queue

Requirements
------------

Scripts and add-ons provided by this project are only supported on SkyTools 2.x

Be warned that SkyTools versions upper to 3.0 does not handle "failed events" anymore.

Usage
-----

### Retrieving info about failed events

* **pgq.get_failed_queue_info(0)**

  Returns info about failed events on all consumers.

  ```
  pgq.get_failed_queue_info() returns setof record

  -- Returns:
  --      queue_name          - Queue name
  --      consumer_name       - Consumer name
  --      failed_events       - Size of the failed queue
  --      last_failure        - Date of the last failed event
  --      last_event_id       - ID of the last failed event
  ```

* **pgq.get_failed_queue_info(1)**

  Returns info about failed events on a single queue.

  ```
  pgq.get_failed_queue_info(x_queue_name text) returns setof record

  -- Parameters:
  --      x_queue_name        - Name of a queue (null = all)
  --
  -- Returns:
  --      queue_name          - Queue name
  --      consumer_name       - Consumer name
  --      failed_events       - Size of the failed queue
  --      last_failure        - Date of the last failed event
  --      last_event_id       - ID of the last failed event
  ```

* **pgq.get_failed_queue_info(2)**

  Get info about failed events on a particular consumer/queue.

  ```
  pgq.get_failed_queue_info(x_queue_name text,
                            x_consumer_name text) returns setof record

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
  ```

### Retrieving info about events to be processed again later

* **pgq.get_retry_queue_info(0)**

  Returns info about events in retry queue for all consumers.

  ```
  pgq.get_retry_queue_info() returns setof record

  -- Returns:
  --      queue_name          - Queue name
  --      consumer_name       - Consumer name
  --      retry_events        - Size of the retry queue
  ```

* **pgq.get_retry_queue_info(1)**

  Returns info about events in a single retry queue for all subscribed consumers.

  ```
  pgq.get_retry_queue_info(x_queue_name text) returns setof record

  -- Parameters:
  --      x_queue_name        - Name of a queue (null = all)
  --
  -- Returns:
  --      queue_name          - Queue name
  --      consumer_name       - Consumer name
  --      retry_events        - Size of the retry queue
  ```

* **pgq.get_retry_queue_info(2)**

  Get info about events of a particular retry queue, for a particular consumer.

  ```
  pgq.get_retry_queue_info(x_queue_name text,
                           x_consumer_name text) returns setof record

  -- Parameters:
  --      x_queue_name        - Name of a queue (null = all)
  --      x_consumer_name     - Name of a consumer (null = all)
  --
  -- Returns:
  --      queue_name          - Queue name
  --      consumer_name       - Consumer name
  --      retry_events        - Size of the retry queue
  ```

### Performing maintenance on a particular queue

Both functions below enable you to move events back from retry queue to main queue. This feature
is originally provided by the maintenance routine (see `pgq.maint_retry_events()`), but unfortunately
doesn't allow you to perform a maintenance over only one queue.

* **pgq.maint_retry_queue(1)**

  Moves events from retry queue back to the main queue.
  Returns the number of events moved.

  ```
  pgq.maint_retry_queue(x_queue_name text) returns integer
  ```

* **pgq.maint_retry_queue(2)**

  Moves events from retry queue back to the main queue.
  Returns the number of events moved.

  ```
  pgq.maint_retry_queue(x_queue_name text, x_count integer) returns integer
  ```

Branching Model
---------------

The git branching model used for development is the one described and assisted by the Twgit tool:
<https://github.com/Twenga/twgit>
