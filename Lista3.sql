--zad. 1 ✓ 
    -- Default -> B-Tree inxed in MarieDB
    CREATE INDEX osoba_imidx ON osoba (imię);
    CREATE INDEX osoba_dtidx ON osoba (dataUrodzenia);
    CREATE INDEX sport_idx   ON sport (id, nazwa);
    CREATE INDEX inne_idx    ON inne (nazwa, id);
    CREATE INDEX hobby_idx   ON hobby (osoba, id, typ);
    /* Generalnie jak się robi klucz podstawowy albo tam unikalny
       to z automatu staje się PRIMARY indeksem. Tych wyżej nie było, ale 
       odnoszące się do id działały podobnie. */

--zad. 2 ✓ 
    --Tutaj pomoże EXPLAIN 

    SELECT sex FROM osoba WHERE imię LIKE 'M%';
    --Nie użył indexu
    SELECT name FROM sport ORDER BY name;
    --Do posegregowanie użyty index
    SELECT s1.id, s2.id FROM sport AS s1 JOIN sport as s2
    WHERE s1.typ = 'indywidualny' AND s2.typ = 'indywidualny'
    AND s1.lokacja = s2.lokacja AND s1.id <> s2.id;
    --Nie użyty index.
    SELECT * FROM osoba WHERE dataUrodzenia < '2000-01-01';
    --Znowu nie użyty.

    SELECT * FROM hobby GROUP BY id ORDER BY COUNT(*) DESC LIMIT 1;
    --Użyty index PRIMARY

    SELECT imię FROM osoba WHERE id IN
    (SELECT ownerID FROM zwierzak WHERE species = 'pies')
    ORDER BY dataUrodzenia DESC LIMIT 1;
    --Tutaj tak samo

    /* Coś tu mi nie pasuje, bo pewnie te indexy powinny się tu przyać,
       Trzeba jeszcze ogarnąć to. */

--zad. 3 ✓ 
        -- zał. pensja -> int, każdy ma jedną pracę.
        CREATE TABLE zawody(id int NOT NULL AUTO_INCREMENT, nazwa varchar(20) NOT NULL, pensja_min int, pensja_max int, PRIMARY KEY (id));

        CREATE TABLE praca(id_zawodu int NOT NULL, id_osoby int NOT NULL, zarobki int NOT NULL, PRIMARY KEY (id_zawodu, id_osoby));

        --teraz zrobić pętlę (wykład) i cośtam z kursorów

        DELIMITER //

        CREATE PROCEDURE RandomJobs()
        BEGIN
            DECLARE x INT;
            SET x = 1;

            main_loop: LOOP
                SET x = x +1;

                IF x > 11 THEN 
                        LEAVE main_loop;
                END IF;

                INSERT INTO zawody(nazwa, pensja_min, pensja_max)
                VALUES (ELT(FLOOR(RAND()*7 + 1), 'piekarz', 'lekarz', 'tynkarz', 'stolarz', 'kolarz', 'sklepikarz', 'malarz'),
                        FLOOR(RAND() * 2000 + 1774),
                        FLOOR(RAND() * 5000 + 3774));
            END LOOP;
        END //

        DELIMITER ;

        DELIMITER //

        CREATE PROCEDURE EmployPeople()
        BEGIN 
            DECLARE I int;
            DECLARE id_zawodu int;
            DECLARE finished INTEGER DEFAULT 0;

            DECLARE curID 
                CURSOR FOR
                    SELECT id FROM osoba;

            DECLARE CONTINUE HANDLER 
                FOR NOT FOUND SET finished = 1;

            OPEN curID;
                populate_loop: LOOP
                FETCH curID INTO I;
                IF finished THEN 
                    LEAVE populate_loop;
                END IF;
                SET id_zawodu = (FLOOR(RAND() * (SELECT COUNT(*) FROM zawody) + 1));
                INSERT INTO praca (id_zawodu, id_osoby, zarobki )
                VALUES (id_zawodu,
                        I,
                        (FLOOR(RAND() * ((SELECT pensja_max FROM zawody WHERE id = id_zawodu) - (SELECT pensja_min FROM zawody WHERE id = id_zawodu))
                         + (SELECT pensja_min FROM zawody WHERE id = id_zawodu))) );
				END LOOP;
            CLOSE curID;
        END 

        DELIMITER ;

        -- działa elegancko, ale linia 93 paskudna

--zad 4. ✓

    DELIMITER //

   CREATE  AggFun(IN kol ENUM('id', 'imie', 'dataUrodzenia', 'nazwisko', 'plec'), IN agg VARCHAR(20), OUT X VARCHAR(100))
    BEGIN
        SET @temp = NULL;
        SET @arg = kol;
        CASE LOWER(agg)
            WHEN 'avg' THEN
                SET @query = CONCAT('SELECT  DATE_FORMAT(FROM_UNIXTIME(AVG(', kol,  ')), "%Y") FROM osoba INTO @temp');
                PREPARE stmt FROM @query;
                EXECUTE stmt;
                DEALLOCATE PREPARE stmt;
            WHEN 'count' THEN
                SET @query = CONCAT('SELECT COUNT(', kol, ') FROM osoba INTO @temp');
                PREPARE stmt FROM @query;
                EXECUTE stmt;
                DEALLOCATE PREPARE stmt;
            WHEN 'max' THEN
                SET @query = CONCAT('SELECT MAX(', kol, ') FROM osoba INTO @temp');
                PREPARE stmt FROM @query;
                EXECUTE stmt;
                DEALLOCATE PREPARE stmt;
            WHEN 'min' THEN
                SET @query = CONCAT('SELECT MIN(', kol, ') FROM osoba INTO @temp');
                PREPARE stmt FROM @query;
                EXECUTE stmt;
                DEALLOCATE PREPARE stmt;
            WHEN 'sum' THEN
                SET @query = CONCAT('SELECT SUM(', kol, ') FROM osoba INTO @temp');
                PREPARE stmt FROM @query;
                EXECUTE stmt;
                DEALLOCATE PREPARE stmt;
            WHEN 'group_concat' THEN
                    SET @query = CONCAT('SELECT GROUP_CONCAT(', kol, ') FROM osoba INTO @temp');
                    PREPARE stmt FROM @query;
                    EXECUTE stmt;
                    DEALLOCATE PREPARE stmt;
                WHEN 'std' THEN
                    SET @query = CONCAT('SELECT  DATE_FORMAT(FROM_UNIXTIME(STD(', kol,  ')), "%Y") FROM osoba INTO @temp');
                    PREPARE stmt FROM @query;
                    EXECUTE stmt;
                    DEALLOCATE PREPARE stmt;
                WHEN 'var_pop' THEN
                    SET @query = CONCAT('SELECT VAR_POP(', kol, ') FROM osoba AS datetime INTO @temp');
                    PREPARE stmt FROM @query;
                    EXECUTE stmt;
                    DEALLOCATE PREPARE stmt;
            ELSE
                SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'niepoprawna funkcja agregująca';
            END CASE;
            SET X = @temp;
    END//

    DELIMITER ;

--zad 5. ✓ 

    CREATE TABLE hasła (osoba_id int NOT NULL, hasło varchar(255) NOT NULL);

    --błąd -> nie działa, jeżeli istnieje para użytkowników z tym samym imieniem i hasłem. 
    DELIMITER //

        CREATE  PROCEDURE GetUsrDate(IN user varchar(20), IN password varchar(20))
    BEGIN
        IF sha1(password) = (SELECT hasło FROM hasła INNER JOIN osoba ON osoba.id = hasła.osoba_id WHERE osoba.imię = user) THEN
        
            SELECT dataUrodzenia FROM osoba
            INNER JOIN hasła ON osoba.id = hasła.osoba_id
            WHERE osoba_id = id AND user = osoba.imię AND sha1(password) = hasła.hasło;
        
        ELSE 
            SELECT date((NOW() - INTERVAL FLOOR(216 + RAND() * 984) MONTH)) AS dataUrodzenia;
        END IF;
    END //

    DELIMITER ;

--zad. 6
    /* robi się */

--zad. 7

        WITH RECURSIVE binom (n, k) AS
        (
            SELECT 1
            UNION ALL
            SELECT n + 1
            FROM binom WHERE n < 3
        )

--zad. 8 ✓ 
    --W zadaniu procedura powinna otrzymać nazwę, ale to bez sensu ze względu, że nazwy nie są unikalne, więc używam id.
    DELIMITER //

        CREATE DEFINER=`jkt44`@`localhost` PROCEDURE `SalaryRaise`(IN jobid int)
        BEGIN
			DECLARE cur int(11);
            DECLARE finished INTEGER DEFAULT 0;
            DECLARE salaryOverflow INTEGER DEFAULT 0;
	
            DECLARE curID 
                CURSOR FOR
                    SELECT id FROM osoba;
                    
            DECLARE CONTINUE HANDLER 
                FOR NOT FOUND SET finished = 1;
                
			DROP VIEW IF EXISTS osobaPracaZarobki;
            
			CREATE VIEW osobaPracaZarobki AS
             SELECT o.id, o.imię, o.dataUrodzenia, o.plec, o.nazwisko, p.id_zawodu,
             p.id_osoby, p.zarobki, z.id AS zawódID, z.nazwa, z.pensja_min, pensja_max
				FROM zawody 	 AS z
                INNER JOIN praca AS p ON z.id = p.id_zawodu
                INNER JOIN osoba AS o ON o.id = p.id_osoby;
			
            OPEN curID;
			main_loop: LOOP
				IF finished THEN 
				LEAVE main_loop;
				END IF;
                
                FETCH curID INTO cur;
                
                IF (SELECT zarobki FROM osobaPracaZarobki WHERE id = cur AND zawódID = jobid) * 1.1 >
					(SELECT pensja_max FROM osobaPracaZarobki WHERE id = cur AND zawódID = jobid) THEN
                    SELECT 'dupa';
                    SET finished = 1;
                    SET salaryOverflow = 1;
				END IF;
			END LOOP;
            CLOSE curID;
            
            SET finished = 0;
            
            IF salaryOverflow = 0 THEN
            OPEN curID;
				second_loop: LOOP
				IF finished THEN 
				LEAVE second_loop;
				END IF;
                
                FETCH curID INTO cur;
                
                UPDATE praca
                SET zarobki = (zarobki * 1.1) WHERE id_osoby = cur AND id_zawodu = jobid;
				
			END LOOP;
            CLOSE curID;
			END IF;
    END//

    DELIMITER ;

--zad. 9 ✓ 
    DELIMITER //
    CREATE DEFINER=`jkt44`@`localhost` FUNCTION `laplace`(a FLOAT, b FLOAT, x FLOAT) RETURNS float
        DETERMINISTIC
    BEGIN
        DECLARE r FLOAT DEFAULT 0;
        SET r = (1/(2*b))*EXP(-(ABS(x-a)/b));
        RETURN r;
    END //
    DELIMITER ;

    DELIMITER //

    CREATE PROCEDURE AvgSalary(IN jobid int)
    BEGIN
        DECLARE delta FLOAT;
        SET @id = jobid;
        SET @r = NULL;
        SET @maks = 0;
        SET @min = 0;
        SET @count = 0;
        SET @query = CONCAT('SELECT pensja_min FROM zawody WHERE id = @id INTO @min');
        PREPARE stmt1 FROM @query;
        SET @query = CONCAT('SELECT pensja_max FROM zawody WHERE id = @id INTO @max');
        PREPARE stmt2 FROM @query;
        SET @query = CONCAT('SELECT COUNT(*) FROM praca WHERE id_zawodu = @id INTO @count');
        PREPARE stmt3 FROM @query;
        EXECUTE stmt1;
        EXECUTE stmt2;
        EXECUTE stmt3;
        SET delta = @maks - @min;
        SET @query = CONCAT('SELECT laplace(0, (SELECT zarobki FROM praca ORDER BY RAND() LIMIT 1), (', delta, '/0.05))+SUM(zarobki) FROM praca WHERE id_zawodu = ? INTO @r');
        PREPARE stmt FROM @query;
        EXECUTE stmt USING @id;
        SET @r = @r / @count;
        SELECT @r AS Wynik;
    END //

    DELIMITER ;
    

-- zad. 10 ✓ 
    /*
        robione w MarieDB | zsh | Linux Arch/Manjaro

        mysqldump -u jkt44 -p Hobby --result-file Hobby.sql
        mysql -u jkt44 -p HobbyB < Hobby.sql

        mysqldump wyświetla bazę jako plik, można przekierować potok gdziekolwiek, w drugą stronę trochę analogicznie.


-- TODO :  6, 7,