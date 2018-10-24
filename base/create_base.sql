START TRANSACTION;

	-- CREATE DATABASE IF NOT EXISTS u489214;

	-- ALTER DATABASE u489214 CHARACTER SET utf8 COLLATE utf8_unicode_ci;

	CREATE TABLE records (
		id INT NOT NULL AUTO_INCREMENT,
		date DATE NOT NULL,
        owner TEXT NOT NULL,
		type TEXT NOT NULL,
		title TEXT NOT NULL,
		storage TEXT NOT NULL,
		value double NOT NULL,
		PRIMARY KEY (id)
	);
COMMIT;

