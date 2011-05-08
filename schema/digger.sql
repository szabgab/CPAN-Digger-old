CREATE TABLE distro (
    id       INTEGER PRIMARY KEY,
    author   VARCHAR(50) NOT NULL,
    name     VARCHAR(255) NOT NULL,
    version  VARCHAR(30) NOT NULL,
    path     VARCHAR(255) UNIQUE NOT NULL,
    file_timestamp DATE,
    added_timestamp DATE
);
CREATE INDEX distro_author_idx ON distro (author);
CREATE INDEX distro_name_idx   ON distro (name);

CREATE TABLE author (
    pauseid   VARCHAR(50) PRIMARY KEY,
    name      VARCHAR(255),
    email     VARCHAR(255),
    asciiname VARCHAR(255),
    homepage  VARCHAR(255)
);

CREATE TABLE word_types (
    id       INTEGER PRIMARY KEY,
    name     VARCHAR(50) UNIQUE NOT NULL
);
CREATE INDEX word_types_idx ON word_types (name);
INSERT INTO word_types VALUES(1, 'distro_name');
INSERT INTO word_types VALUES(2, 'abstract');
INSERT INTO word_types VALUES(3, 'meta_keyword');


CREATE TABEL words (
    word    VARCHAR(30) NOT NULL,
    type    INTEGER NOT NULL,
    distro  INTEGER NOT NULL,
    source  VARCHAR(100) NOT NULL,
    FOREIGN KEY(type)    REFERENCES word_types (id),
    FOREIGN KEY(distro)  REFERENCES distro (id)
);
CREATE INDEX words_word_idx ON words (word);

CREATE TABLE modules (
    id       INTEGER PRIMARY KEY,
    name     VARCHAR(255) UNIQUE NOT NULL
);

