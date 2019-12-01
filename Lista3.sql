--zad. 1
    -- Default -> B-Tree inxed in MarieDB
    CREATE INDEX osoba_imidx ON osoba (imię);
    CREATE INDEX osoba_dtidx ON osoba (dataUrodzenia);
    CREATE INDEX sport_idx   ON sport (id, nazwa);
    CREATE INDEX inne_idx    ON inne (nazwa, id);
    CREATE INDEX hobby_idx   ON hobby (osoba, id, typ);
    /* Generalnie jak się robi klucz podstawowy albo tam unikalny
       to z automatu staje się PRIMARY indeksem. Tych wyżej nie było, ale 
       odnoszące się do id działały podobnie. */

--zad. 2
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

--zad. 3
        -- zał. pensja -> int, każdy ma jedną pracę.
        CREATE TABLE zawody(id int NOT NULL AUTO_INCREMENT, nazwa varchar(20) NOT NULL, pensja_min int, pensja_max int, PRIMARY KEY (id));

        CREATE TABLE praca(id_zawodu int NOT NULL, id_osoby int NOT NULL, zarobki int NOT NULL, PRIMARY KEY (id_zawodu, id_osoby));

        --teraz zrobić pętlę (wykład) i cośtam z kursorów