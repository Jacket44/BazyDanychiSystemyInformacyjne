#1
 CREATE DATABASE Hobby;

 CREATE USER 'Mateusz19'@'localhost' IDENTIFIED BY '919442';

GRANT SELECT, INSERT, UPDATE ON Hobby.* TO 'Mateusz19'@'localhost';

#2
	CREATE TABLE osoba (id int NOT NULL AUTO_INCREMENT, imię varchar(20) NOT NULL, dataUrodzenia date NOT NULL, plec char(1) NOT NULL, PRIMARY KEY (id));

	# Cannot use CURDATE() in CHECK, instead we use Trigger:
	
	DELIMITER //

	CREATE TRIGGER Over18
	BEFORE INSERT ON osoba
	FOR EACH ROW
	BEGIN
	IF NEW.dataUrodzenia > DATE_SUB(CURDATE(), INTERVAL 18 YEAR) THEN
	SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'User not over 18!'; END IF; END //

	DELIMITER ;

	CREATE TABLE sport (id int NOT NULL AUTO_INCREMENT,
        nazwa varchar(20) NOT NULL,
        typ enum('indywidualny', 'drużynowy', 'mieszany') NOT NULL DEFAULT 'drużynowy',
        lokacja varchar(20),
        PRIMARY KEY (id));

	CREATE TABLE nauka (id int NOT NULL AUTO_INCREMENT,
                          nazwa varchar(20) NOT NULL,
                          lokacja varchar(20),
                          PRIMARY KEY (id));

	CREATE TABLE inne (id int NOT NULL AUTO_INCREMENT,
                          nazwa varchar(20) NOT NULL,
                          lokacja varchar(20),
                          towarzysze bool NOT NULL DEFAULT true,
                          PRIMARY KEY (id));

	CREATE TABLE hobby(osoba int NOT NULL,
                          id int NOT NULL AUTO_INCREMENT,
                          typ enum('sport', 'nauka', 'inne') NOT NULL,
                          PRIMARY KEY (id, osoba, typ));

#3 
	CREATE TABLE zwierzak (name    VARCHAR(20),
                            owner   VARCHAR(20),
                            species VARCHAR(20),
                            sex     CHAR(1),
                            birth   DATE,
                            death   DATE);
	# Had to use option "--local-infile true" when turning mycli on, not secure stuff.
	LOAD DATA LOCAL INFILE '/path/to/pet.txt'
                          INTO TABLE zwierzak;

	INSERT INTO osoba (imię, dataUrodzenia, plec) VALUES ('Harold', '1998-12-31', 'M'), ('Gwen', '2000-04-12', 'F'), ('Benny', '1975-06-01', 'M'), ('Diane', '1979-08-31', 'F');

#4
	ALTER TABLE osoba
        ADD nazwisko varchar(50);

	ALTER TABLE zwierzak
	DROP COLUMN owner;

	ALTER TABLE zwierzak
	ADD ownerID INT;

#5
	ALTER TABLE zwierzak
	ADD FOREIGN KEY (ownerID) REFERENCES osoba(id);

	ALTER TABLE hobby
	ADD FOREIGN KEY (osoba) REFERENCES osoba(id);

#6
	ALTER TABLE inne AUTO_INCREMENT = 7000;

#7
	# DELIMITER DOES NOT WORK IN mycli #
	# hobby has problem with duplicates, just create random records until done.
	DELIMITER //		

CREATE DEFINER=`jkt44`@`localhost` PROCEDURE `RandomRecords`(IN name varchar(20), IN num INT)
BEGIN
DECLARE i INT DEFAULT 0;
	CASE
		WHEN name = 'osoba' THEN
			WHILE i < num DO
				INSERT INTO osoba (imię, dataUrodzenia, plec, nazwisko) VALUES (
                ELT(FLOOR(RAND()*10 + 1), 'Jan', 'Pawel', 'Bobo', 'Marcin', 'Kamil', 'Tulipan', 'Krystyna', 'Marcjanna', 'Żaklin', 'Jessica'),
                (NOW() - INTERVAL FLOOR(216 + RAND() * 1000) MONTH),
                ELT(FLOOR(RAND()*2 + 1), 'M', 'F'),
                ELT(FLOOR(RAND()*10 + 1), 'Kaczor', 'Tusk', 'Braun', 'Thun', 'Petru', 'Kolonko', 'Prokop', 'Wojtyła', 'Kabanos', 'Marchewka'));
				SET i = i + 1;
			END WHILE;
		WHEN name = 'sport' THEN
			WHILE i < num DO
				INSERT INTO sport (nazwa, typ, lokacja) VALUES (
                ELT(FLOOR(RAND()*5 + 1),'bieganie', 'pływanie', 'MMA', 'taniec', 'wspinanie'),
                ELT(FLOOR(RAND()*3 + 1), 'indywidualny', 'drużynowy', 'mieszany'),
                ELT(FLOOR(RAND()*3 + 1), 'na zewnątrz', 'wewnątrz', 'klub'));
                SET i = i + 1;
			END WHILE;
		WHEN name = 'nauka' THEN
			WHILE i < num DO
				INSERT INTO nauka (nazwa, lokacja) VALUES (
                ELT(FLOOR(RAND()*3 + 1), 'matematyka', 'filozofia', 'historia'),
                ELT(FLOOR(RAND()*3 + 1), 'szkoła', 'dom', 'kościół'));
                SET i = i + 1;
			END WHILE;
		WHEN name = 'inne' THEN
			WHILE i < num DO
				INSERT INTO inne (nazwa, lokacja, towarzysze) VALUES (
                ELT(FLOOR(RAND()*3 + 1), 'planszówki', 'jam session', 'slam poetycki'),
                ELT(FLOOR(RAND()*3 + 1), 'dom', 'klub', 'piwnica'),
                (FLOOR(RAND() * 10) % 2));
                SET i = i + 1;
			END WHILE;
		WHEN name = 'hobby' THEN
			WHILE i/3 < num DO
				INSERT INTO hobby (osoba, id, typ) VALUES (
                (FLOOR(RAND() * (SELECT MAX(id) FROM osoba) + 1)),
				(FLOOR(RAND() * (SELECT MAX(id) FROM sport) + 1)), 'sport');
                
				INSERT INTO hobby (osoba, id, typ) VALUES (
                (FLOOR(RAND() * (SELECT MAX(id) FROM osoba) + 1)),
				(FLOOR(RAND() * (SELECT MAX(id) FROM nauka) + 1)),
                'nauka');
                
				INSERT INTO hobby (osoba, id, typ) VALUES (
                (FLOOR(RAND() * (SELECT MAX(id) FROM osoba) + 1)),
				(FLOOR(RAND() * 550 + 7000)),
                'inne');
                
                SET i = i + 1;
			END WHILE;
	END CASE;
END //

DELIMITER ;

	CALL RandomRecords('osoba', 1000); #...

#8
  # Nie da rady tabeli w FROM sparametryzować, trzeba jak poniżej, ale wtedy typ nie wchodzi jako parametr w EXECUTE.
DELIMITER //
  CREATE DEFINER=`jkt44`@`localhost` PROCEDURE `ShowHobbys`(IN typ varchar(20), IN id INT)
BEGIN
	SET @sql = CONCAT('SELECT nazwa FROM ', typ, ' ', 'AS n INNER JOIN hobby AS h ON h.id = n.id WHERE  h.osoba = ?');
  SET @id = id;
	PREPARE stmt FROM @sql;
	EXECUTE stmt USING @id;
	DEALLOCATE PREPARE stmt;
END //

DELIMITER ;
  #example call (osoba 125)
  CALL ShowHobbys('sport', 125)
#9
	# Możnaby jeszcze połączyć te tabele, ale ze względu na problem z poprzedniego zadania to trochę trudne i nie chce mi się, a polecenie nie stwierdza, że powinno być w jednej.
DELIMITER //
  CREATE DEFINER=`jkt44`@`localhost` PROCEDURE `ShowUserHobbys`( IN id INT)
BEGIN
  SET @id = id;

  SET @typ = 'sport';
  SET @sql = CONCAT('SELECT nazwa FROM ', @typ, ' ', 'AS n INNER JOIN hobby AS h ON h.id = n.id WHERE  h.osoba = ?');
	PREPARE stmt FROM @sql;
	EXECUTE stmt USING @id;
	DEALLOCATE PREPARE stmt;

  SET @typ = 'nauka';
  SET @sql = CONCAT('SELECT nazwa FROM ', @typ, ' ', 'AS n INNER JOIN hobby AS h ON h.id = n.id WHERE  h.osoba = ?');
	PREPARE stmt FROM @sql;
	EXECUTE stmt USING @id;
	DEALLOCATE PREPARE stmt;

  SET @typ = 'inne';
  SET @sql = CONCAT('SELECT nazwa FROM ', @typ, ' ', 'AS n INNER JOIN hobby AS h ON h.id = n.id WHERE  h.osoba = ?');
	PREPARE stmt FROM @sql;
	EXECUTE stmt USING @id;
	DEALLOCATE PREPARE stmt;
END //
#10
	#j.w.
  DELIMITER //
  CREATE DEFINER=`jkt44`@`localhost` PROCEDURE `ShowUserHobbysAnimals`( IN id INT)
BEGIN
  SET @id = id;

  SET @typ = 'sport';
  SET @sql = CONCAT('SELECT nazwa FROM ', @typ, ' ', 'AS n INNER JOIN hobby AS h ON h.id = n.id WHERE  h.osoba = ?');
	PREPARE stmt FROM @sql;
	EXECUTE stmt USING @id;
	DEALLOCATE PREPARE stmt;

  SET @typ = 'nauka';
  SET @sql = CONCAT('SELECT nazwa FROM ', @typ, ' ', 'AS n INNER JOIN hobby AS h ON h.id = n.id WHERE  h.osoba = ?');
	PREPARE stmt FROM @sql;
	EXECUTE stmt USING @id;
	DEALLOCATE PREPARE stmt;

  SET @typ = 'inne';
  SET @sql = CONCAT('SELECT nazwa FROM ', @typ, ' ', 'AS n INNER JOIN hobby AS h ON h.id = n.id WHERE  h.osoba = ?');
	PREPARE stmt FROM @sql;
	EXECUTE stmt USING @id;
	DEALLOCATE PREPARE stmt;

  SET @typ = 'zwierzak';
  SET @sql = CONCAT('SELECT species FROM zwierzak AS n INNER JOIN hobby AS h ON h.osoba = n.OwnerID WHERE  h.osoba = ?');
	PREPARE stmt FROM @sql;
	EXECUTE stmt USING @id;
	DEALLOCATE PREPARE stmt;
END //
DELIMITER ;

#11
	#TODO
  DELIMITER //

	CREATE TRIGGER CheckID
	BEFORE INSERT ON hobby
	FOR EACH ROW
	BEGIN
	IF NEW.id = (nauka.id OR sport.id OR inne.id)  THEN
	SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Hobby with this id already exists.'; END IF; END //

	DELIMITER ;

#12
	DELIMITER //

	CREATE TRIGGER OnSportDelete
	AFTER DELETE ON sport
	FOR EACH ROW
	BEGIN
		DELETE FROM hobby WHERE OLD.id = hobby.id;
	END //

	DELIMITER ;

#13
	DELIMITER //

	CREATE TRIGGER OnNaukaDelete
	AFTER DELETE ON nauka
	FOR EACH ROW
	BEGIN
		DELETE FROM hobby WHERE OLD.id = hobby.id;
	END //

	CREATE TRIGGER OnNaukaUpdate
	AFTER UPDATE ON nauka
	FOR EACH ROW
	BEGIN
		UPDATE hobby SET id = NEW.id WHERE id = OLD.id AND typ = "nauka";
	END //

	DELIMITER ;

#14
	DELIMITER //

	CREATE TRIGGER OnOsobaDelete
	AFTER DELETE ON osoba
	FOR EACH ROW
	BEGIN
		DELETE FROM hobby WHERE OLD.id = hobby.osoba;
		UPDATE zwierzak SET ownerID = (FLOOR(RAND() * (SELECT MAX(id) FROM osoba) + 1)) WHERE ownerID = OLD.id;
	END //

	DELIMITER ;

#15 Jeżeli nie mogą, to dlatego, że na jedej tabeli i jednej akcji może być tylko jeden trigger.

#16
  # HAVING COUNT(0) > 2 niewymagane, ale dodałem, żeby ładnie wyglądało.
	CREATE 
		ALGORITHM = UNDEFINED 
		DEFINER = `jkt44`@`localhost` 
		SQL SECURITY DEFINER
	VIEW `hobbyCount` AS
		SELECT 
			`s`.`nazwa` AS `nazwa`,
			`h`.`id` AS `id`,
			`h`.`typ` AS `typ`,
			COUNT(0) AS `ilosc_osób`
		FROM
			(`hobby` `h`
			JOIN `sport` `s` ON (`s`.`id` = `h`.`id`
				AND `h`.`typ` = 'sport'))
		GROUP BY `h`.`id`
		HAVING COUNT(0) > 2 
		UNION SELECT 
			`s`.`nazwa` AS `nazwa`,
			`h`.`id` AS `id`,
			`h`.`typ` AS `typ`,
			COUNT(0) AS `ilosc_osób`
		FROM
			(`hobby` `h`
			JOIN `nauka` `s` ON (`s`.`id` = `h`.`id`
				AND `h`.`typ` = 'nauka'))
		GROUP BY `h`.`id`
		HAVING COUNT(0) > 2 
		UNION SELECT 
			`s`.`nazwa` AS `nazwa`,
			`h`.`id` AS `id`,
			`h`.`typ` AS `typ`,
			COUNT(0) AS `ilosc_osób`
		FROM
			(`hobby` `h`
			JOIN `inne` `s` ON (`s`.`id` = `h`.`id`
				AND `h`.`typ` = 'inne'))
		GROUP BY `h`.`id`
		HAVING COUNT(0) > 2
		ORDER BY `id`
#17
	# Wyświetla wybrane dane. Nie widzę sposobu, żeby jakoś ładnie to wyświetlić, bo osoba 0..* hobby/zwierzak
CREATE VIEW UserHobby AS
	SELECT o.id AS osobaID, o.imię, o.dataUrodzenia h.id AS hobbyID, h.typ, z.name FROM osoba AS o
	LEFT JOIN hobby AS h ON o.id = h.osoba
	LEFT JOIN zwierzak AS z ON o.id = z.ownerID;

#18
	
	PREPARE stmt FROM 'SELECT imię, TIMESTAMPDIFF(YEAR, dataUrodzenia, CURDATE()) as age  FROM UserHobby GROUP BY osobaID ORDER BY COUNT(*) DESC LIMIT 1;'
	EXECUTE stmt 
	DEALLOCATE PREPARE stmt;
