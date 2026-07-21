    ## Schema versioning is not yet active

    Current verified state:

    - PostgreSQL contains `users` and `processing_log`;
    - `flyway_schema_history` is absent;
    - schema creation is currently Hibernate-managed.

    Impact:

    - schema evolution is not yet tracked through explicit versioned migrations.

    Recommended next step:

    - introduce Flyway migrations and switch Hibernate schema mode accordingly.