-- Core V1 queries. Run after schema.sql + seed.sql in the selected database.
SET NAMES utf8mb4;
SET SESSION time_zone = '+00:00';
SET @project_id=1, @run_id=101, @case_id=101, @assignee_id=6;

-- Q1: Requirement coverage; no duplicate numerator from N:M links.
SELECT COUNT(*) AS active_requirements,
       COALESCE(SUM(EXISTS (
         SELECT 1 FROM test_case_requirements tr
         JOIN test_cases tc ON tc.id=tr.test_case_id
         WHERE tr.requirement_id=r.id AND tr.status='CONFIRMED'
           AND tc.status='READY' AND tc.project_id=r.project_id
       )),0) AS covered_requirements
FROM requirements r WHERE r.project_id=@project_id AND r.status='ACTIVE';

-- Q2: No current linked Case (REMOVED links do not count).
SELECT r.id,r.key_no,r.title FROM requirements r
WHERE r.project_id=@project_id AND r.status='ACTIVE'
  AND NOT EXISTS (SELECT 1 FROM test_case_requirements tr
                  WHERE tr.requirement_id=r.id AND tr.status<>'REMOVED')
ORDER BY r.key_no;

-- Q3: No effective coverage, including NEEDS_REVIEW.
SELECT r.id,r.key_no,r.title FROM requirements r
WHERE r.project_id=@project_id AND r.status='ACTIVE'
  AND NOT EXISTS (
    SELECT 1 FROM test_case_requirements tr JOIN test_cases tc ON tc.id=tr.test_case_id
    WHERE tr.requirement_id=r.id AND tr.status='CONFIRMED' AND tc.status='READY'
      AND tc.project_id=r.project_id)
ORDER BY r.key_no;

-- Q4: Current outcome for each RunCase, retaining zero-attempt items.
SELECT rc.id AS run_case_id,rc.test_case_id,rc.snapshot_title,
       a.attempt_no,COALESCE(a.status,'NOT_RUN') AS current_outcome
FROM test_run_cases rc JOIN test_runs run ON run.id=rc.test_run_id
LEFT JOIN test_attempts a ON a.test_run_case_id=rc.id
 AND a.attempt_no=(SELECT MAX(a2.attempt_no) FROM test_attempts a2 WHERE a2.test_run_case_id=rc.id)
WHERE run.project_id=@project_id AND run.id=@run_id ORDER BY rc.id;

-- Q5: Dashboard; blocked/skipped are recorded but not actual execution.
WITH latest AS (
 SELECT rc.id,COALESCE(a.status,'NOT_RUN') AS outcome
 FROM test_run_cases rc JOIN test_runs run ON run.id=rc.test_run_id
 LEFT JOIN test_attempts a ON a.test_run_case_id=rc.id
   AND a.attempt_no=(SELECT MAX(a2.attempt_no) FROM test_attempts a2 WHERE a2.test_run_case_id=rc.id)
 WHERE run.project_id=@project_id AND run.id=@run_id
), totals AS (
 SELECT COUNT(*) AS n,
 COALESCE(SUM(outcome='PASS'),0) AS p, COALESCE(SUM(outcome='FAIL'),0) AS f,
 COALESCE(SUM(outcome='BLOCKED'),0) AS b, COALESCE(SUM(outcome='SKIPPED'),0) AS s
 FROM latest
)
SELECT n,p,f,b,s,n-p-f-b-s AS not_run,p+f AS actually_executed,
 ROUND(100.0*p/NULLIF(p+f,0),2) AS pass_rate,
 ROUND(100.0*(p+f)/NULLIF(n,0),2) AS execution_rate,
 ROUND(100.0*(p+f+b+s)/NULLIF(n,0),2) AS recorded_rate
FROM totals;

-- Q6: Immutable FAIL evidence is still visible after a later PASS.
SELECT r.key_no AS requirement_no,tc.key_no AS case_no,run.id AS run_id,
 a.attempt_no,a.status,d.key_no AS defect_no,d.status AS defect_status,tr.status AS link_status
FROM requirements r JOIN test_case_requirements tr ON tr.requirement_id=r.id
JOIN test_cases tc ON tc.id=tr.test_case_id AND tc.project_id=r.project_id
JOIN test_run_cases rc ON rc.test_case_id=tc.id
JOIN test_runs run ON run.id=rc.test_run_id AND run.project_id=r.project_id
JOIN test_attempts a ON a.test_run_case_id=rc.id
JOIN test_attempt_defects ad ON ad.attempt_id=a.id
JOIN defects d ON d.id=ad.defect_id AND d.project_id=r.project_id
WHERE r.project_id=@project_id ORDER BY r.key_no,tc.key_no,run.id,a.attempt_no,d.key_no;

-- Q7: Project Run list directly uses mandatory Run ownership.
SELECT id,test_plan_id,name,status,created_at
FROM test_runs WHERE project_id=@project_id ORDER BY created_at DESC,id DESC;

-- Q8: Existing assignee work list (authorization is checked by Service).
SELECT id,key_no,title,status FROM defects
WHERE project_id=@project_id AND assignee_id=@assignee_id
 AND status IN ('OPEN','IN_PROGRESS','REOPENED') ORDER BY id;

-- Q9: Multiple implementations for a logical Case.
SELECT m.id,m.status,i.source,i.namespace,i.external_key
FROM test_automation_mappings m
JOIN test_automation_identities i ON i.id=m.automation_identity_id
JOIN test_cases tc ON tc.id=m.test_case_id
WHERE tc.project_id=@project_id AND i.project_id=@project_id AND tc.id=@case_id ORDER BY m.id;

-- Q10: Full attempt history is not counted as multiple RunCases.
SELECT a.id,a.attempt_no,a.status,a.executed_by,a.import_id,a.automation_mapping_id,a.comment
FROM test_attempts a JOIN test_run_cases rc ON rc.id=a.test_run_case_id
JOIN test_runs run ON run.id=rc.test_run_id
WHERE run.project_id=@project_id AND run.id=@run_id AND rc.test_case_id=@case_id
ORDER BY a.attempt_no;

-- E1/E2: Executed only against the small seed fixture; not a production benchmark.
EXPLAIN ANALYZE SELECT id,name,status FROM test_runs
WHERE project_id=1 ORDER BY created_at DESC,id DESC;
EXPLAIN ANALYZE SELECT * FROM test_attempts
WHERE test_run_case_id=101 ORDER BY attempt_no DESC LIMIT 1;
