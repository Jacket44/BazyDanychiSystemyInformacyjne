# Lista 1 Bazy Danych i systemy informacyjne
# Mateusz Trzeciak 244919, 2019


#1
    SHOW TABLES;

#2
    SELECT owner, name FROM pet;

#3
    SELECT birth FROM pet WHERE species='dog';

#4
    SELECT name, owner FROM pet WHERE species='dog' AND MONTH(birth) < 6;

#5
    SELECT DISTINCT species FROM pet WHERE sex='m';

#6  (Zał. urodziny == prezent)
    SELECT pet.name, event.`date` FROM pet INNER JOIN event ON pet.name = event.name WHERE type='birthday';

#7
    SELECT DISTINCT owner FROM pet WHERE name LIKE '%ffy';

#8
    SELECT p.owner, p.name FROM pet AS p INNER JOIN event ON p.name = event.name WHERE death IS NULL;

#9 
    SELECT owner FROM pet GROUP BY owner HAVING COUNT(*) > 1; 

#10 
    SELECT * FROM pet AS p INNER JOIN event AS e ON p.name = e.name WHERE species='dog' AND type<>'birthday' ORDER BY p.name DESC;

#11 
    SELECT * FROM pet WHERE birth BETWEEN '1992-01-01' AND '1994-06-01';

#12 
    SELECT * FROM pet WHERE death IS NULL ORDER BY birth ASC LIMIT 2;

#13 
    SELECT * FROM pet WHERE birth=(SELECT MAX(birth) FROM pet);

#14 
    SELECT DISTINCT p.owner
    FROM pet AS p 
    INNER JOIN event AS e ON p.name = e.name
    WHERE e.date > (SELECT date FROM event WHERE name='Slim');

#15  (Tutaj nie wiadomo co z właścicielami, którzy mają kilka zwierząt. Domyślnie, sortuje po najmłodszym zwierzaku.)
    SELECT DISTINCT owner FROM pet AS p INNER JOIN event AS e ON p.name = e.name WHERE type<>'birthday' ORDER BY birth ASC;

#16 (Duplikaty nie usunięte)
    SELECT DISTINCT p1.owner, p2.owner
    FROM pet AS p1
    JOIN pet AS p2 
    WHERE p1.species=p2.species AND
          p1.owner<>p2.owner;
#17 
    ALTER TABLE event ADD COLUMN preformer varchar(30) AFTER date;

#18 
    UPDATE event AS E INNER JOIN pet AS P ON E.name = P.name SET E.preformer = P.owner WHERE type<>"vet" OR type<>"litter";
      UPDATE event SET preformer="A. Małysz" WHERE type="vet";
      UPDATE event SET preformer="M. Pudzianowski" WHERE type="litter";

#19 
    UPDATE pet SET owner="Diane" WHERE species="cat";

#20 
    SELECT species AS name, COUNT(*) species FROM pet GROUP BY species ORDER BY species DESC;

#21 
    DELETE pet, event FROM pet INNER JOIN event ON pet.name = event.name WHERE death IS NOT NULL;

#22 
    ALTER TABLE pet DROP COLUMN death;

#23 
    INSERT INTO pet
    VALUES
      ('Puzon', 'Waldemar', 'pies', 'm', '2013-10-01'),
      ('Skarpetka', 'Krystyna', 'pies', 'f', '2010-12-07'),
      ('Tuptuś', 'Krystyna', 'chomik', 'f', '2011-03-25'),
      ('Trisan', 'Waldemar', 'koza', 'm', '2012-02-05'),
      ('Hamlet', 'Waldemar', 'koza', 'm', '2014-02-13'),
      ('Dulcynea', 'Waldemar', 'koza', 'f', '2014-01-30'),
      ('Dzwoneczek', 'Dobromir', 'owca', 'f', '2015-08-18');  
    
    INSERT INTO event
    VALUES
      ('Puzon', '2019-10-01', 'A. Małysz', 'vet', 'Oderwane ucho'),
      ('Skarpetka', '2019-10-02', 'A. Małysz', 'vet', 'Nóż w łapie'),
      ('Tuptuś', '2019-10-03', 'M. Pudzianowski', 'litter', '10 nowych chomików'),
      ('Tristan', '2019-10-04', 'M. Pudzianowski', 'birthday', 'Dostał jabuszko'),
      ('Hamlet', '2019-10-05', 'A. Małysz', 'birthday', 'Dostał marchewkę'),
      ('Dulcynea', '2019-10-06', 'A. Małysz', 'birthday', 'Brak prezentu'),
      ('Dzwoneczek', '2019-10-07', 'A. Małysz', 'birthday', 'Wielki tort z siana');
