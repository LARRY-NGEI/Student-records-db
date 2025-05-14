-- Student Records Management System

-- Created by Larry Ngei

-- Create database
DROP DATABASE IF EXISTS student_records;
CREATE DATABASE student_records;
USE student_records;

-- Department table (1-M relationship with Students and Courses)
CREATE TABLE department (
    department_id INT AUTO_INCREMENT PRIMARY KEY,
    department_code VARCHAR(10) NOT NULL UNIQUE,
    department_name VARCHAR(100) NOT NULL,
    office_location VARCHAR(100),
    phone VARCHAR(20),
    email VARCHAR(100),
    chair_person VARCHAR(100),
    established_date DATE,
    CONSTRAINT chk_department_email CHECK (email LIKE '%@%.%')
);

-- Student table (central entity with multiple relationships)
CREATE TABLE student (
    student_id INT AUTO_INCREMENT PRIMARY KEY,
    student_number VARCHAR(20) NOT NULL UNIQUE,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    date_of_birth DATE NOT NULL,
    gender ENUM('Male', 'Female', 'Other') NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    phone VARCHAR(20),
    address VARCHAR(200),
    admission_date DATE NOT NULL,
    graduation_date DATE,
    department_id INT,
    status ENUM('Active', 'Graduated', 'Suspended', 'Withdrawn') DEFAULT 'Active',
    CONSTRAINT fk_student_department FOREIGN KEY (department_id) REFERENCES department(department_id),
    CONSTRAINT chk_student_email CHECK (email LIKE '%@%.%'),
    CONSTRAINT chk_graduation_date CHECK (graduation_date IS NULL OR graduation_date > admission_date)
);

-- Faculty table (1-M relationship with Courses)
CREATE TABLE faculty (
    faculty_id INT AUTO_INCREMENT PRIMARY KEY,
    faculty_number VARCHAR(20) NOT NULL UNIQUE,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    date_of_birth DATE,
    gender ENUM('Male', 'Female', 'Other'),
    email VARCHAR(100) NOT NULL UNIQUE,
    phone VARCHAR(20),
    address VARCHAR(200),
    hire_date DATE NOT NULL,
    department_id INT,
    position VARCHAR(50),
    salary DECIMAL(10,2),
    status ENUM('Active', 'On Leave', 'Retired', 'Terminated') DEFAULT 'Active',
    CONSTRAINT fk_faculty_department FOREIGN KEY (department_id) REFERENCES department(department_id),
    CONSTRAINT chk_faculty_email CHECK (email LIKE '%@%.%')
);

-- Course table (1-M relationship with Sections)
CREATE TABLE course (
    course_id INT AUTO_INCREMENT PRIMARY KEY,
    course_code VARCHAR(20) NOT NULL UNIQUE,
    course_name VARCHAR(100) NOT NULL,
    description TEXT,
    credit_hours INT NOT NULL,
    department_id INT,
    prerequisite_course_id INT,
    CONSTRAINT fk_course_department FOREIGN KEY (department_id) REFERENCES department(department_id),
    CONSTRAINT fk_course_prerequisite FOREIGN KEY (prerequisite_course_id) REFERENCES course(course_id),
    CONSTRAINT chk_credit_hours CHECK (credit_hours > 0 AND credit_hours <= 6)
);

-- Academic term table (1-M relationship with Sections)
CREATE TABLE academic_term (
    term_id INT AUTO_INCREMENT PRIMARY KEY,
    term_name VARCHAR(50) NOT NULL,
    term_code VARCHAR(20) NOT NULL UNIQUE,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    registration_start DATE NOT NULL,
    registration_end DATE NOT NULL,
    CONSTRAINT chk_term_dates CHECK (end_date > start_date),
    CONSTRAINT chk_registration_dates CHECK (registration_end > registration_start AND 
                                           registration_start < start_date AND 
                                           registration_end < start_date)
);

-- Section table (connects Courses, Faculty, and Terms)
CREATE TABLE section (
    section_id INT AUTO_INCREMENT PRIMARY KEY,
    section_number VARCHAR(10) NOT NULL,
    course_id INT NOT NULL,
    term_id INT NOT NULL,
    faculty_id INT,
    classroom VARCHAR(20),
    schedule VARCHAR(100),
    max_capacity INT NOT NULL,
    current_enrollment INT NOT NULL DEFAULT 0,
    CONSTRAINT fk_section_course FOREIGN KEY (course_id) REFERENCES course(course_id),
    CONSTRAINT fk_section_term FOREIGN KEY (term_id) REFERENCES academic_term(term_id),
    CONSTRAINT fk_section_faculty FOREIGN KEY (faculty_id) REFERENCES faculty(faculty_id),
    CONSTRAINT chk_section_capacity CHECK (current_enrollment <= max_capacity),
    CONSTRAINT unique_section UNIQUE (section_number, course_id, term_id)
);

-- Enrollment table (M-M relationship between Students and Sections)
CREATE TABLE enrollment (
    enrollment_id INT AUTO_INCREMENT PRIMARY KEY,
    student_id INT NOT NULL,
    section_id INT NOT NULL,
    enrollment_date DATE NOT NULL,
    withdrawal_date DATE,
    status ENUM('Enrolled', 'Withdrawn', 'Dropped', 'Completed') DEFAULT 'Enrolled',
    CONSTRAINT fk_enrollment_student FOREIGN KEY (student_id) REFERENCES student(student_id),
    CONSTRAINT fk_enrollment_section FOREIGN KEY (section_id) REFERENCES section(section_id),
    CONSTRAINT chk_withdrawal_date CHECK (withdrawal_date IS NULL OR withdrawal_date >= enrollment_date),
    CONSTRAINT unique_student_section UNIQUE (student_id, section_id) 
        WHERE status = 'Enrolled' -- Note: This is a conceptual constraint
);

-- Grade table (1-1 relationship with Enrollment)
CREATE TABLE grade (
    grade_id INT AUTO_INCREMENT PRIMARY KEY,
    enrollment_id INT NOT NULL UNIQUE,
    letter_grade VARCHAR(2),
    grade_points DECIMAL(3,2),
    comments TEXT,
    date_recorded DATE NOT NULL,
    recorded_by_faculty_id INT NOT NULL,
    CONSTRAINT fk_grade_enrollment FOREIGN KEY (enrollment_id) REFERENCES enrollment(enrollment_id),
    CONSTRAINT fk_grade_faculty FOREIGN KEY (recorded_by_faculty_id) REFERENCES faculty(faculty_id),
    CONSTRAINT chk_grade_points CHECK (grade_points IS NULL OR (grade_points >= 0 AND grade_points <= 4.0))
);

-- Attendance table (1-M relationship with Enrollment)
CREATE TABLE attendance (
    attendance_id INT AUTO_INCREMENT PRIMARY KEY,
    enrollment_id INT NOT NULL,
    attendance_date DATE NOT NULL,
    status ENUM('Present', 'Absent', 'Late', 'Excused') NOT NULL,
    recorded_by_faculty_id INT NOT NULL,
    CONSTRAINT fk_attendance_enrollment FOREIGN KEY (enrollment_id) REFERENCES enrollment(enrollment_id),
    CONSTRAINT fk_attendance_faculty FOREIGN KEY (recorded_by_faculty_id) REFERENCES faculty(faculty_id),
    CONSTRAINT unique_attendance_record UNIQUE (enrollment_id, attendance_date)
);

-- Student payment table (1-M relationship with Students)
CREATE TABLE payment (
    payment_id INT AUTO_INCREMENT PRIMARY KEY,
    student_id INT NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    payment_date DATETIME NOT NULL,
    payment_method ENUM('Cash', 'Credit Card', 'Debit Card', 'Bank Transfer', 'Scholarship') NOT NULL,
    semester VARCHAR(20) NOT NULL,
    purpose VARCHAR(100),
    receipt_number VARCHAR(50) NOT NULL UNIQUE,
    processed_by_staff_id INT,
    CONSTRAINT fk_payment_student FOREIGN KEY (student_id) REFERENCES student(student_id),
    CONSTRAINT chk_payment_amount CHECK (amount > 0)
);

-- Audit log table to track important changes
CREATE TABLE audit_log (
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    table_name VARCHAR(50) NOT NULL,
    record_id INT NOT NULL,
    action ENUM('INSERT', 'UPDATE', 'DELETE') NOT NULL,
    action_time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    user_id INT,
    old_values JSON,
    new_values JSON
);

-- Create indexes for performance optimization
CREATE INDEX idx_student_name ON student(last_name, first_name);
CREATE INDEX idx_student_number ON student(student_number);
CREATE INDEX idx_student_department ON student(department_id);
CREATE INDEX idx_course_code ON course(course_code);
CREATE INDEX idx_course_department ON course(department_id);
CREATE INDEX idx_section_course ON section(course_id);
CREATE INDEX idx_section_term ON section(term_id);
CREATE INDEX idx_enrollment_student ON enrollment(student_id);
CREATE INDEX idx_enrollment_section ON enrollment(section_id);
CREATE INDEX idx_grade_enrollment ON grade(enrollment_id);
CREATE INDEX idx_attendance_enrollment ON attendance(enrollment_id);
CREATE INDEX idx_payment_student ON payment(student_id);
