/*
    Представления
*/
-- 1. Создать представление, отображающее всех преподавателей, предметы и средний
--    балл, выставляемый ими, агрегируя по предметам.
CREATE VIEW avg_marks_by_subjects AS
SELECT people.last_name, people.first_name, subjects.name, AVG(marks.value) AS avg_mark
FROM
    people
    JOIN marks ON people.id = marks.teacher_id
    JOIN subjects ON marks.subject_id = subjects.id
    GROUP BY subjects.name, people.last_name, people.first_name;
    
SELECT * FROM avg_marks_by_subjects;

-- 2. Создать представление, отображающее средние баллы, агрегируя оценки по годам.
CREATE VIEW avg_marks_by_years AS
SELECT SUBSTR(groups.name, 8) AS group_year, AVG(marks.value) AS avg_mark
FROM
    people
    JOIN marks ON people.id = marks.student_id
    JOIN groups ON people.group_id = groups.id
    GROUP BY SUBSTR(groups.name, 8);
    
SELECT * FROM avg_marks_by_years;



/*
    Хранимые процедуры
*/
-- без параметров:
-- 1. Создать хранимую процедуру, выводящую все предметы, по которым в
--    заданном году были выставлены оценки, и средний балл по каждому из
--    предметов.
set serveroutput on;
CREATE OR REPLACE PROCEDURE subjects_avg_mark_year
IS
    TYPE subjects_avg_mark_year_type IS RECORD (
        name VARCHAR2(50),
        avg_mark FLOAT
    );
    tmp_rec subjects_avg_mark_year_type;
    
    CURSOR subjects_cursor IS
    SELECT subjects.name, AVG(marks.value) AS avg_mark
    FROM subjects
    JOIN marks ON subjects.id = marks.subject_id
    JOIN people ON people.id = marks.student_id
    JOIN groups ON people.group_id = groups.id
    WHERE SUBSTR(groups.name, 8) = '2005'
    GROUP BY subjects.name;
BEGIN
    dbms_output.put_line('Предмет'||' '||'Средний балл');
    FOR tmp_rec IN subjects_cursor
    LOOP
        dbms_output.put_line(tmp_rec.name||' '||tmp_rec.avg_mark);
    END LOOP;
END subjects_avg_mark_year;

EXECUTE subjects_avg_mark_year;

-- с входными параметрами:
-- 1. Создать хранимую процедуру. Входные параметры задают интервал
--    времени. Процедура должна вернуть выборку средних баллов по группам,
--    попавшим в этот интервал.
CREATE OR REPLACE PROCEDURE groups_avg_mark_years(startYear IN VARCHAR, endYear IN VARCHAR)
IS
    TYPE groups_avg_mark_years_type IS RECORD (
        name VARCHAR2(50),
        avg_mark FLOAT
    );
    tmp_rec groups_avg_mark_years_type;
    
    CURSOR groups_cursor IS
    SELECT groups.name, AVG(marks.value) AS avg_mark
    FROM groups
    JOIN people ON people.group_id = groups.id
    JOIN marks ON people.id = marks.student_id
    WHERE SUBSTR(groups.name, 8) >= startYear AND SUBSTR(groups.name, 8) <= endYear
    GROUP BY groups.name;
BEGIN
    dbms_output.put_line('Группа'||' '||'Средний балл');
    FOR tmp_rec IN groups_cursor
    LOOP
        dbms_output.put_line(tmp_rec.name||' '||tmp_rec.avg_mark);
    END LOOP;
END groups_avg_mark_years;

EXECUTE groups_avg_mark_years('2005', '2007');

-- с выходными параметрами:
-- 1. Создать хранимую процедуру с входным параметром «преподаватель» и
--    выходным параметром – группа, с наименьшим средним баллом у этого
--    преподавателя.
CREATE OR REPLACE PROCEDURE group_min_mark_teacher(teacherId IN NUMBER, groupId OUT NUMBER)
IS
BEGIN   
    SELECT DISTINCT groups.id
    INTO groupId
    FROM
        marks
        JOIN people ON marks.student_id = people.id
        JOIN groups ON groups.id = people.group_id
        WHERE marks.teacher_id = teacherId
    GROUP BY groups.id
    ORDER BY AVG(marks.value)
    OFFSET 0 ROWS FETCH FIRST 1 ROWS ONLY;
END group_min_mark_teacher;

VARIABLE groupp_id NUMBER
EXECUTE group_min_mark_teacher(23, :groupp_id);
PRINT groupp_id;

/*
    Триггеры
*/
-- Триггеры на вставку:
-- 1. Создать триггер, который не позволяет добавить оценку, не попадающую в
--    интервал [2..5].
CREATE OR REPLACE TRIGGER check_mark_value
    BEFORE INSERT OR UPDATE ON marks
        FOR EACH ROW
BEGIN
    IF (:NEW.value < 2 OR :NEW.value > 5)
    THEN
        RAISE_APPLICATION_ERROR(-20202, 'Value is not in [2..5]');
    END IF;
END;

INSERT INTO marks (id, student_id, SUBJECT_ID, TEACHER_ID, value) VALUES(1, 1, 1, 1, 6);

-- Триггеры на модификацию:
-- 1. Создать триггер, который не позволяет изменить наименование предмета,
--    если на него есть ссылки.
CREATE OR REPLACE TRIGGER checkSubjectName
    BEFORE UPDATE ON subjects
        FOR EACH ROW
DECLARE
    referencess NUMBER;
BEGIN
    SELECT COUNT(*)
    INTO referencess
    FROM marks
    WHERE subject_id = :NEW.id;
    
    IF referencess != 0
    THEN
        RAISE_APPLICATION_ERROR(-20202, 'The subject is binded by records in other tables');
    END IF;
END;

UPDATE subjects SET name = 'ООПП' WHERE id = 12;

-- Триггеры на удаление:
-- 1. Создать триггер, который при удалении предмета, если на него существуют
--    ссылки – откатывает транзакцию.
CREATE OR REPLACE TRIGGER checkSubjectDeleting
    BEFORE DELETE ON subjects
        FOR EACH ROW
DECLARE
    referencess NUMBER;
BEGIN
    SELECT COUNT(*)
    INTO referencess
    FROM marks
    WHERE subject_id = :OLD.id;
    
    IF referencess != 0
    THEN
        RAISE_APPLICATION_ERROR(-20202, 'The subject is binded by records in other tables. Transaction was rolled back.');
    END IF;
END;

DELETE FROM subjects WHERE id = 12;


/* 
    Курсор
*/
-- Хранимая процедура для расчета успеваемости и прироста успеваемости:
-- Хранимая процедура имеет два параметра, определяющие анализируемый интервал
-- времени. Результатом работы процедуры должна явиться выборка, содержащая средний
-- балл по всем предметам в рассматриваемом интервале времени, и разницу текущего
-- среднего балла и предыдущего.
-- Алгоритм реализации предлагается следующий. Организуется курсор,
-- перебирающий все года, в которых проводилось обучение, попадающие в заданный
-- интервал времени. Средний балл предыдущего года запоминается в переменной. В теле
-- курсора формируется выборка необходимых данных.
CREATE OR REPLACE PROCEDURE calculatePerformance(startYear IN VARCHAR, endYear IN VARCHAR)
IS
    avg_mark FLOAT;
    new_avg_mark FLOAT;
    tmp_year VARCHAR(4);
    diff FLOAT;
    
    CURSOR my_cursor IS
    SELECT DISTINCT SUBSTR(groups.name, 8) AS year
    FROM groups
         JOIN people ON groups.id = people.group_id
         JOIN marks ON people.id = marks.student_id
    WHERE SUBSTR(groups.name, 8) >= startYear AND SUBSTR(groups.name, 8) <= endYear
    ORDER BY year;
BEGIN
    OPEN my_cursor;
    FETCH my_cursor INTO tmp_year;
    
    SELECT AVG(marks.value)
    INTO avg_mark
    FROM
        marks
        JOIN people ON marks.student_id = people.id
        JOIN groups ON people.group_id = groups.id
        WHERE SUBSTR(groups.name, 8) = tmp_year;
    
    dbms_output.put_line('Year'||' '||'avg_mark'||' '||'difference');
    dbms_output.put_line(tmp_year||' '||avg_mark||' '||'0');
    LOOP
        FETCH my_cursor INTO tmp_year;
        EXIT WHEN my_cursor%NOTFOUND;
        
        SELECT AVG(marks.value)
        INTO new_avg_mark
        FROM
            marks
            JOIN people ON marks.student_id = people.id
            JOIN groups ON people.group_id = groups.id
            WHERE SUBSTR(groups.name, 8) = tmp_year;
            
        diff := new_avg_mark - avg_mark;
        dbms_output.put_line(tmp_year||' '||new_avg_mark||' '||diff);
        avg_mark := new_avg_mark;
    END LOOP;
    
    CLOSE my_cursor;
END calculatePerformance;

EXECUTE calculatePerformance('2005', '2007');