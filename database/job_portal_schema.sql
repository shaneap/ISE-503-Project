-- ============================================================
--  ISE 503 · Spring 2026 · Course Project
--  Job Search Portal – Relational Schema + Seed Data (MySQL)
-- ============================================================

DROP DATABASE IF EXISTS job_portal;
CREATE DATABASE job_portal CHARACTER SET utf8mb4;
USE job_portal;

-- ─────────────────────────────────────────────
--  1. TABLES
-- ─────────────────────────────────────────────

CREATE TABLE Skill (
    skill_id      INT          PRIMARY KEY AUTO_INCREMENT,
    skill_name    VARCHAR(100) NOT NULL UNIQUE,
    category      VARCHAR(100) NOT NULL   -- e.g. 'Programming', 'Design', 'Management'
);

CREATE TABLE Employer (
    employer_id   INT          PRIMARY KEY AUTO_INCREMENT,
    company_name  VARCHAR(150) NOT NULL,
    ceo_name      VARCHAR(100),
    industry      VARCHAR(100),
    address       VARCHAR(255),
    city          VARCHAR(100),
    state         CHAR(2),
    zip           VARCHAR(10),
    website       VARCHAR(200)
);

CREATE TABLE Employee (
    employee_id   INT          PRIMARY KEY AUTO_INCREMENT,
    first_name    VARCHAR(80)  NOT NULL,
    last_name     VARCHAR(80)  NOT NULL,
    role          VARCHAR(100) NOT NULL,  -- e.g. 'Admin', 'Recruiter', 'Support'
    join_date     DATE         NOT NULL,
    supervisor_id INT,
    employer_id   INT,                    -- which company they work for (portal staff)
    CONSTRAINT fk_emp_supervisor FOREIGN KEY (supervisor_id) REFERENCES Employee(employee_id)
        ON DELETE SET NULL
);

CREATE TABLE Candidate (
    candidate_id  INT          PRIMARY KEY AUTO_INCREMENT,
    first_name    VARCHAR(80)  NOT NULL,
    last_name     VARCHAR(80)  NOT NULL,
    email         VARCHAR(150) NOT NULL UNIQUE,
    phone         VARCHAR(20),
    location      VARCHAR(150),
    qualification VARCHAR(100) NOT NULL,  -- e.g. 'Bachelor', 'Master', 'PhD', 'Associate'
    years_exp     DECIMAL(4,1) NOT NULL DEFAULT 0,
    resume_url    VARCHAR(300),
    created_at    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Many-to-many: a candidate can have many skills
CREATE TABLE Candidate_Skill (
    candidate_id  INT  NOT NULL,
    skill_id      INT  NOT NULL,
    proficiency   ENUM('Beginner','Intermediate','Advanced','Expert') NOT NULL DEFAULT 'Intermediate',
    PRIMARY KEY (candidate_id, skill_id),
    CONSTRAINT fk_cs_candidate FOREIGN KEY (candidate_id) REFERENCES Candidate(candidate_id) ON DELETE CASCADE,
    CONSTRAINT fk_cs_skill     FOREIGN KEY (skill_id)     REFERENCES Skill(skill_id)          ON DELETE CASCADE
);

CREATE TABLE Job (
    job_id        INT          PRIMARY KEY AUTO_INCREMENT,
    employer_id   INT          NOT NULL,
    posted_by     INT,                    -- Employee who posted the job
    title         VARCHAR(150) NOT NULL,
    description   TEXT,
    job_type      ENUM('Full-Time','Part-Time','Contract','Internship') NOT NULL DEFAULT 'Full-Time',
    salary_min    DECIMAL(10,2),
    salary_max    DECIMAL(10,2),
    location      VARCHAR(150),
    remote_ok     BOOLEAN      NOT NULL DEFAULT FALSE,
    posted_date   DATE         NOT NULL,
    deadline      DATE,
    is_active     BOOLEAN      NOT NULL DEFAULT TRUE,
    CONSTRAINT fk_job_employer  FOREIGN KEY (employer_id) REFERENCES Employer(employer_id) ON DELETE CASCADE,
    CONSTRAINT fk_job_posted_by FOREIGN KEY (posted_by)   REFERENCES Employee(employee_id)  ON DELETE SET NULL,
    CONSTRAINT chk_salary       CHECK (salary_max IS NULL OR salary_max >= salary_min)
);

-- Many-to-many: a job can require many skills
CREATE TABLE Job_Skill (
    job_id        INT  NOT NULL,
    skill_id      INT  NOT NULL,
    is_required   BOOLEAN NOT NULL DEFAULT TRUE,
    PRIMARY KEY (job_id, skill_id),
    CONSTRAINT fk_js_job   FOREIGN KEY (job_id)   REFERENCES Job(job_id)    ON DELETE CASCADE,
    CONSTRAINT fk_js_skill FOREIGN KEY (skill_id) REFERENCES Skill(skill_id) ON DELETE CASCADE
);

CREATE TABLE Application (
    application_id  INT      PRIMARY KEY AUTO_INCREMENT,
    candidate_id    INT      NOT NULL,
    job_id          INT      NOT NULL,
    applied_date    DATE     NOT NULL,
    status          ENUM('Submitted','Under Review','Interview Scheduled','Offer Extended','Rejected','Withdrawn')
                             NOT NULL DEFAULT 'Submitted',
    cover_letter    TEXT,
    reviewed_by     INT,     -- Employee who reviewed
    CONSTRAINT fk_app_candidate  FOREIGN KEY (candidate_id) REFERENCES Candidate(candidate_id) ON DELETE CASCADE,
    CONSTRAINT fk_app_job        FOREIGN KEY (job_id)        REFERENCES Job(job_id)             ON DELETE CASCADE,
    CONSTRAINT fk_app_reviewed   FOREIGN KEY (reviewed_by)   REFERENCES Employee(employee_id)   ON DELETE SET NULL,
    CONSTRAINT uq_app            UNIQUE (candidate_id, job_id)  -- one application per job per candidate
);

-- ─────────────────────────────────────────────
--  2. SEED DATA  (30+ rows per major table)
-- ─────────────────────────────────────────────

-- SKILLS (35 rows)
INSERT INTO Skill (skill_name, category) VALUES
('Python',           'Programming'),
('Java',             'Programming'),
('JavaScript',       'Programming'),
('SQL',              'Database'),
('C++',              'Programming'),
('R',                'Data Science'),
('Machine Learning', 'Data Science'),
('Deep Learning',    'Data Science'),
('Data Analysis',    'Data Science'),
('Tableau',          'Analytics'),
('Power BI',         'Analytics'),
('Excel',            'Analytics'),
('Project Management','Management'),
('Agile/Scrum',      'Management'),
('Leadership',       'Management'),
('Communication',    'Soft Skills'),
('Problem Solving',  'Soft Skills'),
('Teamwork',         'Soft Skills'),
('React',            'Web Development'),
('Node.js',          'Web Development'),
('HTML/CSS',         'Web Development'),
('AWS',              'Cloud'),
('Azure',            'Cloud'),
('Google Cloud',     'Cloud'),
('Docker',           'DevOps'),
('Kubernetes',       'DevOps'),
('CI/CD',            'DevOps'),
('Cybersecurity',    'Security'),
('Network Admin',    'IT'),
('Database Design',  'Database'),
('MongoDB',          'Database'),
('PostgreSQL',       'Database'),
('Graphic Design',   'Design'),
('UI/UX Design',     'Design'),
('Content Writing',  'Marketing');

-- EMPLOYERS (30 rows)
INSERT INTO Employer (company_name, ceo_name, industry, address, city, state, zip, website) VALUES
('TechNova Inc.',        'Sandra Patel',    'Technology',     '100 Silicon Ave',      'San Jose',       'CA','95101','www.technova.io'),
('BlueBridge Analytics', 'Marcus Liu',      'Analytics',      '220 Data Dr',          'Austin',         'TX','73301','www.bluebridge.com'),
('CloudSphere LLC',      'Olivia Chen',     'Cloud Services', '45 Cloud Way',         'Seattle',        'WA','98101','www.cloudsphere.net'),
('FinEdge Corp',         'David Okonkwo',   'Finance',        '1 Wall Street Pl',     'New York',       'NY','10005','www.finedge.com'),
('HealthSync',           'Priya Nair',      'Healthcare IT',  '300 Wellness Blvd',    'Boston',         'MA','02101','www.healthsync.org'),
('RetailPlus',           'Tom Harrington',  'Retail',         '55 Commerce Ct',       'Chicago',        'IL','60601','www.retailplus.com'),
('GreenLogix',           'Aisha Kone',      'Logistics',      '700 Green Pkwy',       'Denver',         'CO','80201','www.greenlogix.co'),
('MediaWave',            'Carlos Ruiz',     'Media',          '18 Broadcast Ln',      'Los Angeles',    'CA','90001','www.mediawave.tv'),
('EduTech Solutions',    'Nancy Bloom',     'Education',      '90 Campus Dr',         'Ann Arbor',      'MI','48101','www.edutechsol.com'),
('AutoDrive Systems',    'Raj Mehta',       'Automotive',     '500 Motor Mile',       'Detroit',        'MI','48201','www.autodrive.ai'),
('CyberShield Inc.',     'Helen Cross',     'Cybersecurity',  '22 Firewall Rd',       'Washington',     'DC','20001','www.cybershield.us'),
('DataBridge Co.',       'Samuel Torres',   'Data Services',  '88 Pipeline St',       'Atlanta',        'GA','30301','www.databridge.io'),
('SkyPath Aviation',     'Monica West',     'Aviation',       '1 Runway Ave',         'Dallas',         'TX','75201','www.skypath.aero'),
('NovaBuild Const.',     'Arthur Kim',      'Construction',   '400 Foundation Blvd',  'Phoenix',        'AZ','85001','www.novabuild.com'),
('LegalEdge LLP',        'Diana Shah',      'Legal Services', '200 Justice Way',      'Houston',        'TX','77001','www.legaledge.law'),
('BioGen Research',      'Elton Grant',     'Biotechnology',  '5 Lab Circle',         'San Diego',      'CA','92101','www.biogen.bio'),
('SmartHome Tech',       'Irene Castillo',  'IoT/Smart Home', '33 Connected Dr',      'Portland',       'OR','97201','www.smarthometech.net'),
('UrbanDesign Studio',   'Frank Osei',      'Architecture',   '12 Blueprint Ln',      'Miami',          'FL','33101','www.urbandesign.studio'),
('PayStream',            'Grace Liu',       'Fintech',        '9 Transaction Blvd',   'San Francisco',  'CA','94101','www.paystream.fi'),
('TravelSmart',          'Henry Park',      'Travel/Tourism', '3 Departure Ct',       'Orlando',        'FL','32801','www.travelsmart.biz'),
('AgriNet',              'Isabelle Roy',    'Agriculture',    '100 Harvest Rd',       'Des Moines',     'IA','50301','www.agrinet.farm'),
('ClearAir Energy',      'James Okafor',    'Renewable Energy','15 Solar Blvd',       'Phoenix',        'AZ','85002','www.clearair.energy'),
('SwiftDeliver',         'Karen Yeh',       'E-commerce',     '77 Package Ct',        'Louisville',     'KY','40201','www.swiftdeliver.com'),
('InnovateMed',          'Leo Baxter',      'MedTech',        '60 Pulse Dr',          'Minneapolis',    'MN','55401','www.innovatemed.health'),
('GlobalBrands',         'Mia Johnson',     'Marketing',      '14 Brand Ave',         'Nashville',      'TN','37201','www.globalbrands.mkt'),
('SecureVault',          'Nathan Diaz',     'Cybersecurity',  '8 Encryption Row',     'Raleigh',        'NC','27601','www.securevault.us'),
('EcoTextile Co.',       'Olivia Marsh',    'Manufacturing',  '2 Fabric Mill Rd',     'Charlotte',      'NC','28201','www.ecotextile.co'),
('QuantumLeap AI',       'Peter Solis',     'Artificial Intel','500 Neural Ave',      'Cambridge',      'MA','02139','www.quantumleap.ai'),
('HarborView Bank',      'Quinn Walsh',     'Banking',        '1 Harbor Sq',          'Providence',     'RI','02901','www.harborviewbank.com'),
('NexGen Robotics',      'Rachel Tan',      'Robotics',       '99 Servo Blvd',        'Pittsburgh',     'PA','15201','www.nexgenrobotics.com');

-- EMPLOYEES  (portal staff; 10 rows with supervisor chain)
INSERT INTO Employee (first_name, last_name, role, join_date, supervisor_id) VALUES
('Alice',   'Morgan',   'Admin',     '2019-03-01', NULL),
('Bob',     'Sanders',  'Admin',     '2020-06-15', 1),
('Carol',   'Zhang',    'Recruiter', '2021-01-10', 1),
('Dan',     'Patel',    'Recruiter', '2021-04-22', 2),
('Eve',     'Nguyen',   'Recruiter', '2022-02-14', 2),
('Frank',   'Obi',      'Support',   '2022-07-01', 3),
('Grace',   'Lin',      'Support',   '2023-01-05', 3),
('Henry',   'Brown',    'Recruiter', '2023-03-20', 4),
('Irene',   'Costa',    'Recruiter', '2023-08-11', 4),
('James',   'Wu',       'Support',   '2024-01-30', 5);

-- CANDIDATES (35 rows)
INSERT INTO Candidate (first_name, last_name, email, phone, location, qualification, years_exp) VALUES
('Liam',    'Harris',   'liam.harris@email.com',    '555-0101','New York, NY',      'Bachelor', 3.0),
('Sophia',  'Lee',      'sophia.lee@email.com',     '555-0102','San Jose, CA',      'Master',   5.0),
('Noah',    'Clark',    'noah.clark@email.com',     '555-0103','Austin, TX',        'Bachelor', 2.0),
('Emma',    'White',    'emma.white@email.com',     '555-0104','Seattle, WA',       'PhD',      7.0),
('Oliver',  'Hall',     'oliver.hall@email.com',    '555-0105','Boston, MA',        'Master',   4.0),
('Ava',     'Turner',   'ava.turner@email.com',     '555-0106','Chicago, IL',       'Bachelor', 1.5),
('Elijah',  'Scott',    'elijah.scott@email.com',   '555-0107','Denver, CO',        'Associate',1.0),
('Isabella','Adams',    'isabella.adams@email.com', '555-0108','Los Angeles, CA',   'Bachelor', 3.5),
('James',   'Baker',    'james.baker@email.com',    '555-0109','Miami, FL',         'Master',   6.0),
('Mia',     'Gonzalez', 'mia.gonzalez@email.com',   '555-0110','Dallas, TX',        'Bachelor', 2.5),
('Lucas',   'Nelson',   'lucas.nelson@email.com',   '555-0111','Atlanta, GA',       'Master',   4.5),
('Charlotte','Carter',  'charlotte.carter@email.com','555-0112','San Francisco, CA','PhD',      9.0),
('Henry',   'Mitchell', 'henry.mitchell@email.com', '555-0113','Portland, OR',      'Bachelor', 1.0),
('Amelia',  'Perez',    'amelia.perez@email.com',   '555-0114','Phoenix, AZ',       'Master',   3.0),
('Alexander','Roberts', 'alex.roberts@email.com',   '555-0115','Houston, TX',       'Bachelor', 2.0),
('Evelyn',  'Turner',   'evelyn.turner@email.com',  '555-0116','Detroit, MI',       'Associate',0.5),
('Daniel',  'Phillips', 'daniel.phillips@email.com','555-0117','Washington, DC',    'Master',   5.5),
('Harper',  'Campbell', 'harper.campbell@email.com','555-0118','Minneapolis, MN',   'Bachelor', 3.0),
('Jackson', 'Parker',   'jackson.parker@email.com', '555-0119','Nashville, TN',     'Master',   6.5),
('Scarlett','Evans',    'scarlett.evans@email.com', '555-0120','Raleigh, NC',       'Bachelor', 2.0),
('Aiden',   'Edwards',  'aiden.edwards@email.com',  '555-0121','Charlotte, NC',     'Master',   4.0),
('Luna',    'Collins',  'luna.collins@email.com',   '555-0122','Cambridge, MA',     'PhD',      8.0),
('Owen',    'Stewart',  'owen.stewart@email.com',   '555-0123','Providence, RI',    'Bachelor', 1.5),
('Penelope','Sanchez',  'penelope.sanchez@email.com','555-0124','Pittsburgh, PA',   'Master',   3.5),
('Wyatt',   'Morris',   'wyatt.morris@email.com',   '555-0125','Louisville, KY',    'Bachelor', 2.5),
('Layla',   'Rogers',   'layla.rogers@email.com',   '555-0126','Des Moines, IA',    'Associate',1.0),
('Gabriel', 'Reed',     'gabriel.reed@email.com',   '555-0127','Orlando, FL',       'Bachelor', 4.0),
('Zoe',     'Cook',     'zoe.cook@email.com',       '555-0128','San Diego, CA',     'Master',   5.0),
('Carter',  'Morgan',   'carter.morgan@email.com',  '555-0129','Ann Arbor, MI',     'Bachelor', 2.0),
('Nora',    'Bell',     'nora.bell@email.com',      '555-0130','Boston, MA',        'Master',   3.5),
('Eli',     'Murphy',   'eli.murphy@email.com',     '555-0131','Seattle, WA',       'PhD',      10.0),
('Hannah',  'Bailey',   'hannah.bailey@email.com',  '555-0132','Austin, TX',        'Bachelor', 1.5),
('Logan',   'Rivera',   'logan.rivera@email.com',   '555-0133','New York, NY',      'Master',   6.0),
('Stella',  'Cooper',   'stella.cooper@email.com',  '555-0134','Chicago, IL',       'Bachelor', 2.5),
('Levi',    'Richardson','levi.richardson@email.com','555-0135','Dallas, TX',       'Master',   4.0);

-- CANDIDATE_SKILL  (representative subset — ~70 rows)
INSERT INTO Candidate_Skill (candidate_id, skill_id, proficiency) VALUES
(1,1,'Advanced'),(1,4,'Intermediate'),(1,7,'Intermediate'),
(2,7,'Expert'),(2,8,'Advanced'),(2,6,'Advanced'),(2,4,'Expert'),
(3,2,'Intermediate'),(3,18,'Intermediate'),(3,14,'Beginner'),
(4,1,'Expert'),(4,7,'Expert'),(4,8,'Expert'),(4,30,'Advanced'),
(5,19,'Advanced'),(5,20,'Advanced'),(5,21,'Intermediate'),(5,22,'Intermediate'),
(6,33,'Advanced'),(6,34,'Advanced'),(6,21,'Intermediate'),
(7,16,'Intermediate'),(7,17,'Intermediate'),(7,18,'Advanced'),
(8,10,'Advanced'),(8,11,'Intermediate'),(8,9,'Advanced'),
(9,13,'Expert'),(9,14,'Expert'),(9,15,'Advanced'),
(10,3,'Advanced'),(10,19,'Intermediate'),(10,21,'Intermediate'),
(11,4,'Advanced'),(11,30,'Expert'),(11,31,'Intermediate'),(11,32,'Intermediate'),
(12,1,'Expert'),(12,7,'Expert'),(12,6,'Expert'),(12,28,'Advanced'),
(13,21,'Beginner'),(13,3,'Beginner'),(13,16,'Intermediate'),
(14,2,'Advanced'),(14,5,'Intermediate'),(14,27,'Intermediate'),
(15,25,'Advanced'),(15,26,'Intermediate'),(15,27,'Advanced'),
(16,16,'Beginner'),(16,18,'Beginner'),
(17,28,'Advanced'),(17,29,'Intermediate'),(17,12,'Intermediate'),
(18,13,'Intermediate'),(18,14,'Intermediate'),(18,16,'Advanced'),
(19,9,'Expert'),(19,10,'Expert'),(19,12,'Advanced'),
(20,34,'Intermediate'),(20,35,'Intermediate'),(20,21,'Beginner'),
(21,22,'Advanced'),(21,23,'Advanced'),(21,24,'Intermediate'),
(22,1,'Expert'),(22,7,'Expert'),(22,8,'Expert'),(22,30,'Expert'),
(23,4,'Intermediate'),(23,12,'Beginner'),
(24,6,'Advanced'),(24,9,'Advanced'),(24,10,'Intermediate'),
(25,25,'Advanced'),(25,26,'Advanced'),
(26,16,'Intermediate'),(26,18,'Intermediate'),
(27,3,'Advanced'),(27,19,'Intermediate'),(27,20,'Intermediate'),
(28,1,'Expert'),(28,31,'Advanced'),(28,4,'Advanced'),
(29,2,'Advanced'),(29,5,'Advanced'),(29,27,'Intermediate'),
(30,7,'Advanced'),(30,8,'Intermediate'),(30,9,'Advanced'),
(31,1,'Expert'),(31,7,'Expert'),(31,8,'Expert'),(31,22,'Expert'),
(32,16,'Intermediate'),(32,18,'Intermediate'),(32,21,'Beginner'),
(33,9,'Advanced'),(33,13,'Advanced'),(33,14,'Advanced'),
(34,33,'Advanced'),(34,34,'Advanced'),
(35,4,'Advanced'),(35,30,'Advanced'),(35,32,'Intermediate');

-- JOBS (35 rows)
INSERT INTO Job (employer_id, posted_by, title, description, job_type, salary_min, salary_max, location, remote_ok, posted_date, deadline) VALUES
(1, 3,'Data Scientist','Build ML models for product analytics.','Full-Time',110000,145000,'San Jose, CA',TRUE,'2026-02-01','2026-05-31'),
(1, 3,'Backend Engineer','Design REST APIs using Python/Django.','Full-Time',105000,135000,'San Jose, CA',FALSE,'2026-02-05','2026-05-31'),
(2, 4,'Analytics Engineer','Transform data pipelines in dbt and SQL.','Full-Time',95000,125000,'Austin, TX',TRUE,'2026-02-10','2026-06-01'),
(3, 5,'Cloud Architect','Design multi-cloud infrastructure on AWS/Azure.','Full-Time',130000,170000,'Seattle, WA',TRUE,'2026-02-12','2026-05-30'),
(4, 3,'Financial Analyst','Analyze market trends and investment data.','Full-Time',80000,105000,'New York, NY',FALSE,'2026-02-15','2026-05-15'),
(5, 4,'Health IT Consultant','Implement EHR systems at hospital sites.','Contract',90000,115000,'Boston, MA',FALSE,'2026-02-18','2026-06-15'),
(6, 5,'E-Commerce Manager','Oversee online storefront and promotions.','Full-Time',75000,95000,'Chicago, IL',FALSE,'2026-02-20','2026-05-20'),
(7, 3,'Logistics Coordinator','Optimize last-mile delivery routes.','Full-Time',65000,85000,'Denver, CO',FALSE,'2026-02-22','2026-05-25'),
(8, 4,'Content Strategist','Plan and produce digital media content.','Full-Time',60000,80000,'Los Angeles, CA',TRUE,'2026-02-25','2026-06-01'),
(9, 5,'Instructional Designer','Design eLearning modules and curricula.','Part-Time',45000,65000,'Ann Arbor, MI',TRUE,'2026-03-01','2026-06-30'),
(10,3,'Autonomous Systems Engineer','Develop perception stack for self-driving.','Full-Time',140000,180000,'Detroit, MI',FALSE,'2026-03-02','2026-05-31'),
(11,4,'Security Analyst','Monitor SIEM and respond to incidents.','Full-Time',100000,130000,'Washington, DC',FALSE,'2026-03-05','2026-06-05'),
(12,5,'Data Engineer','Build ETL pipelines with Spark and Kafka.','Full-Time',105000,135000,'Atlanta, GA',TRUE,'2026-03-08','2026-06-08'),
(13,3,'Operations Analyst','Improve flight scheduling efficiency.','Full-Time',70000,90000,'Dallas, TX',FALSE,'2026-03-10','2026-06-10'),
(14,4,'Site Engineer','Supervise residential construction projects.','Full-Time',72000,92000,'Phoenix, AZ',FALSE,'2026-03-12','2026-06-12'),
(15,5,'Paralegal','Draft legal documents and support attorneys.','Full-Time',55000,70000,'Houston, TX',FALSE,'2026-03-15','2026-06-15'),
(16,3,'Research Scientist','Conduct genomics research and analysis.','Full-Time',120000,155000,'San Diego, CA',FALSE,'2026-03-17','2026-06-17'),
(17,4,'IoT Developer','Build firmware for smart home devices.','Full-Time',95000,125000,'Portland, OR',TRUE,'2026-03-19','2026-06-19'),
(18,5,'UX Designer','Lead user research and interface design.','Full-Time',90000,115000,'Miami, FL',TRUE,'2026-03-20','2026-06-20'),
(19,3,'Software Engineer - Payments','Build payment processing microservices.','Full-Time',120000,155000,'San Francisco, CA',TRUE,'2026-03-22','2026-06-22'),
(20,4,'Travel Operations Specialist','Coordinate tour packages and logistics.','Full-Time',55000,72000,'Orlando, FL',FALSE,'2026-03-24','2026-06-24'),
(21,5,'Data Analyst – AgriTech','Analyze crop yield and sensor data.','Full-Time',65000,85000,'Des Moines, IA',FALSE,'2026-03-25','2026-06-25'),
(22,3,'Solar Energy Engineer','Design PV systems and grid integration.','Full-Time',85000,110000,'Phoenix, AZ',FALSE,'2026-03-26','2026-06-26'),
(23,4,'Warehouse Automation Lead','Deploy robotics for fulfillment centers.','Full-Time',95000,125000,'Louisville, KY',FALSE,'2026-03-27','2026-06-27'),
(24,5,'Clinical Data Analyst','Analyze trial data to support FDA submissions.','Full-Time',100000,130000,'Minneapolis, MN',FALSE,'2026-03-28','2026-06-28'),
(25,3,'Digital Marketing Manager','Drive SEO, SEM, and social campaigns.','Full-Time',80000,105000,'Nashville, TN',TRUE,'2026-03-29','2026-06-29'),
(26,4,'Penetration Tester','Conduct ethical hacking engagements.','Contract',110000,145000,'Raleigh, NC',TRUE,'2026-03-30','2026-06-30'),
(27,5,'Textile Production Analyst','Monitor sustainable manufacturing KPIs.','Full-Time',58000,75000,'Charlotte, NC',FALSE,'2026-04-01','2026-07-01'),
(28,3,'ML Research Engineer','Publish and implement cutting-edge AI models.','Full-Time',145000,190000,'Cambridge, MA',FALSE,'2026-04-02','2026-07-02'),
(29,4,'Loan Processing Officer','Review mortgage applications and documentation.','Full-Time',62000,80000,'Providence, RI',FALSE,'2026-04-03','2026-07-03'),
(30,5,'Robotics Software Engineer','Program ROS-based industrial arms.','Full-Time',125000,160000,'Pittsburgh, PA',FALSE,'2026-04-04','2026-07-04'),
(2, 3,'Junior Data Analyst','Entry-level analytics with Tableau/Power BI.','Full-Time',60000,78000,'Austin, TX',TRUE,'2026-04-05','2026-07-05'),
(1, 4,'DevOps Engineer','Manage CI/CD pipelines and Kubernetes clusters.','Full-Time',115000,145000,'San Jose, CA',TRUE,'2026-04-06','2026-07-06'),
(11,5,'Cloud Security Engineer','Protect cloud workloads on AWS/Azure.','Full-Time',120000,155000,'Washington, DC',TRUE,'2026-04-07','2026-07-07'),
(28,3,'NLP Engineer','Build large language model applications.','Full-Time',150000,195000,'Cambridge, MA',FALSE,'2026-04-08','2026-07-08');

-- JOB_SKILL  (required skills per job)
INSERT INTO Job_Skill (job_id, skill_id, is_required) VALUES
(1,1,TRUE),(1,7,TRUE),(1,8,FALSE),(1,4,TRUE),
(2,1,TRUE),(2,4,TRUE),
(3,4,TRUE),(3,9,TRUE),(3,10,FALSE),
(4,22,TRUE),(4,23,TRUE),(4,24,FALSE),
(5,9,TRUE),(5,12,TRUE),
(6,6,FALSE),(6,9,TRUE),(6,12,TRUE),
(7,13,TRUE),(7,14,FALSE),
(8,16,TRUE),(8,35,TRUE),
(9,16,TRUE),(9,17,TRUE),
(10,5,TRUE),(10,7,TRUE),(10,8,TRUE),
(11,28,TRUE),(11,29,TRUE),
(12,1,TRUE),(12,4,TRUE),(12,30,FALSE),
(13,9,TRUE),(13,12,TRUE),
(14,13,TRUE),(14,17,TRUE),
(15,16,TRUE),(15,18,TRUE),
(16,1,TRUE),(16,6,TRUE),(16,7,FALSE),
(17,2,TRUE),(17,5,FALSE),
(18,33,FALSE),(18,34,TRUE),
(19,1,TRUE),(19,19,FALSE),(19,20,TRUE),
(20,13,TRUE),(20,16,TRUE),
(21,9,TRUE),(21,1,FALSE),(21,10,TRUE),
(22,9,TRUE),(22,12,FALSE),
(23,25,TRUE),(23,26,FALSE),
(24,6,TRUE),(24,9,TRUE),(24,12,FALSE),
(25,35,TRUE),(25,16,FALSE),
(26,28,TRUE),(26,29,TRUE),
(27,9,TRUE),(27,12,FALSE),
(28,1,TRUE),(28,7,TRUE),(28,8,TRUE),(28,31,FALSE),
(29,12,TRUE),(29,16,TRUE),
(30,2,TRUE),(30,5,TRUE),(30,27,FALSE),
(31,9,TRUE),(31,10,TRUE),(31,11,TRUE),
(32,25,TRUE),(32,26,TRUE),(32,27,TRUE),
(33,22,TRUE),(33,28,TRUE),(33,24,FALSE),
(34,1,TRUE),(34,7,TRUE),(34,8,TRUE);

-- APPLICATIONS (40 rows)
INSERT INTO Application (candidate_id, job_id, applied_date, status, reviewed_by) VALUES
(1,  1, '2026-02-15','Under Review',      3),
(2,  1, '2026-02-16','Interview Scheduled',3),
(4,  1, '2026-02-17','Offer Extended',     3),
(22, 1, '2026-02-20','Submitted',          NULL),
(31, 1, '2026-02-21','Submitted',          NULL),
(2,  3, '2026-02-18','Under Review',       4),
(11, 3, '2026-02-19','Interview Scheduled',4),
(5, 4, '2026-02-20','Under Review',        5),
(10, 9, '2026-03-05','Submitted',          NULL),
(6,  9, '2026-03-06','Rejected',           3),
(9, 7,  '2026-03-01','Under Review',       4),
(18,7,  '2026-03-02','Interview Scheduled',4),
(7, 8,  '2026-03-03','Submitted',          NULL),
(20,8,  '2026-03-04','Under Review',       5),
(12, 1, '2026-02-22','Rejected',           3),
(3, 2,  '2026-02-25','Submitted',          NULL),
(14,2,  '2026-02-26','Under Review',       4),
(29,2,  '2026-02-27','Interview Scheduled',4),
(15,32, '2026-04-10','Submitted',          NULL),
(25,33, '2026-04-12','Under Review',       5),
(21,33, '2026-04-13','Submitted',          NULL),
(4, 28, '2026-04-05','Interview Scheduled',3),
(22,28, '2026-04-06','Under Review',       3),
(31,28, '2026-04-07','Offer Extended',     3),
(30,30, '2026-04-10','Submitted',          NULL),
(24,30, '2026-04-11','Under Review',       4),
(17,11, '2026-03-10','Interview Scheduled',5),
(12,11, '2026-03-11','Withdrawn',          5),
(8, 5,  '2026-02-25','Under Review',       3),
(5, 19, '2026-03-25','Submitted',          NULL),
(27,19, '2026-03-26','Under Review',       4),
(33,6,  '2026-03-01','Interview Scheduled',5),
(19,6,  '2026-03-02','Under Review',       5),
(28, 12,'2026-03-12','Offer Extended',     3),
(13,31, '2026-04-06','Submitted',          NULL),
(23,29, '2026-04-05','Submitted',          NULL),
(35,3,  '2026-02-15','Interview Scheduled',4),
(11,12, '2026-03-14','Submitted',          NULL),
(26,8,  '2026-03-05','Rejected',           5),
(16,20, '2026-03-25','Submitted',          NULL);


-- ─────────────────────────────────────────────
--  3. 10 SQL QUERIES
-- ─────────────────────────────────────────────

-- Q1: List all active jobs with employer info
--     Concept: Basic JOIN, WHERE, ORDER BY
SELECT  j.title, j.job_type, j.salary_min, j.salary_max,
        e.company_name, e.industry, e.city
FROM    Job j
JOIN    Employer e ON e.employer_id = j.employer_id
WHERE   j.is_active = TRUE
ORDER BY j.posted_date DESC;

-- Q2: Count applications per job (including jobs with zero applications)
--     Concept: LEFT JOIN, GROUP BY, COUNT, aggregate ordering
SELECT  j.title, e.company_name,
        COUNT(a.application_id) AS total_applications
FROM    Job j
JOIN    Employer      e ON e.employer_id = j.employer_id
LEFT JOIN Application a ON a.job_id      = j.job_id
GROUP BY j.job_id, j.title, e.company_name
ORDER BY total_applications DESC;

-- Q3: Find all candidates who have a specific skill (Python)
--     Concept: Three-table JOIN, WHERE on a non-key column
SELECT  c.first_name, c.last_name, c.qualification,
        s.skill_name, cs.proficiency
FROM    Candidate c
JOIN    Candidate_Skill cs ON cs.candidate_id = c.candidate_id
JOIN    Skill           s  ON s.skill_id      = cs.skill_id
WHERE   s.skill_name = 'Python'
ORDER BY cs.proficiency DESC;

-- Q4: Show average salary by job type
--     Concept: AVG, ROUND, GROUP BY on a single table
SELECT  job_type,
        COUNT(*)                   AS total_jobs,
        ROUND(AVG(salary_min), 0)  AS avg_min_salary,
        ROUND(AVG(salary_max), 0)  AS avg_max_salary
FROM    Job
WHERE   salary_min IS NOT NULL
GROUP BY job_type
ORDER BY avg_max_salary DESC;

-- Q5: List candidates who have NOT applied to any job
--     Concept: LEFT JOIN anti-join pattern (NULL check)
SELECT  c.first_name, c.last_name, c.email,
        c.qualification, c.years_exp
FROM    Candidate c
LEFT JOIN Application a ON a.candidate_id = c.candidate_id
WHERE   a.application_id IS NULL
ORDER BY c.years_exp DESC;

-- Q6: All applications with full candidate and job details
--     Concept: Four-table JOIN
SELECT  a.application_id, a.applied_date, a.status,
        c.first_name, c.last_name, c.qualification,
        j.title AS job_title, e.company_name,
        j.salary_min, j.salary_max
FROM    Application a
JOIN    Candidate c ON c.candidate_id = a.candidate_id
JOIN    Job       j ON j.job_id       = a.job_id
JOIN    Employer  e ON e.employer_id  = j.employer_id
ORDER BY a.applied_date DESC;

-- Q7: Jobs offering above-average salary
--     Concept: Scalar subquery in WHERE clause
SELECT  j.title, e.company_name, j.salary_max, j.job_type
FROM    Job j
JOIN    Employer e ON e.employer_id = j.employer_id
WHERE   j.salary_max > (
            SELECT AVG(salary_max) FROM Job WHERE salary_max IS NOT NULL
        )
ORDER BY j.salary_max DESC;

-- Q8: Count candidates per qualification level with average experience
--     Concept: GROUP BY with multiple aggregate functions
SELECT  qualification,
        COUNT(*)                    AS total_candidates,
        ROUND(AVG(years_exp), 1)    AS avg_experience
FROM    Candidate
GROUP BY qualification
ORDER BY avg_experience DESC;

-- Q9: Remote jobs that received at least one application
--     Concept: WHERE + GROUP BY + HAVING (showing the difference)
SELECT  j.title, e.company_name, j.location,
        COUNT(a.application_id) AS applications
FROM    Job j
JOIN    Employer      e ON e.employer_id = j.employer_id
LEFT JOIN Application a ON a.job_id      = j.job_id
WHERE   j.remote_ok = TRUE
GROUP BY j.job_id, j.title, e.company_name, j.location
HAVING  COUNT(a.application_id) >= 1
ORDER BY applications DESC;

-- Q10: List all employees alongside their supervisor's name
--      Concept: Self-JOIN on the same table
SELECT  e.first_name                              AS employee_first,
        e.last_name                               AS employee_last,
        e.role, e.join_date,
        CONCAT(s.first_name, ' ', s.last_name)    AS supervisor_name
FROM    Employee e
LEFT JOIN Employee s ON s.employee_id = e.supervisor_id
ORDER BY s.last_name, e.last_name;