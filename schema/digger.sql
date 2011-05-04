CREATE TABLE distro (
    id       INTEGER PRIMARY KEY,
    author   VARCHAR(50),
    name     VARCHAR(255) UNIQUE NOT NULL,
    version  VARCHAR(30),
    path     VARCHAR(255) UNIQUE,
    file_timestamp DATE,
    added_timestamp DATE
);

