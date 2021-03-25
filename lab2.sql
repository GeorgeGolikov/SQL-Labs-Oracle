/*
    ������� ������
*/
-- ������������� �������
-- ������� ��� ������, ���������� �� � �������� ������� �� ���� � � ������ ������� �� ������������.
SELECT *
FROM
    groups
ORDER BY
    SUBSTR(name, 7) DESC,
    name
;

-- ������� � ������������
-- ������� ����� ���������, �� ������� ���� ������ � ������, �������� �� ������������.
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

-- ���������� ������ (join):
-- 1. ������� ��������� � ������������ ���������(������� ��� �������), ������� ��������, �������
--    �� �������� ��������� � ���������, ������� �� �������� �� ����� ������.
-- people(type=s), marks, subjects

   SELECT people.first_name, people.last_name, people.group_id, subjects.name
     FROM people
LEFT JOIN marks
       ON people.id = marks.student_id
FULL JOIN subjects
       ON marks.subject_id = subjects.id
    WHERE people.type = 'S' OR subjects.id IS NOT NULL
;

-- 2. ������� ��� ������ � ������� ���� ��������� ������.
  SELECT groups.id, groups.name, AVG(marks.value)
    FROM marks
    JOIN people
      ON marks.student_id = people.id
    JOIN groups
      ON groups.id = people.group_id
GROUP BY groups.id, groups.name;

    
 /*
    ������� ������
*/
-- ������������� �������
-- 1. �������� ������ ��������.
INSERT INTO people
            (first_name, last_name, father_name, group_id, type)
     VALUES
            ('�����', '������������', '�����������', '1', 'S');
            
-- 2. �������� ������ �� ���������� �������� �������� �� �.1.
INSERT INTO marks
            (student_id, subject_id, teacher_id, value)
     VALUES
            (
                (SELECT id FROM people
                WHERE first_name = '�����' AND last_name = '������������' AND father_name = '�����������'),
                1,
                1,
                5
            );
        
    
    
-- �������������� ������� � ������ ����������
-- 1. ������� ����� �������� ������ (�� ����������) � ����������� ����� �� 1
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
-- �������� ������ �� ���� ������
    newGroupName := CONCAT(TO_CHAR(TO_NUMBER(SUBSTR(groupName, 1, 1)) + 1), SUBSTR(groupName, 2));
    dbms_output.put_line(newGroupName);
    
-- ������� ������ � ������ �� 1 ���� ���� ���������
    INSERT INTO groups
            (name)
     VALUES
            (newGroupName);
            
-- ������� id ������ ������
    SELECT id INTO groupId FROM groups WHERE name = groupName;
    dbms_output.put_line(groupId);
    
-- ������� id ����� ������
    SELECT id INTO newGroupId FROM groups WHERE name = newGroupName;
    dbms_output.put_line(newGroupId);
            
-- ������� ���� ��������� �������� ������
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
    
    
-- 2. �� �� ��� �.1. ���� ������ � ���������� ������������� ��� ���������� � ���������� ��������
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
-- �������� ������ �� ���� ������
    newGroupName := CONCAT(TO_CHAR(TO_NUMBER(SUBSTR(groupName, 1, 1)) + 1), SUBSTR(groupName, 2));
    dbms_output.put_line(newGroupName);
    
-- ���� ������ ��� ���������� - rollback
    SELECT COUNT(name) INTO groupFromTable FROM groups WHERE name = newGroupName;
    
    IF (groupFromTable = 0) 
    THEN
    -- ������� ������ � ������ �� 1 ���� ���� ���������
        INSERT INTO groups
            (name)
        VALUES
            (newGroupName);
            
    -- ������� id ������ ������
        SELECT id INTO groupId FROM groups WHERE name = groupName;
        dbms_output.put_line(groupId);
    
    -- ������� id ����� ������
        SELECT id INTO newGroupId FROM groups WHERE name = newGroupName;
        dbms_output.put_line(newGroupId);
            
    -- ������� ���� ��������� �������� ������
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
    �������� ������
*/
-- �������� �� ������� � �������� �� ��������� ������:
-- 1. ������� ���������, � ������� ������� ���� ���� ���������.
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

-- 2. ������� �������� ������ � ���������, ������������� ��.
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


-- ������� ������ � ����������� ������� ������
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

-- �������� � ������ ����������:
-- 1. ������� � ������ ���������� ������ � ����� ��������� ������� ������ � ���������, ������������� ��.
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

-- 2. �� ��, ��� � �.1, ��, ���� � ��������� ������ �������� 3 ��������, ������� ������ ����� �� �������� � ���������� ��������.
-- ���-�� ���������, ��� ������� ������ - ���� � �� �� � ������ ����, ����� 3.
-- ������� - ������ - ������� - ������


 /*
    ����������� ������
*/
-- ����������� �� �������:
-- 1. ��������� �������� ������ �� ������.
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
    
    
-- ����������� � ������ ����������:
-- 1. �������� �� ���� ������������ ������� �������� ������� �� ������ �
--    ������� ���� ������� �� ������� ���������.
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

-- 2. �� ��, ��� � �.1, �� � ������, ���� �������������, �������� ���������
--    �������, ������ ������ �� ������ � �������� ����������.
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


