CREATE EXTENSION IF NOT EXISTS citext;

CREATE TABLE person (
    id                          serial          PRIMARY KEY,
    name                        text            not null,
    email                       citext          not null unique,
    is_enabled                  boolean         not null default true,
    is_admin                    boolean         not null default false,
    created_at                  timestamptz     not null default current_timestamp
);

-- Settings for a given user.  | Use with care, add things to the data model when you should.
create TABLE person_settings (
    id                          serial          PRIMARY KEY,
    person_id                   int             not null references person(id),
    name                        text            not null,
    value                       json            not null default '{}',
    created_at                  timestamptz     not null default current_timestamp,

    -- Allow ->find_or_new_related()
    CONSTRAINT unq_person_id_name UNIQUE(person_id, name)
);

CREATE TABLE auth_password (
    person_id                   int             not null unique references person(id),
    password                    text            not null,
    salt                        text            not null,
    updated_at                  timestamptz     not null default current_timestamp,
    created_at                  timestamptz     not null default current_timestamp
);

CREATE TABLE auth_token (
    id                          serial          PRIMARY KEY,
    person_id                   int             not null references person(id),
    scope                       text            not null,
    token                       text            not null,
    created_at                  timestamptz     not null default current_timestamp
);

CREATE TABLE ssh_key (
    id                          serial          PRIMARY KEY,
    person_id                   int             not null references person(id),
    title                       text            ,
    public_key                  text            not null,
    private_key                 text            not null,
    created_at                  timestamptz     not null default current_timestamp
);

CREATE TABLE basic_auth (
    id                          serial          PRIMARY KEY,
    person_id                   int             not null references person(id),
    username                    text            not null,
    password                    text            not null,
    created_at                  timestamptz     not null default current_timestamp
);

CREATE TABLE domain (
    id                          serial          PRIMARY KEY,
    person_id                   int             not null references person(id),
    domain                      citext          not null unique,
    created_at                  timestamptz     not null default current_timestamp
);

CREATE TABLE domain_redirect (
    id                          serial          PRIMARY KEY,
    person_id                   int             not null references person(id),
    domain_id                   int             references domain(id),
    redirect_to                 text            not null,
    created_at                  timestamptz     not null default current_timestamp
);

CREATE TABLE builder (
    id                          serial          PRIMARY KEY,
    name                        text            not null,
    title                       text            ,
    description                 text            ,
    doc_url                     text            ,
    img_url                     text            ,
    job_name                    text            not null,
    created_at                  timestamptz     not null default current_timestamp
);

INSERT INTO builder ( name, title, description, doc_url, img_url, job_name ) VALUES (
    'jekyll',
    'Jekyll Blog',
    'This builder will process your repository with the jekyll/jekyll docker image to build your website.',
    'https://docs.markdownsite.com/builder/jekyll',
    '/assets/img/logo-jekyll.png',
    'build_jekyll'
);

INSERT INTO builder ( name, title, description, doc_url, img_url, job_name ) VALUES (
    'static',
    'Hand-Rolled HTML/CSS/JS',
    'This builder assumes the entire website is in the public/ directory of your repo.',
    'https://docs.markdownsite.com/builder/static',
    '',
    'build_static'
);

CREATE TABLE site (
    id                          serial          PRIMARY KEY,
    person_id                   int             not null references person(id),
    domain_id                   int             references domain(id),
    builder_id                  int             references builder(id),

    -- Settings: File Allowances
    max_static_file_count       int             not null default 100,
    max_static_file_size        int             not null default   2, -- MiB
    max_static_webroot_size     int             not null default  50, -- MiB

    -- Settings: Build Timers
    minutes_wait_after_build    int             not null default 10,
    builds_per_hour             int             not null default  3,
    builds_per_day              int             not null default 12,

    -- Settings: Features
    build_priority              int             not null default 1,

    is_enabled                  boolean         not null default true,
    created_at                  timestamptz     not null default current_timestamp
);

CREATE TABLE repo (
    id                          serial          PRIMARY KEY,
    site_id                     int             references site(id),
    url                         text            not null,

    -- Auth methods for the url.
    basic_auth_id               int             references basic_auth(id),
    ssh_key_id                  int             references ssh_key(id),

    created_at                  timestamptz     not null default current_timestamp
);

-- Attributes for a given machine.  | Use with care, add things to the data model when you should.
create TABLE site_attribute (
    id                          serial          PRIMARY KEY,
    site_id                     int             not null references site(id),
    name                        text            not null,
    value                       json            not null default '{}',
    created_at                  timestamptz     not null default current_timestamp,

    -- Allow ->find_or_new_related()
    CONSTRAINT unq_site_id_name UNIQUE(site_id, name)
);

CREATE TABLE build (
    id                          serial          PRIMARY KEY,
    site_id                     int             not null references site(id),
    job_id                      int             not null, -- For minion->job($id)
    created_at                  timestamptz     not null default current_timestamp
);
