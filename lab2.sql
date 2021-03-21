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
    --WHERE people.type = 'S'
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
-- 2. �� �� ��� �.1. ���� ������ � ���������� ������������� ��� ���������� � ���������� ��������.
    
    