CREATE DATABASE library_db;

DROP TABLE IF EXISTS branch;
CREATE TABLE branch
(
            branch_id VARCHAR(10) PRIMARY KEY,
            manager_id VARCHAR(10),
            branch_address VARCHAR(30),
            contact_no VARCHAR(15)
);


-- Create table "Employee"
DROP TABLE IF EXISTS employees;
CREATE TABLE employees
(
            emp_id VARCHAR(10) PRIMARY KEY,
            emp_name VARCHAR(30),
            position VARCHAR(30),
            salary DECIMAL(10,2),
            branch_id VARCHAR(10),
            FOREIGN KEY (branch_id) REFERENCES  branch(branch_id)
);


-- Create table "Members"
DROP TABLE IF EXISTS members;
CREATE TABLE members
(
            member_id VARCHAR(10) PRIMARY KEY,
            member_name VARCHAR(30),
            member_address VARCHAR(30),
            reg_date DATE
);



-- Create table "Books"
DROP TABLE IF EXISTS books;
CREATE TABLE books
(
            isbn VARCHAR(50) PRIMARY KEY,
            book_title VARCHAR(80),
            category VARCHAR(30),
            rental_price DECIMAL(10,2),
            status VARCHAR(10),
            author VARCHAR(30),
            publisher VARCHAR(30)
);



-- Create table "IssueStatus"
DROP TABLE IF EXISTS issued_status;
CREATE TABLE issued_status
(
            issued_id VARCHAR(10) PRIMARY KEY,
            issued_member_id VARCHAR(30),
            issued_book_name VARCHAR(80),
            issued_date DATE,
            issued_book_isbn VARCHAR(50),
            issued_emp_id VARCHAR(10),
            FOREIGN KEY (issued_member_id) REFERENCES members(member_id),
            FOREIGN KEY (issued_emp_id) REFERENCES employees(emp_id),
            FOREIGN KEY (issued_book_isbn) REFERENCES books(isbn) 
);



-- Create table "ReturnStatus"
DROP TABLE IF EXISTS return_status;
CREATE TABLE return_status
(
            return_id VARCHAR(10) PRIMARY KEY,
            issued_id VARCHAR(30),
            return_book_name VARCHAR(100),
            return_date DATE,
            return_book_isbn VARCHAR(100),
            FOREIGN KEY (return_book_isbn) REFERENCES books(isbn)
);

-- Tasks

-- 1. Delete the book 'To kill a Mockingbird' from the books table
delete from books
where book_title = 'To Kill a Mockingbird';

-- 2. Create a New Book Record -- "978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.')"
insert into books(isbn, book_title, category, rental_price, status, author, publisher)
values('978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.');

-- 3.Update an Existing Member's Address
update members
set member_address = '125 Oak St'
where member_id = 'C103';

-- 4. Write a SQL query to list Members Who Have Issued More Than One Book
with cte as
(
	select issued_id, issued_member_id, member_name
	from issued_status as t1
	join members as t2
	on t1.issued_member_id = t2.member_id
)
select member_name, count(*) as books_issued
from cte
group by 1
having books_issued >1
order by 2;

-- 5. Create Summary Tables: Used CTAS to generate new tables based on query results - each book and total book_issued_cnt
create table books_issue_count
as
select t1.book_title, count(t1.book_title) as issued_count 
from books as t1
join issued_status as t2
on t1.isbn = t2.issued_book_isbn
group by 1;

-- 6. Write a SQL query to Find Total Rental Income by Category
select t1.category, sum(t1.rental_price) as total_rental_income, count(*) as issued_count
from books as t1
join issued_status as t2
group by 1
order by 2;

-- 7. List Members Who Registered in the Last 180 Days:

insert into members(member_id,member_name,member_address,reg_date)
values
('C120','Sam','145 Main St','2025-04-21'),
('C121','Peter','145 Church St','2025-02-19');

select member_name
from members
where reg_date >= CURDATE() - INTERVAL 180 DAY;

-- 8. List Employees with Their Branch Manager's Name and their branch details

with cte as
(
select t1.emp_id, t1.emp_name, t2.manager_id
from employees as t1
join branch as t2
on t1.branch_id = t2.branch_id
)
select t2.emp_name, t1.emp_name as manager 
from cte as t1
join cte as t2
on t1.emp_id = t2.manager_id;

-- 9. Write a query to identify members who have overdue books (assume a 30-day return period). Display the member's_id, member's name, book title, issue date, and 
-- days overdue. Let Today's date be 2024-05-01

select t1.issued_member_id, t3.member_name, t2.book_title, t1.issued_date, curdate() - t1.issued_date  as overdue_days
from issued_status as t1
join books as t2
on t1.issued_book_isbn = t2.isbn
join members as t3
on t1.issued_member_id = t3.member_id
left join return_status as t4
on t4.issued_id = t1.issued_id
where t4.return_date is null and curdate() - t1.issued_date  >30
order by 2;

-- 10. Write a query to update the status of books in the books table to "Yes" when they are returned (based on entries in the return_status table).
-- 			We are going to create a function for this

DELIMITER $$
CREATE PROCEDURE add_return_records(p_return_id VARCHAR(10), p_issued_id VARCHAR(10), p_book_quality VARCHAR(10))

BEGIN 

	-- Declaring the variables
	DECLARE v_isbn VARCHAR(50);
	DECLARE v_book_name VARCHAR(80);

	-- Insert into return_status table
    INSERT INTO return_status (return_id, issued_id, return_date, book_quality)
    VALUES (p_return_id, p_issued_id, CURRENT_DATE(), p_book_quality);
    
    -- Get book info from the issued_status table
    SELECT issued_book_isbn, issued_book_name
    INTO v_isbn, v_book_name
    FROM issued_status
    WHERE issued_id = p_issued_id;
    
    -- Update books table
    UPDATE books
    SET status = 'yes'
    WHERE isbn = v_isbn;
    
    -- Print message
    SELECT CONCAT('Thank you for returning the book: ',v_book_name) AS message;

END $$

DELIMITER ;


-- 11. Create a query that generates a performance report for each branch, showing the number of books issued, the number of books returned, 
-- and the total revenue generated from book rentals.

CREATE TABLE branch_performance_report
AS
select 
	br.branch_id,
	br.manager_id,
	COUNT(ist.issued_id) as number_book_issued,
	COUNT(rst.return_id) as number_of_book_return,
	SUM(bk.rental_price) as total_revenue
from books as bk
join issued_status as ist
on bk.isbn = ist.issued_book_isbn
left join return_status as rst
on ist.issued_id = rst.issued_id
join employees as emp
on emp.emp_id = ist.issued_emp_id
join branch as br
on br.branch_id = emp.branch_id
group by 1,2;

select * from branch_performance_report;

-- 12. CTAS: Create a Table of Active Members
--	Use the CREATE TABLE AS (CTAS) statement to create a new table active_members containing members who have issued at least one book in the last 2 months.

DROP TABLE if exists Active_members ;
CREATE TABLE Active_members
AS
	select * 
	from members 
	where member_id in
	(
		select distinct issued_member_id
		from issued_status
		where issued_date >= curdate() - interval 720 day
    );
    
select * from Active_members;



-- 13. Write a query to find the top 3 employees who have processed the most book issues. Display the employee name, number of books processed, and their branch.

select 
	emp.emp_name, 
    emp.branch_id,
    count(*) as books_processed
from issued_status as ist
join employees as emp
on emp.emp_id = ist.issued_emp_id
group by 1,2
order by 3 DESC;

/*
14. Create a stored procedure to manage the status of books in a library system. Description: Write a stored procedure that updates the status of a book in the 
library based on its issuance. The procedure should function as follows: The stored procedure should take the book_id as an input parameter. The procedure should 
first check if the book is available (status = 'yes'). If the book is available, it should be issued, and the status in the books table should be updated to 'no'. 
If the book is not available (status = 'no'), the procedure should return an error message indicating that the book is currently not available.
*/
DELIMITER $$
CREATE PROCEDURE book_status_management(p_issued_id VARCHAR(10), p_issued_member_id VARCHAR(30), p_issued_book_isbn VARCHAR(30), p_issued_emp_id VARCHAR(10))
BEGIN 
	
    -- Creating a varaible to store the book status
	DECLARE book_status VARCHAR(10);
	
    -- Checking the book status
    select status into book_status
    from books
    where isbn = p_issued_book_isbn;
    
    -- If the status is 'yes' then the book will be issued and the book status will be set to 'no' and also add the entry in the issued_status
    If book_status = 'yes' then
		
        insert into issued_status(issued_id, issued_member_id, issued_date, issued_book_isbn, issued_emp_id)
        values (p_issued_id, p_issued_member_id, curdate(), p_issued_book_isbn, p_issued_emp_id);
        
        update books
        set status = 'no'
        where isbn = p_issued_book_isbn;
        
        SELECT CONCAT('Book record added successfully for the book isbn: ',p_issued_book_isbn) AS message;
	
    ELSE
		SELECT CONCAT('Sorry, the book you have requested is not available isbn: ',p_issued_book_isbn) AS message;
    END IF;
    
END $$
DELIMITER ;

CALL book_status_management('IS155', 'C108', '978-0-553-29698-2', 'E104')

