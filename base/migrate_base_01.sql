START TRANSACTION;
    DELETE FROM owners;
    DELETE FROM storages;
    DELETE FROM types;
    DELETE FROM titles;
    DELETE FROM records_02;
    ALTER TABLE owners AUTO_INCREMENT = 0;
    ALTER TABLE storages AUTO_INCREMENT = 0;
    ALTER TABLE types AUTO_INCREMENT = 0;
    ALTER TABLE titles AUTO_INCREMENT = 0;
    ALTER TABLE records_02 AUTO_INCREMENT = 0;
    INSERT INTO owners (name)
    SELECT DISTINCT owner FROM records ORDER BY 1;
    INSERT INTO storages (name)
    SELECT DISTINCT storage FROM records ORDER BY 1;
    INSERT INTO types (name)
    SELECT DISTINCT type FROM records ORDER BY 1;
    INSERT INTO titles (name)
    SELECT DISTINCT title FROM records ORDER BY 1;
    INSERT INTO records_02 (id, date, owner_id, storage_id, type_id, title_id, value)
    SELECT r.id, r.date, o.id, s.id, t.id, ti.id, r.value FROM records AS r
    LEFT JOIN owners AS o ON o.name = r.owner
    LEFT JOIN storages AS s ON s.name = r.storage
    LEFT JOIN types AS t ON t.name = r.type
    LEFT JOIN titles AS ti ON ti.name = r.title
    ORDER BY 1;
COMMIT;
