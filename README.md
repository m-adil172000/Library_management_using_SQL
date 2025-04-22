# Library Management System using SQL

## 📆 Project Overview
This project implements a comprehensive **Library Management System** using **MySQL**. It includes data modeling, DDL (Data Definition Language) and DML (Data Manipulation Language) operations, as well as stored procedures for automating book issuing and return processes.

---

## 📑 Database Name
```sql
CREATE DATABASE library_db;
```

---

## 📂 Tables Created

### 1. `branch`
- Contains information about each branch.

### 2. `employees`
- Stores employee details and their branch affiliation.

### 3. `members`
- Holds library member data.

### 4. `books`
- Manages book metadata and availability.

### 5. `issued_status`
- Tracks which books are issued, to whom, and by which employee.

### 6. `return_status`
- Records return information and book condition.

---

## 🔧 Operations Performed

### CRUD Operations
1. Delete a book by title.
2. Insert a new book record.
3. Update a member's address.


## Database and Table Creation

```sql
CREATE DATABASE library_db;

-- Create table: branch
CREATE TABLE branch (
    branch_id VARCHAR(10) PRIMARY KEY,
    manager_id VARCHAR(10),
    branch_address VARCHAR(30),
    contact_no VARCHAR(15)
);

-- Create table: employees
CREATE TABLE employees (
    emp_id VARCHAR(10) PRIMARY KEY,
    emp_name VARCHAR(30),
    position VARCHAR(30),
    salary DECIMAL(10,2),
    branch_id VARCHAR(10),
    FOREIGN KEY (branch_id) REFERENCES branch(branch_id)
);

-- Create table: members
CREATE TABLE members (
    member_id VARCHAR(10) PRIMARY KEY,
    member_name VARCHAR(30),
    member_address VARCHAR(30),
    reg_date DATE
);

-- Create table: books
CREATE TABLE books (
    isbn VARCHAR(50) PRIMARY KEY,
    book_title VARCHAR(80),
    category VARCHAR(30),
    rental_price DECIMAL(10,2),
    status VARCHAR(10),
    author VARCHAR(30),
    publisher VARCHAR(30)
);

-- Create table: issued_status
CREATE TABLE issued_status (
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

-- Create table: return_status
CREATE TABLE return_status (
    return_id VARCHAR(10) PRIMARY KEY,
    issued_id VARCHAR(30),
    return_book_name VARCHAR(100),
    return_date DATE,
    return_book_isbn VARCHAR(100),
    FOREIGN KEY (return_book_isbn) REFERENCES books(isbn)
);
```

## Tasks and Queries

### 1. Delete a specific book
```sql
delete from books
where book_title = 'To Kill a Mockingbird';
```

### 2. Insert a new book
```sql
insert into books(isbn, book_title, category, rental_price, status, author, publisher)
values('978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.');
```

### 3. Update a member's address
```sql
update members
set member_address = '125 Oak St'
where member_id = 'C103';
```

### 4. List members who issued more than one book
```sql
with cte as (
    select issued_id, issued_member_id, member_name
    from issued_status as t1
    join members as t2 on t1.issued_member_id = t2.member_id
)
select member_name, count(*) as books_issued
from cte
group by 1
having books_issued > 1
order by 2;
```

### 5. Create a summary table for issued books
```sql
create table books_issue_count as
select t1.book_title, count(t1.book_title) as issued_count 
from books as t1
join issued_status as t2 on t1.isbn = t2.issued_book_isbn
group by 1;
```

### 6. Total rental income by category
```sql
select t1.category, sum(t1.rental_price) as total_rental_income, count(*) as issued_count
from books as t1
join issued_status as t2
on t1.isbn = t2.issued_book_isbn
group by 1
order by 2;
```

### 7. Members registered in the last 180 days
```sql
insert into members(member_id, member_name, member_address, reg_date)
values ('C120','Sam','145 Main St','2025-04-21'),
       ('C121','Peter','145 Church St','2025-02-19');

select member_name
from members
where reg_date >= CURDATE() - INTERVAL 180 DAY;
```

### 8. Employees and their branch managers
```sql
with cte as (
    select t1.emp_id, t1.emp_name, t2.manager_id
    from employees as t1
    join branch as t2 on t1.branch_id = t2.branch_id
)
select t2.emp_name, t1.emp_name as manager 
from cte as t1
join cte as t2 on t1.emp_id = t2.manager_id;
```

### 9. Overdue books
```sql
select t1.issued_member_id, t3.member_name, t2.book_title, t1.issued_date, curdate() - t1.issued_date  as overdue_days
from issued_status as t1
join books as t2 on t1.issued_book_isbn = t2.isbn
join members as t3 on t1.issued_member_id = t3.member_id
left join return_status as t4 on t4.issued_id = t1.issued_id
where t4.return_date is null and curdate() - t1.issued_date > 30
order by 2;
```

### 10. Procedure to handle book returns
```sql
DELIMITER $$
CREATE PROCEDURE add_return_records(p_return_id VARCHAR(10), p_issued_id VARCHAR(10), p_book_quality VARCHAR(10))
BEGIN 
    DECLARE v_isbn VARCHAR(50);
    DECLARE v_book_name VARCHAR(80);

    INSERT INTO return_status (return_id, issued_id, return_date, book_quality)
    VALUES (p_return_id, p_issued_id, CURRENT_DATE(), p_book_quality);

    SELECT issued_book_isbn, issued_book_name INTO v_isbn, v_book_name
    FROM issued_status
    WHERE issued_id = p_issued_id;

    UPDATE books SET status = 'yes' WHERE isbn = v_isbn;

    SELECT CONCAT('Thank you for returning the book: ', v_book_name) AS message;
END $$
DELIMITER ;
```

### 11. Branch performance report
```sql
CREATE TABLE branch_performance_report AS
select 
    br.branch_id,
    br.manager_id,
    COUNT(ist.issued_id) as number_book_issued,
    COUNT(rst.return_id) as number_of_book_return,
    SUM(bk.rental_price) as total_revenue
from books as bk
join issued_status as ist on bk.isbn = ist.issued_book_isbn
left join return_status as rst on ist.issued_id = rst.issued_id
join employees as emp on emp.emp_id = ist.issued_emp_id
join branch as br on br.branch_id = emp.branch_id
group by 1,2;

select * from branch_performance_report;
```

### 12. Create table for active members
```sql
DROP TABLE IF EXISTS Active_members;
CREATE TABLE Active_members AS
select * 
from members 
where member_id in (
    select distinct issued_member_id
    from issued_status
    where issued_date >= CURDATE() - INTERVAL 60 DAY
);

select * from Active_members;
```

### 13. Top 3 employees by book issues
```sql
select 
    emp.emp_name, 
    emp.branch_id,
    count(*) as books_processed
from issued_status as ist
join employees as emp on emp.emp_id = ist.issued_emp_id
group by 1,2
order by 3 DESC
limit 3;
```

### 14. Procedure to manage book status during issuance
```sql
DELIMITER $$
CREATE PROCEDURE book_status_management(
    p_issued_id VARCHAR(10), 
    p_issued_member_id VARCHAR(30), 
    p_issued_book_isbn VARCHAR(30), 
    p_issued_emp_id VARCHAR(10)
)
BEGIN 
    DECLARE book_status VARCHAR(10);

    SELECT status INTO book_status FROM books WHERE isbn = p_issued_book_isbn;

    IF book_status = 'yes' THEN
        INSERT INTO issued_status(issued_id, issued_member_id, issued_date, issued_book_isbn, issued_emp_id)
        VALUES (p_issued_id, p_issued_member_id, CURDATE(), p_issued_book_isbn, p_issued_emp_id);

        UPDATE books SET status = 'no' WHERE isbn = p_issued_book_isbn;

        SELECT CONCAT('Book record added successfully for the book isbn: ', p_issued_book_isbn) AS message;
    ELSE
        SELECT CONCAT('Sorry, the book you have requested is not available isbn: ', p_issued_book_isbn) AS message;
    END IF;
END $$
DELIMITER ;

CALL book_status_management('IS155', 'C108', '978-0-553-29698-2', 'E104');
```

---

## Conclusion
This project showcases a comprehensive relational schema for a library management system, including multiple queries and procedures to handle real-life operations like book issuance, return tracking, overdue analysis, employee performance, and active member tracking.

## ✅ Technologies Used
- MySQL
- SQL (DDL, DML, Stored Procedures)
