# Job Portal — ISE 503 Database Project

A full-stack job portal web application built for ISE 503. Features a MySQL relational database, a Node.js/Express REST API backend, and a vanilla HTML/CSS/JS single-page frontend.

---

## Tech Stack

| Layer    | Technology                  |
|----------|-----------------------------|
| Frontend | HTML5, CSS3, Vanilla JS (SPA) |
| Backend  | Node.js, Express.js         |
| Database | MySQL 8.0+                  |

---

## Project Structure

```
Job Portal Project/
├── backend/
│   ├── server.js          # Express REST API (port 3000)
│   ├── db.js              # MySQL connection pool (reads from .env)
│   ├── .env.example       # Environment variable template
│   └── package.json
├── database/
│   └── job_portal_schema.sql  # Full schema + seed data
└── frontend/
    └── index.html         # Single-page application
```

---

## Getting Started

### Prerequisites

- Node.js (v18+)
- MySQL 8.0+

### 1. Set up the database

```bash
mysql -u root -p < database/job_portal_schema.sql
```

### 2. Configure environment variables

```bash
cp backend/.env.example backend/.env
```

Edit `backend/.env` and fill in your MySQL credentials:

```
DB_HOST=localhost
DB_USER=root
DB_PASSWORD=your_password_here
DB_NAME=job_portal
```

### 3. Install dependencies and start the backend

```bash
cd backend
npm install
node server.js
```

The API will be running at `http://localhost:3000`.

### 4. Open the frontend

Open `frontend/index.html` directly in your browser — no build step needed.

---

## API Endpoints

| Method | Endpoint                      | Description                        |
|--------|-------------------------------|------------------------------------|
| GET    | `/jobs`                       | List active jobs (supports `?search=`, `?type=`, `?remote=true`) |
| GET    | `/jobs/:id`                   | Job detail with required skills    |
| GET    | `/candidates`                 | List all candidates                |
| GET    | `/candidates/:id`             | Candidate detail with skills & applications |
| GET    | `/applications`               | All applications                   |
| POST   | `/applications`               | Submit a new application           |
| PATCH  | `/applications/:id/status`    | Update application status          |
| GET    | `/stats`                      | Dashboard stats (counts, top skills, status breakdown) |
| GET    | `/query/:id`                  | Run a named SQL query (`q1`–`q10`) |

---

## Database Schema

The schema includes the following tables:

- **Employer** — 30 companies
- **Job** — 34 active job postings with salary ranges and skill requirements
- **Candidate** — 35 job seekers with qualifications and experience
- **Employee** — Portal staff with supervisor hierarchy
- **Application** — Links candidates to jobs with status tracking
- **Skill** — 35+ skills across categories
- **Job_Skill** — Many-to-many: required/preferred skills per job
- **Candidate_Skill** — Many-to-many: candidate skills with proficiency levels

---

## Named SQL Queries (q1–q10)

Accessible via `GET /query/q1` through `GET /query/q10` and viewable in the SQL Explorer tab of the frontend.

| ID  | Description |
|-----|-------------|
| q1  | All active job listings with employer info |
| q2  | Jobs ranked by number of applications |
| q3  | Candidates with Python skills, sorted by proficiency |
| q4  | Average salary by job type |
| q5  | Candidates who have never applied to a job |
| q6  | Full application details (candidate + job + employer) |
| q7  | Jobs with above-average maximum salary (subquery) |
| q8  | Candidate count and average experience by qualification |
| q9  | Remote jobs with at least one application |
| q10 | Employee–supervisor hierarchy |
