CREATE TABLE distro (
    id       INTEGER PRIMARY KEY,
    author   VARCHAR(50) NOT NULL,
    name     VARCHAR(255) NOT NULL,
    version  VARCHAR(30) NOT NULL,
    path     VARCHAR(255) UNIQUE,
    file_timestamp DATE,
    added_timestamp DATE
);

