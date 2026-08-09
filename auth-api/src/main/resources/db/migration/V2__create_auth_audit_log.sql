create table auth_audit_log (
    id bigserial primary key,
    email varchar(255) not null,
    action varchar(50) not null,
    success boolean not null,
    created_at timestamp with time zone not null default current_timestamp
);
