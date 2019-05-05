START TRANSACTION;
    DELETE FROM records_02;
    DELETE FROM owners;
    DELETE FROM storages;
    DELETE FROM types;
    DELETE FROM titles;
COMMIT;
