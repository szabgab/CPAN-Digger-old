CREATE TABLE distro (
    id       INTEGER PRIMARY KEY,
    author   VARCHAR(50) NOT NULL,
    name     VARCHAR(255) NOT NULL,
    version  VARCHAR(30) NOT NULL,
    path     VARCHAR(255) UNIQUE NOT NULL,
    file_timestamp DATE,
    added_timestamp DATE,

    unzip_error VARCHAR(20),
    unzip_error_details TEXT
);
CREATE INDEX distro_author_idx ON distro (author);
CREATE INDEX distro_name_idx   ON distro (name);

CREATE TABLE distro_details (
    id                INTEGER UNIQUE NOT NULL,
    has_meta_yml      BOOL,
    has_meta_json     BOOL,
    has_t             BOOL,
    has_xt            BOOL,
    test_file         BOOL,
    examples          VARCHAR(100),
    meta_homepage     VARCHAR(100),
    meta_repository   VARCHAR(100),
    meta_abstract     VARCHAR(100),
    meta_license      VARCHAR(30),
    meta_version      VARCHAR(20),
    special_files     VARCHAR(1000),
    pods              VARCHAR(1000),
    min_perl          VARCHAR(20),
    critic            TEXT,
    FOREIGN KEY(id)   REFERENCES distro (id)
);


CREATE TABLE author (
    pauseid      VARCHAR(50) PRIMARY KEY,
    name         VARCHAR(255),
    email        VARCHAR(255),
    asciiname    VARCHAR(255),
    homepage     VARCHAR(255),
    author_json  VARCHAR(50),
    homedir   BOOL
);

CREATE TABLE author_json (
    pauseid   VARCHAR(50) NOT NULL,
    field     VARCHAR(50) NOT NULL,
    name      VARCHAR(50) NOT NULL,
    id        VARCHAR(50) NOT NULL
);
CREATE INDEX author_profile_pauseid_idx ON author_json (pauseid);
CREATE INDEX author_profile_name_idx ON author_json (name);
CREATE INDEX author_profile_field_idx ON author_json (field);

CREATE TABLE word_types (
    id       INTEGER PRIMARY KEY,
    name     VARCHAR(50) UNIQUE NOT NULL
);
CREATE INDEX word_types_idx ON word_types (name);
INSERT INTO word_types VALUES(1, 'distro_name');
INSERT INTO word_types VALUES(2, 'abstract');
INSERT INTO word_types VALUES(3, 'meta_keyword');

CREATE TABLE words (
    word    VARCHAR(30) NOT NULL,
    type    INTEGER NOT NULL,
    distro  INTEGER NOT NULL,
    source  VARCHAR(100) NOT NULL,
    FOREIGN KEY(type)    REFERENCES word_types (id),
    FOREIGN KEY(distro)  REFERENCES distro (id)
);
CREATE INDEX words_word_idx ON words (word);

CREATE TABLE module (
    id       INTEGER PRIMARY KEY,
    name     VARCHAR(255) UNIQUE NOT NULL,
    abstract VARCHAR(255),
    min_perl VARCHAR(20),
    is_module BOOL,
    distro   INTEGER NOT NULL,
    FOREIGN KEY(distro)  REFERENCES distro (id)
);
CREATE INDEX module_name_idx ON module (name);

CREATE TABLE subs (
    name      VARCHAR(255) NOT NULL,
    module_id INTEGER NOT NULL,
    line      INTEGER NOT NULL,
    FOREIGN KEY(module_id)  REFERENCES module (id)
);

