START TRANSACTION;

	-- CREATE DATABASE IF NOT EXISTS u489214;

	-- ALTER DATABASE u489214 CHARACTER SET utf8 COLLATE utf8_unicode_ci;

    CREATE TABLE owners (
        id INT NOT NULL AUTO_INCREMENT,
        name TEXT NOT NULL,
        PRIMARY KEY (id)
    );

    CREATE TABLE types (
        id INT NOT NULL AUTO_INCREMENT,
        name TEXT NOT NULL,
        PRIMARY KEY (id)
    );

    CREATE TABLE titles (
        id INT NOT NULL AUTO_INCREMENT,
        name TEXT NOT NULL,
        PRIMARY KEY (id)
    );

    CREATE TABLE storages (
        id INT NOT NULL AUTO_INCREMENT,
        name TEXT NOT NULL,
        PRIMARY KEY (id)
    );

	CREATE TABLE records_02 (
		id INT NOT NULL AUTO_INCREMENT,
		date DATE NOT NULL,
        owner_id INT NOT NULL,
		type_id INT NOT NULL,
		title_id INT NOT NULL,
		storage_id INT NOT NULL,
		value double NOT NULL,
		PRIMARY KEY (id),
        FOREIGN KEY (owner_id) REFERENCES owners (id),
        FOREIGN KEY (type_id) REFERENCES types (id),
        FOREIGN KEY (title_id) REFERENCES titles (id),
        FOREIGN KEY (storage_id) REFERENCES storages (id)
	);
COMMIT;
