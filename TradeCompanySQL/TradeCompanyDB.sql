/*======================================================================================*/
Задание SQL:
СУБД:  MySQL или Microsoft SQL.

Придумать структуру для базы данных из двух таблиц:
Персонал и отделы компании.

У каждого отдела должен быть руководитель (который также числится сотрудником 
компании и должен быть записан а соответствующей таблице по сотрудникам).

Задание:
1. Написать SQL запрос для создания этой базы данных.

2. Забить таблицы тестовыми данными. Огромным плюсом будет если часть информации 
(например, даты рождения) будешь генерировать запросом автоматически (случайным образом).

3. Написать запрос, который выведет 10 фамилий и инициалов (через точку) сотрудников, 
их полное количество лет (возраст в годах), название отдела и фамилия руководителя 
отдела, где работает сотрудник.

/*======================================================================================*/
/*Решение: */
/*======================================================================================*/
/*1) Подключ к СУБД MySQL:*/
mysql -u root -p --default-character-set=utf8

/*2) Создаем БД:*/
DROP DATABASE IF EXISTS TradeCompany;
CREATE DATABASE TradeCompany CHARACTER SET 'utf8' ;

/*3) Создаем пользователя и передаем ему БД:*/
GRANT ALL PRIVILEGES ON TradeCompany.* TO 'bigtrader'@'localhost' IDENTIFIED BY 'secretgoods';

/*4) Выходим из root режима:*/ 
exit

/*5) */
mysql -u bigtrader -p TradeCompany --default-character-set=utf8
/*password:*/ secretgoods

/* Создаем таблицы */
/*6) Вспомогательные таблицы:
 - rusManNames (мужские имена, соотв.отчества мужч. и женщ.);
 - rusWomanNames (женские имена);
 - rusSurnames (фамилии мужск. и женск. формы).
Эти таблицы заполняем на основе текстовых данных, полученных из интернета, с помощью скрипта php
Например см. файлы: parseSurnames.php (исх.текст - Surnames) parseWnames.php (исх.текст - Wnames).
Из этих таблиц будем выбирать данные для "придумывания" личных данных сотрудников.
*/
CREATE TABLE rusManNames
(
Id INT AUTO_INCREMENT PRIMARY KEY,
mname VARCHAR(30) NOT NULL UNIQUE,
mpatronymic VARCHAR(30) NOT NULL UNIQUE,
wpatronymic VARCHAR(30) NOT NULL UNIQUE
);
/*parseRusManNames.php*/
SELECT * FROM rusManNames;
/**/

CREATE TABLE rusWomanNames
(
Id INT AUTO_INCREMENT PRIMARY KEY,
wname VARCHAR(30) NOT NULL UNIQUE
);
/*parseWnames.php*/
SELECT * FROM rusWomanNames;
/**/

CREATE TABLE rusSurnames
(
Id INT AUTO_INCREMENT PRIMARY KEY,
msurname VARCHAR(30) NOT NULL UNIQUE,
wsurname VARCHAR(30) NOT NULL UNIQUE
);
/*parseSurnames.php*/
SELECT * FROM rusSurnames;

/*7)Таблица отделы компании*/
/*DROP TABLE departments;*/
CREATE TABLE departments
(
Id INT AUTO_INCREMENT PRIMARY KEY,
departmentName VARCHAR(60) NOT NULL UNIQUE,
chiefId INT UNIQUE REFERENCES personnels(Id)
) ENGINE = INNODB;

/*8)Таблица сотрудники*/
CREATE TABLE personnels
(
Id INT AUTO_INCREMENT PRIMARY KEY,
birthDate DATE NOT NULL,
gender CHAR(1) DEFAULT 'M',
surname VARCHAR(30),
name VARCHAR(30),
patronymic VARCHAR(30),
departmentId INT REFERENCES departments(Id)
) ENGINE = INNODB;

/*9) Добавляем названия отделов */
/* первый отдел, вариант синтаксиса MySQL*/
INSERT INTO departments
SET departmentName='Дирекция';
/* остальные отделы, вариант синтаксиса SQL*/
INSERT INTO departments
(departmentName)
VALUES 
('Активные продажи. Поиск новых Клиентов'), 
('Торговля оптом, "под заказ" и в розницу со склада'), 
('Отдел торговых представителей'),
('Розничный магазин. Торговый зал'),
('Отдел маркетинга и рекламы'),
('Закупка'),
('Транспорт/логистика'),
('Склад'),
('Бухгалтерия'),
('Отдел персонала'),
('IT-отдел'),
('Офисное хозяйство/секретариат');

/* 10) Нанимаем на работу 'numberPeople' сотрудников: */
DROP PROCEDURE IF EXISTS hireemployees;
delimiter //

CREATE procedure hireemployees(IN numberPeople INT)
wholeblock:BEGIN
  declare x INT default 0;
  SET x = 1;

  WHILE x <= numberPeople DO
/*----------------------------------------------------------*/  
SELECT @gender := ELT(0.5 + RAND() * 2, 'M', 'W');
INSERT INTO personnels
(birthDate, gender, surname, name, patronymic, departmentId)
VALUES
(
NOW() - INTERVAL FLOOR(RAND() * 20 * 365 + 21 * 365) DAY,
@gender,
(case 
when @gender = 'M' then  (SELECT msurname FROM rusSurnames ORDER BY RAND() LIMIT 1 )
when @gender = 'W' then (SELECT wsurname FROM rusSurnames ORDER BY RAND() LIMIT 1 )
end),
(case 
when @gender = 'M' then  (SELECT mname FROM rusManNames ORDER BY RAND() LIMIT 1 )
when @gender = 'W' then  (SELECT wname FROM rusWomanNames ORDER BY RAND() LIMIT 1 )
end),
(case 
when @gender = 'M' then ( SELECT mpatronymic FROM rusManNames ORDER BY RAND() LIMIT 1 )
when @gender = 'W' then ( SELECT wpatronymic FROM rusManNames ORDER BY RAND() LIMIT 1 ) 
end),
( SELECT departments.Id FROM departments ORDER BY RAND() LIMIT 1 )
);
/*----------------------------------------------------------*/  
    SET x = x + 1;
  END WHILE;
END//
delimiter ;

CALL hireemployees(1500);

SELECT * FROM personnels;

/*11)Назначаем начальников отделов из числа сотрудников этих же отделов*/

UPDATE departments
INNER JOIN personnels ON departments.Id = personnels.departmentId
SET departments.chiefId = (SELECT personnels.Id FROM personnels
WHERE personnels.departmentId = departments.Id ORDER BY RAND() LIMIT 1);

SELECT * FROM departments;

/*12)Выводим 10 фамилий и инициалов (через точку) сотрудников, 
их полное количество лет (возраст в годах), название отдела и фамилия руководителя 
отдела, где работает сотрудник. + добавим в результаты id сотрудника */

SELECT personnels.Id, personnels.surname, 
CONCAT( SUBSTRING(personnels.name, 1, 1), '.') AS name, 
CONCAT( SUBSTRING(personnels.patronymic, 1, 1), '.')  AS patro,
( YEAR(CURRENT_DATE) - YEAR(birthDate) - (DATE_FORMAT(CURRENT_DATE, '%m%d') < DATE_FORMAT(birthDate, '%m%d')) ) AS age,
departments.departmentName AS department,
(
	SELECT personnels.surname
	FROM personnels
	WHERE personnels.Id = departments.chiefId
) AS Chief
FROM personnels
INNER JOIN departments 
ON personnels.departmentId = departments.Id
LIMIT 150, 10;

/*13) То же самое, что 12), но в списке сотрудников нет руководителей*/
SELECT personnels.Id, personnels.surname, 
CONCAT( SUBSTRING(personnels.name, 1, 1), '.') AS name, 
CONCAT( SUBSTRING(personnels.patronymic, 1, 1), '.')  AS patro,
( YEAR(CURRENT_DATE) - YEAR(birthDate) - (DATE_FORMAT(CURRENT_DATE, '%m%d') < DATE_FORMAT(birthDate, '%m%d')) ) AS age,
departments.departmentName AS department,
(
	SELECT personnels.surname
	FROM personnels
	WHERE personnels.Id = departments.chiefId
) AS Chief
FROM personnels
INNER JOIN departments 
ON personnels.departmentId = departments.Id
WHERE personnels.Id <> departments.chiefId
LIMIT 10 OFFSET 169;
/*14) Создадим dump нашей базы данных*/
exit
mysqldump -u bigtrader -p --opt TradeCompany > /home/bbrs/Desktop/Trade/TradeCompany_save.sql
/*
USE TradeCompany;
source TradeCompany_save.sql;
*/
/*======================================================================================*/
/* Voila ! 
La tâche est accomplie ! */
/*======================================================================================*/

/*branch:  feature_15*/
/*15) Среднее количество сотрудников в одном отделе*/
SELECT ( SELECT COUNT(*) FROM personnels ) / ( SELECT COUNT(*) FROM departments );

/*16) Показать отделы, в которых количество сотрудников больше среднего, отсортировать по убыванию*/
SELECT departments.Id, departments.departmentName, COUNT(*) AS employeesNum
FROM personnels INNER JOIN departments ON departments.Id = personnels.departmentId  
GROUP BY departmentId
HAVING COUNT(*) >  ( SELECT COUNT(*) FROM personnels ) / ( SELECT COUNT(*) FROM departments ) 
ORDER BY employeesNum DESC;

/*17) Показать Id, фамилию, возраст сотрудников, возраст которых в диапазоне от 22 до 33,
 указать порядковый номер этих сотрудников, начиная с 1 */
SELECT @n := 0; 
SELECT
@n := @n + 1 AS num,
personnels.Id, personnels.surname, 
( YEAR(CURRENT_DATE) - YEAR(birthDate) - (DATE_FORMAT(CURRENT_DATE, '%m%d') < DATE_FORMAT(birthDate, '%m%d')) ) AS age
FROM personnels
WHERE 
( ( YEAR(CURRENT_DATE) - YEAR(birthDate) - (DATE_FORMAT(CURRENT_DATE, '%m%d') < DATE_FORMAT(birthDate, '%m%d')) ) > 22 )
AND 
( ( YEAR(CURRENT_DATE) - YEAR(birthDate) - (DATE_FORMAT(CURRENT_DATE, '%m%d') < DATE_FORMAT(birthDate, '%m%d')) ) < 33 );

/*18) Показать Id, фамилию, возраст сотрудников, возраст которых либо 22 либо 33 года,
 указать порядковый номер этих сотрудников, начиная с 1. Вывести 10 строк, пропустив первые 15.  */
SELECT @n := 0; 
SELECT
@n := @n + 1 AS num,
personnels.Id, personnels.surname, 
( YEAR(CURRENT_DATE) - YEAR(birthDate) - (DATE_FORMAT(CURRENT_DATE, '%m%d') < DATE_FORMAT(birthDate, '%m%d')) ) AS age
FROM personnels
WHERE ( YEAR(CURRENT_DATE) - YEAR(birthDate) - (DATE_FORMAT(CURRENT_DATE, '%m%d') < DATE_FORMAT(birthDate, '%m%d')) ) IN(22,33)
LIMIT 10 OFFSET 15;

/*19) Показать фамилии и количество тех однофамильцев (независимо от пола) в компании, число которых больше 5 */
/*SET sql_mode = 'ONLY_FULL_GROUP_BY';*/
SET sql_mode = '';
SELECT personnels.surname, 
SUBSTRING( personnels.surname, 1, CHAR_LENGTH(personnels.surname) - 2 ) AS family, 
COUNT(*) AS numb
FROM personnels
GROUP BY family
HAVING COUNT(*) > 5;

/*20) Показать фамилии и количество тех однофамильцев (независимо от пола) в компании, число которых 
больше 0,7 от рекордного числа однофамильцев*/
SELECT personnels.surname, 
SUBSTRING( personnels.surname, 1, CHAR_LENGTH(personnels.surname) - 2 ) AS family, 
COUNT(*) AS numb,
(
	SELECT  
	COUNT(*) AS numb
	FROM personnels
	GROUP BY SUBSTRING( personnels.surname, 1, CHAR_LENGTH(personnels.surname) - 2 )  
	ORDER BY numb DESC LIMIT 1
) AS maxnumb
FROM personnels
GROUP BY family
HAVING COUNT(*) > maxnumb * 0.7;

/*21) Показать число однофамильцев внутри каждого отдела. */
SELECT 
personnels.departmentId,
personnels.surname, 
SUBSTRING( personnels.surname, 1, CHAR_LENGTH(personnels.surname) - 2 ) AS family, 
COUNT(*) AS numb
FROM personnels
GROUP BY family, departmentId
HAVING COUNT(*) > 1;

/*22) Показать число однофамильцев для каждого отдела, а так же Фамилию.И.О. каждого*/
SELECT 
personnels.departmentId,
GROUP_CONCAT( CONCAT(personnels.surname, ' ',SUBSTRING(personnels.name, 1, 1), '.',SUBSTRING(personnels.patronymic, 1, 1), '.') ) as fio, 
SUBSTRING( personnels.surname, 1, CHAR_LENGTH(personnels.surname) - 2 ) AS family, 
COUNT(*) AS numb
FROM personnels
GROUP BY family, departmentId
HAVING COUNT(*) > 1
ORDER BY personnels.departmentId;

/*23) Показать Id отдела, название отдела, фамилию нач. отдела,
число однофамильцев для каждого отдела, а так же Фамилию.И.О. каждого однофамильца*/
/*  to leave <pager less -SFX> press <q> */
pager less -SFX
SELECT 
personnels.departmentId as depId, 
departments.departmentName as dep,
(
	SELECT personnels.surname
	FROM personnels
	WHERE personnels.Id = departments.chiefId
) as Chief,
GROUP_CONCAT( CONCAT(personnels.surname, ' ',SUBSTRING(personnels.name, 1, 1), '.',SUBSTRING(personnels.patronymic, 1, 1), '.') ) as fio, 
SUBSTRING( personnels.surname, 1, CHAR_LENGTH(personnels.surname) - 2 ) AS family, 
COUNT(*) AS numb
FROM personnels 
INNER JOIN departments ON departments.Id = personnels.departmentId
GROUP BY family, departmentId
HAVING COUNT(*) > 1
ORDER BY personnels.departmentId;

/*24) Id отдела, название отдела, фамилия начальника отдела*/
SELECT departments.Id, departments.departmentName, personnels.surname
FROM personnels INNER JOIN departments ON departments.chiefId = personnels.Id;

/*============================================================================================*/
