/*
    ВЫБОРКА ДАННЫХ
*/
-- однотабличная выборка
-- Вывести все группы, упорядочив их в обратном порядке по году и в прямом порядке по наименованию.
SELECT *
FROM
    groups
ORDER BY
    SUBSTR(name, 7) DESC,
    name
;

-- выборка с подзапросами
-- Вывести число предметов, по которым есть оценки у группы, заданной по наименованию.
SELECT 
    COUNT(*) AS "number-of-sub-s"
FROM
    subjects
WHERE id IN (
    SELECT 
        subject_id
    FROM 
        marks
    WHERE student_id IN (
        SELECT 
            id
        FROM
            people
        WHERE group_id IN (
            SELECT
                id
            FROM
                groups
            WHERE
                name = '3084/1_2005'
        )
    )
);

-- соединение таблиц (join):
-- 1. Вывести студентов и наименования предметов(которые они сдавали), включая предметы, которые
--    не читались студентам и студентов, которые не получили ни одной оценки.
-- people(type=s), marks, subjects

   SELECT people.first_name, people.last_name, people.group_id, subjects.name
     FROM people
LEFT JOIN marks
       ON people.id = marks.student_id
FULL JOIN subjects
       ON marks.subject_id = subjects.id
    --WHERE people.type = 'S'
;

-- 2. Вывести все группы и средний балл студентов каждой.
  SELECT groups.id, groups.name, AVG(marks.value)
    FROM marks
    JOIN people
      ON marks.student_id = people.id
    JOIN groups
      ON groups.id = people.group_id
GROUP BY groups.id, groups.name;

    
 /*
    ВСТАВКА ДАННЫХ
*/
-- однотабличная вставка
-- 1. Добавить нового студента.
INSERT INTO people
            (first_name, last_name, father_name, group_id, type)
     VALUES
            ('Алина', 'Муллагалиева', 'Шамильиевна', '1', 'S');
            
-- 2. Добавить оценку по некоторому предмету студенту из п.1.
INSERT INTO marks
            (student_id, subject_id, teacher_id, value)
     VALUES
            (
                (SELECT id FROM people
                WHERE first_name = 'Алина' AND last_name = 'Муллагалиева' AND father_name = 'Шамильиевна'),
                1,
                1,
                5
            );
    
    
-- многотабличная вставка в рамках транзакции
-- 1. Создать копию заданной группы (со студентами) с увеличением курса на 1
-- 2. То же что п.1. Если группа с полученным наименованием уже существует – транзакцию откатить.
    
    