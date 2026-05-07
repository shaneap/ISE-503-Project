// server.js — Job Portal Backend (Express + MySQL)
// Run with: node server.js

const express = require('express');
const cors    = require('cors');
const db      = require('./db');

const app  = express();
const PORT = 3000;

app.use(cors());
app.use(express.json());

// ─────────────────────────────────────────────
//  JOBS
// ─────────────────────────────────────────────

// GET /jobs — list all active jobs (with employer name)
// Optional query params: ?search=engineer  ?type=Full-Time  ?remote=true
app.get('/jobs', async (req, res) => {
  try {
    const { search, type, remote } = req.query;

    let sql = `
      SELECT  j.job_id, j.title, j.job_type, j.salary_min, j.salary_max,
              j.location, j.remote_ok, j.posted_date, j.deadline,
              e.company_name, e.industry
      FROM    Job j
      JOIN    Employer e ON e.employer_id = j.employer_id
      WHERE   j.is_active = TRUE
    `;
    const params = [];

    if (search) {
      sql += ` AND (j.title LIKE ? OR e.company_name LIKE ? OR e.industry LIKE ?)`;
      params.push(`%${search}%`, `%${search}%`, `%${search}%`);
    }
    if (type) {
      sql += ` AND j.job_type = ?`;
      params.push(type);
    }
    if (remote === 'true') {
      sql += ` AND j.remote_ok = TRUE`;
    }

    sql += ` ORDER BY j.posted_date DESC`;

    const [rows] = await db.query(sql, params);
    res.json(rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// GET /jobs/:id — single job detail with required skills
app.get('/jobs/:id', async (req, res) => {
  try {
    const [[job]] = await db.query(`
      SELECT  j.*, e.company_name, e.industry, e.city, e.state, e.website, e.ceo_name
      FROM    Job j JOIN Employer e ON e.employer_id = j.employer_id
      WHERE   j.job_id = ?`, [req.params.id]);

    if (!job) return res.status(404).json({ error: 'Job not found' });

    const [skills] = await db.query(`
      SELECT s.skill_name, s.category, js.is_required
      FROM   Job_Skill js JOIN Skill s ON s.skill_id = js.skill_id
      WHERE  js.job_id = ?`, [req.params.id]);

    const [appCount] = await db.query(
      `SELECT COUNT(*) AS total FROM Application WHERE job_id = ?`, [req.params.id]);

    res.json({ ...job, skills, applicant_count: appCount[0].total });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ─────────────────────────────────────────────
//  CANDIDATES
// ─────────────────────────────────────────────

// GET /candidates — list all candidates
app.get('/candidates', async (req, res) => {
  try {
    const [rows] = await db.query(`
      SELECT  c.candidate_id, c.first_name, c.last_name, c.email,
              c.location, c.qualification, c.years_exp,
              COUNT(a.application_id) AS total_applications
      FROM    Candidate c
      LEFT JOIN Application a ON a.candidate_id = c.candidate_id
      GROUP BY c.candidate_id
      ORDER BY c.last_name`);
    res.json(rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// GET /candidates/:id — single candidate with skills + applications
app.get('/candidates/:id', async (req, res) => {
  try {
    const [[candidate]] = await db.query(
      `SELECT * FROM Candidate WHERE candidate_id = ?`, [req.params.id]);
    if (!candidate) return res.status(404).json({ error: 'Candidate not found' });

    const [skills] = await db.query(`
      SELECT s.skill_name, s.category, cs.proficiency
      FROM   Candidate_Skill cs JOIN Skill s ON s.skill_id = cs.skill_id
      WHERE  cs.candidate_id = ?`, [req.params.id]);

    const [applications] = await db.query(`
      SELECT  a.application_id, a.applied_date, a.status,
              j.title, e.company_name
      FROM    Application a
      JOIN    Job      j ON j.job_id      = a.job_id
      JOIN    Employer e ON e.employer_id = j.employer_id
      WHERE   a.candidate_id = ?
      ORDER BY a.applied_date DESC`, [req.params.id]);

    res.json({ ...candidate, skills, applications });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ─────────────────────────────────────────────
//  APPLICATIONS
// ─────────────────────────────────────────────

// GET /applications — all applications with job + candidate info
app.get('/applications', async (req, res) => {
  try {
    const [rows] = await db.query(`
      SELECT  a.application_id, a.applied_date, a.status,
              c.first_name, c.last_name, c.email, c.qualification,
              j.title AS job_title, e.company_name,
              j.salary_min, j.salary_max
      FROM    Application a
      JOIN    Candidate c ON c.candidate_id = a.candidate_id
      JOIN    Job       j ON j.job_id       = a.job_id
      JOIN    Employer  e ON e.employer_id  = j.employer_id
      ORDER BY a.applied_date DESC`);
    res.json(rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// POST /applications — submit a new application
app.post('/applications', async (req, res) => {
  try {
    const { candidate_id, job_id, cover_letter } = req.body;
    if (!candidate_id || !job_id)
      return res.status(400).json({ error: 'candidate_id and job_id are required' });

    const today = new Date().toISOString().slice(0, 10);
    await db.query(`
      INSERT INTO Application (candidate_id, job_id, applied_date, status, cover_letter)
      VALUES (?, ?, ?, 'Submitted', ?)`,
      [candidate_id, job_id, today, cover_letter || null]);

    res.status(201).json({ message: 'Application submitted successfully!' });
  } catch (err) {
    if (err.code === 'ER_DUP_ENTRY')
      return res.status(409).json({ error: 'You have already applied for this job.' });
    res.status(500).json({ error: err.message });
  }
});

// PATCH /applications/:id/status — update application status
app.patch('/applications/:id/status', async (req, res) => {
  try {
    const { status } = req.body;
    const valid = ['Submitted','Under Review','Interview Scheduled','Offer Extended','Rejected','Withdrawn'];
    if (!valid.includes(status))
      return res.status(400).json({ error: 'Invalid status value' });

    await db.query(
      `UPDATE Application SET status = ? WHERE application_id = ?`,
      [status, req.params.id]);
    res.json({ message: 'Status updated' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ─────────────────────────────────────────────
//  STATS  (dashboard numbers)
// ─────────────────────────────────────────────

app.get('/stats', async (req, res) => {
  try {
    const [[{ total_jobs }]]        = await db.query(`SELECT COUNT(*) AS total_jobs FROM Job WHERE is_active = TRUE`);
    const [[{ total_candidates }]]  = await db.query(`SELECT COUNT(*) AS total_candidates FROM Candidate`);
    const [[{ total_employers }]]   = await db.query(`SELECT COUNT(*) AS total_employers FROM Employer`);
    const [[{ total_applications }]]= await db.query(`SELECT COUNT(*) AS total_applications FROM Application`);
    const [[{ total_offers }]]      = await db.query(`SELECT COUNT(*) AS total_offers FROM Application WHERE status = 'Offer Extended'`);

    const [topSkills] = await db.query(`
      SELECT s.skill_name, COUNT(js.job_id) AS demand
      FROM   Skill s JOIN Job_Skill js ON js.skill_id = s.skill_id AND js.is_required = TRUE
      JOIN   Job j ON j.job_id = js.job_id AND j.is_active = TRUE
      GROUP BY s.skill_id ORDER BY demand DESC LIMIT 5`);

    const [statusBreakdown] = await db.query(`
      SELECT status, COUNT(*) AS count FROM Application GROUP BY status`);

    res.json({ total_jobs, total_candidates, total_employers,
               total_applications, total_offers, topSkills, statusBreakdown });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ─────────────────────────────────────────────
//  SQL EXPLORER  — run any of the 10 named queries
// ─────────────────────────────────────────────

const QUERIES = {
  q1: `SELECT  j.title, j.job_type, j.salary_min, j.salary_max,
        e.company_name, e.industry, e.city
FROM    Job j
JOIN    Employer e ON e.employer_id = j.employer_id
WHERE   j.is_active = TRUE
ORDER BY j.posted_date DESC`,

  q2: `SELECT  j.title, e.company_name,
        COUNT(a.application_id) AS total_applications
FROM    Job j
JOIN    Employer      e ON e.employer_id = j.employer_id
LEFT JOIN Application a ON a.job_id      = j.job_id
GROUP BY j.job_id, j.title, e.company_name
ORDER BY total_applications DESC`,

  q3: `SELECT  c.first_name, c.last_name, c.qualification,
        s.skill_name, cs.proficiency
FROM    Candidate c
JOIN    Candidate_Skill cs ON cs.candidate_id = c.candidate_id
JOIN    Skill           s  ON s.skill_id      = cs.skill_id
WHERE   s.skill_name = 'Python'
ORDER BY cs.proficiency DESC`,

  q4: `SELECT  job_type,
        COUNT(*)                   AS total_jobs,
        ROUND(AVG(salary_min), 0)  AS avg_min_salary,
        ROUND(AVG(salary_max), 0)  AS avg_max_salary
FROM    Job
WHERE   salary_min IS NOT NULL
GROUP BY job_type
ORDER BY avg_max_salary DESC`,

  q5: `SELECT  c.first_name, c.last_name, c.email,
        c.qualification, c.years_exp
FROM    Candidate c
LEFT JOIN Application a ON a.candidate_id = c.candidate_id
WHERE   a.application_id IS NULL
ORDER BY c.years_exp DESC`,

  q6: `SELECT  a.application_id, a.applied_date, a.status,
        c.first_name, c.last_name, c.qualification,
        j.title AS job_title, e.company_name,
        j.salary_min, j.salary_max
FROM    Application a
JOIN    Candidate c ON c.candidate_id = a.candidate_id
JOIN    Job       j ON j.job_id       = a.job_id
JOIN    Employer  e ON e.employer_id  = j.employer_id
ORDER BY a.applied_date DESC`,

  q7: `SELECT  j.title, e.company_name, j.salary_max, j.job_type
FROM    Job j
JOIN    Employer e ON e.employer_id = j.employer_id
WHERE   j.salary_max > (
            SELECT AVG(salary_max) FROM Job WHERE salary_max IS NOT NULL
        )
ORDER BY j.salary_max DESC`,

  q8: `SELECT  qualification,
        COUNT(*)                    AS total_candidates,
        ROUND(AVG(years_exp), 1)    AS avg_experience
FROM    Candidate
GROUP BY qualification
ORDER BY avg_experience DESC`,

  q9: `SELECT  j.title, e.company_name, j.location,
        COUNT(a.application_id) AS applications
FROM    Job j
JOIN    Employer      e ON e.employer_id = j.employer_id
LEFT JOIN Application a ON a.job_id      = j.job_id
WHERE   j.remote_ok = TRUE
GROUP BY j.job_id, j.title, e.company_name, j.location
HAVING  COUNT(a.application_id) >= 1
ORDER BY applications DESC`,

  q10: `SELECT  e.first_name                              AS employee_first,
        e.last_name                               AS employee_last,
        e.role, e.join_date,
        CONCAT(s.first_name, ' ', s.last_name)    AS supervisor_name
FROM    Employee e
LEFT JOIN Employee s ON s.employee_id = e.supervisor_id
ORDER BY s.last_name, e.last_name`,
};

app.get('/query/:id', async (req, res) => {
  const sql = QUERIES[req.params.id];
  if (!sql) return res.status(404).json({ error: 'Query not found' });
  try {
    const [rows] = await db.query(sql);
    res.json({ sql, rows });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ─────────────────────────────────────────────
//  START
// ─────────────────────────────────────────────

app.listen(PORT, () => {
  console.log(`✅  Job Portal API running at http://localhost:${PORT}`);
  console.log(`    Endpoints:`);
  console.log(`      GET  /jobs            — list jobs`);
  console.log(`      GET  /jobs/:id        — job detail`);
  console.log(`      GET  /candidates      — list candidates`);
  console.log(`      GET  /candidates/:id  — candidate detail`);
  console.log(`      GET  /applications    — all applications`);
  console.log(`      POST /applications    — submit application`);
  console.log(`      GET  /stats           — dashboard stats`);
  console.log(`      GET  /query/:id       — run named query (q1–q10)`);
});