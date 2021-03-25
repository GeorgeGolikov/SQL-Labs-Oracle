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
    WHERE people.type = 'S' OR subjects.id IS NOT NULL
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
set serveroutput on;

DECLARE
    groupName VARCHAR2(20) := '3084/1_2005';
    newGroupName VARCHAR2(20);-- := '4084/1_2005';
    groupId NUMBER;
    newGroupId NUMBER;
    TYPE student_data_type IS RECORD (
        first_name VARCHAR(40),
        last_name VARCHAR(40),
        father_name VARCHAR(40),
        group_id NUMBER,
        type CHAR(1)
    );
    --TYPE students_type IS TABLE OF student_data_type
    --INDEX BY BINARY_INTEGER;
    tmpStudent student_data_type;
    numOfStudents NUMBER;
BEGIN
-- название группы на курс старше
    newGroupName := CONCAT(TO_CHAR(TO_NUMBER(SUBSTR(groupName, 1, 1)) + 1), SUBSTR(groupName, 2));
    dbms_output.put_line(newGroupName);
    
-- создать группу с именем на 1 курс выше выбранной
    INSERT INTO groups
            (name)
     VALUES
            (newGroupName);
            
-- выбрать id старой группы
    SELECT id INTO groupId FROM groups WHERE name = groupName;
    dbms_output.put_line(groupId);
    
-- выбрать id новой группы
    SELECT id INTO newGroupId FROM groups WHERE name = newGroupName;
    dbms_output.put_line(newGroupId);
            
-- выбрать всех студентов заданной группы
    SELECT COUNT(first_name) INTO numOfStudents FROM people WHERE group_id = groupId;
    numOfStudents := numOfStudents - 1;
    FOR i IN 0..numOfStudents
    LOOP
        SELECT first_name, last_name, father_name, group_id, type
        INTO tmpStudent
        FROM people
        WHERE group_id = groupId
        ORDER BY id DESC
        OFFSET i ROWS FETCH FIRST 1 ROWS ONLY;
        
        INSERT INTO people
            (first_name, last_name, father_name, group_id, type)
        VALUES
            (tmpStudent.first_name, tmpStudent.last_name,
            tmpStudent.father_name, newGroupId, 'S');
    END LOOP;
END;
    
    
-- 2. То же что п.1. Если группа с полученным наименованием уже существует – транзакцию откатить
DECLARE
    groupName VARCHAR2(20) := '3084/1_2005';
    newGroupName VARCHAR2(20);-- := '4084/1_2005';
    groupFromTable NUMBER;
    groupId NUMBER;
    newGroupId NUMBER;
    TYPE student_data_type IS RECORD (
        first_name VARCHAR(40),
        last_name VARCHAR(40),
        father_name VARCHAR(40),
        group_id NUMBER,
        type CHAR(1)
    );
    --TYPE students_type IS TABLE OF student_data_type
    --INDEX BY BINARY_INTEGER;
    tmpStudent student_data_type;
    numOfStudents NUMBER;
BEGIN
-- название группы на курс старше
    newGroupName := CONCAT(TO_CHAR(TO_NUMBER(SUBSTR(groupName, 1, 1)) + 1), SUBSTR(groupName, 2));
    dbms_output.put_line(newGroupName);
    
-- если группа уже существует - rollback
    SELECT COUNT(name) INTO groupFromTable FROM groups WHERE name = newGroupName;
    
    IF (groupFromTable = 0) 
    THEN
    -- создать группу с именем на 1 курс выше выбранной
        INSERT INTO groups
            (name)
        VALUES
            (newGroupName);
            
    -- выбрать id старой группы
        SELECT id INTO groupId FROM groups WHERE name = groupName;
        dbms_output.put_line(groupId);
    
    -- выбрать id новой группы
        SELECT id INTO newGroupId FROM groups WHERE name = newGroupName;
        dbms_output.put_line(newGroupId);
            
    -- выбрать всех студентов заданной группы
        SELECT COUNT(first_name) INTO numOfStudents FROM people WHERE group_id = groupId;
        numOfStudents := numOfStudents - 1;
        FOR i IN 0..numOfStudents
        LOOP
            SELECT first_name, last_name, father_name, group_id, type
            INTO tmpStudent
            FROM people
            WHERE group_id = groupId
            ORDER BY id DESC
            OFFSET i ROWS FETCH FIRST 1 ROWS ONLY;
        
            INSERT INTO people
                (first_name, last_name, father_name, group_id, type)
            VALUES
                (tmpStudent.first_name, tmpStudent.last_name,
                tmpStudent.father_name, newGroupId, 'S');
        END LOOP;
        COMMIT;
    ELSE
        ROLLBACK;
    END IF;
END;

SELECT people.id, AVG(marks.value)
    FROM marks
    JOIN people
      ON marks.student_id = people.id
    GROUP BY people.id;


 /*
    УДАЛЕНИЕ ДАННЫХ
*/
-- удаление по фильтру и удаление из связанных таблиц:
-- 1. Удалить студентов, у которых средний балл ниже заданного.
DECLARE
    students_mark FLOAT := 4.6;
    numOfStudents NUMBER;
    tempStudentId NUMBER;
BEGIN    
    SELECT COUNT(people.id)
    INTO numOfStudents
    FROM marks
    JOIN people
      ON marks.student_id = people.id
    WHERE marks.value < students_mark;
    
    numOfStudents := numOfStudents - 1;
    FOR i IN 0..numOfStudents
    LOOP
        SELECT people.id
        INTO tempStudentId
        FROM marks
        JOIN people
          ON marks.student_id = people.id
        GROUP BY people.id
        HAVING AVG(marks.value) < students_mark
        ORDER BY people.id DESC
        OFFSET 0 ROWS FETCH FIRST 1 ROWS ONLY;
        
        DELETE FROM marks WHERE student_id = tempStudentId;
        DELETE FROM people WHERE id = tempStudentId;  
    END LOOP;
END;

-- 2. Удалить заданную группу и студентов, принадлежащих ей.
DECLARE
    groupToDelete VARCHAR2(20) := '4084/1_2005';
    numOfStudents NUMBER;
    tempStudentId NUMBER;
BEGIN    
    SELECT COUNT(people.id)
    INTO numOfStudents
    FROM people
    JOIN groups
      ON people.group_id = groups.id
    WHERE groups.name = groupToDelete;
    
    numOfStudents := numOfStudents - 1;
    FOR i IN 0..numOfStudents
    LOOP
        SELECT people.id
        INTO tempStudentId
        FROM people
        JOIN groups
          ON people.group_id = groups.id
        WHERE groups.name = groupToDelete
        ORDER BY people.id DESC
        OFFSET 0 ROWS FETCH FIRST 1 ROWS ONLY;
        
        DELETE FROM marks WHERE student_id = tempStudentId;
        DELETE FROM people WHERE id = tempStudentId;  
    END LOOP;
    
    DELETE FROM groups WHERE name = groupToDelete;
END;


-- вывести группу с минимальным средним баллом
SELECT groups.id, groups.name
    FROM marks
    JOIN people
      ON marks.student_id = people.id
    JOIN groups
      ON groups.id = people.group_id
GROUP BY groups.id, groups.name
HAVING AVG(marks.value) = (
    SELECT MIN(average_grade) FROM (
        SELECT AVG(marks.value) AS average_grade
        FROM marks
        JOIN people
          ON marks.student_id = people.id
        JOIN groups
          ON groups.id = people.group_id
        GROUP BY groups.id
    )
);

-- удаление в рамках транзакции:
-- 1. Удалить в рамках транзакции группу с самым маленьким средним баллом и студентов, принадлежащих ей.
DECLARE
    groupToDelete NUMBER;
    numOfStudents NUMBER;
    tempStudentId NUMBER;
BEGIN    
    SELECT groups.id
    INTO groupToDelete
    FROM marks
    JOIN people
      ON marks.student_id = people.id
    JOIN groups
      ON groups.id = people.group_id
    GROUP BY groups.id
    ORDER BY AVG(marks.value)
    OFFSET 0 ROWS FETCH FIRST 1 ROWS ONLY;

    SELECT COUNT(people.id)
    INTO numOfStudents
    FROM people
    JOIN groups
      ON people.group_id = groups.id
    WHERE groups.id = groupToDelete;
    
    numOfStudents := numOfStudents - 1;
    FOR i IN 0..numOfStudents
    LOOP
        SELECT people.id
        INTO tempStudentId
        FROM people
        JOIN groups
          ON people.group_id = groups.id
        WHERE groups.id = groupToDelete
        ORDER BY people.id DESC
        OFFSET 0 ROWS FETCH FIRST 1 ROWS ONLY;
        
        DELETE FROM marks WHERE student_id = tempStudentId;
        DELETE FROM people WHERE id = tempStudentId;  
    END LOOP;
    
    DELETE FROM groups WHERE id = groupToDelete;
END;

-- 2. то же, что и п.1, но, если в удаленной группе читались 3 предмета, которые больше нигде не читались – транзакцию откатить.
-- кол-во предметов, для которых группа - одна и та же и только одна, равно 3.
-- предмет - оценка - студент - группа


 /*
    МОДИФИКАЦИЯ ДАННЫХ
*/
-- модификация по фильтру:
-- 1. Подменить заданную группу на другую.
DECLARE
    groupToReplace NUMBER := 3;
    groupToSet NUMBER := 1;
    numOfStudents NUMBER;
    tempStudentId NUMBER;
BEGIN    
    SELECT COUNT(people.id)
    INTO numOfStudents
    FROM people
    JOIN groups
      ON people.group_id = groups.id
    WHERE groups.id = groupToReplace;
    
    numOfStudents := numOfStudents - 1;
    FOR i IN 0..numOfStudents
    LOOP
        SELECT people.id
        INTO tempStudentId
        FROM people
        JOIN groups
          ON people.group_id = groups.id
        WHERE groups.id = groupToReplace
        ORDER BY people.id DESC
        OFFSET 0 ROWS FETCH FIRST 1 ROWS ONLY;
        
        UPDATE people SET group_id = groupToSet
        WHERE id = tempStudentId;
    END LOOP;
END;
    
    
-- модификация в рамках транзакции:
-- 1. Заменить во всех существующих записях заданный предмет на другой и
--    удалить этот предмет из таблицы предметов.
DECLARE
    subjToReplace NUMBER := 9;
    subjToSet NUMBER := 10;
    tempSubjectId NUMBER;
BEGIN    
        SELECT subjects.id
        INTO tempSubjectId
        FROM subjects
        JOIN marks
          ON subjects.id = marks.subject_id
        WHERE subjects.id = subjToReplace
        ORDER BY subjects.id DESC
        OFFSET 0 ROWS FETCH FIRST 1 ROWS ONLY;
        
        UPDATE marks SET subject_id = subjToSet
        WHERE subject_id = tempSubjectId;
        DELETE FROM subjects WHERE id = tempSubjectId;
END;

-- 2. то же, что и п.1, но в случае, если преподаватель, читающий удаляемый
--    предмет, больше ничего не читает – откатить транзакцию.
DECLARE
    subjToReplace NUMBER := 10;
    subjToSet NUMBER := 13;
    tempSubjectId NUMBER;
    
    teacherId NUMBER;
    numOfReadSubjects NUMBER;
BEGIN
    COMMIT;
    
    SELECT teacher_id
    INTO teacherId
    FROM marks
    JOIN subjects
    ON subjects.id = marks.subject_id
    WHERE subjects.id = subjToReplace
    OFFSET 0 ROWS FETCH FIRST 1 ROWS ONLY;
    
    SELECT COUNT(DISTINCT marks.subject_id)
    INTO numOfReadSubjects
    FROM marks
    WHERE teacher_id = teacherId;
    
    IF (numOfReadSubjects > 1)
    THEN    
        SELECT subjects.id
        INTO tempSubjectId
        FROM subjects
        JOIN marks
          ON subjects.id = marks.subject_id
        WHERE subjects.id = subjToReplace
        ORDER BY subjects.id DESC
        OFFSET 0 ROWS FETCH FIRST 1 ROWS ONLY;
        
        UPDATE marks SET subject_id = subjToSet
        WHERE subject_id = tempSubjectId;
        DELETE FROM subjects WHERE id = tempSubjectId;
        COMMIT;
    ELSE
        ROLLBACK;
    END IF;
END;


