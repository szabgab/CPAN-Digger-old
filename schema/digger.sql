CREATE TABLE distro (
    id       INTEGER PRIMARY KEY,
    author   VARCHAR(50) NOT NULL,
    name     VARCHAR(255) NOT NULL,
    version  VARCHAR(30) NOT NULL,
    path     VARCHAR(255) UNIQUE,
    file_timestamp DATE,
    added_timestamp DATE
);
CREATE INDEX distro_author_idx ON distro (author);

CREATE TABLE author (
    pauseid   VARCHAR(50) PRIMARY KEY,
    name      VARCHAR(255),
    email     VARCHAR(255),
    asciiname VARCHAR(255),
    homepage  VARCHAR(255)
);

CREATE TABLE modules (
    id       INTEGER PRIMARY KEY,
    name     VARCHAR(255) UNIQUE NOT NULL
);

