-- Read-only fixture consistency checks. Every violation_count must be zero.
-- Does not install triggers or make these rules database constraints.
SELECT 'requirement_case_project' AS rule_name, (SELECT COUNT(*) FROM test_case_requirements l JOIN requirements r ON r.id=l.requirement_id JOIN test_cases c ON c.id=l.test_case_id WHERE r.project_id<>c.project_id) AS violation_count
UNION ALL
SELECT 'plan_case_project' AS rule_name, (SELECT COUNT(*) FROM test_plan_cases l JOIN test_plans p ON p.id=l.test_plan_id JOIN test_cases c ON c.id=l.test_case_id WHERE p.project_id<>c.project_id) AS violation_count
UNION ALL
SELECT 'run_plan_project' AS rule_name, (SELECT COUNT(*) FROM test_runs r JOIN test_plans p ON p.id=r.test_plan_id WHERE r.project_id<>p.project_id) AS violation_count
UNION ALL
SELECT 'run_case_project' AS rule_name, (SELECT COUNT(*) FROM test_run_cases rc JOIN test_runs r ON r.id=rc.test_run_id JOIN test_cases c ON c.id=rc.test_case_id WHERE r.project_id<>c.project_id) AS violation_count
UNION ALL
SELECT 'mapping_project' AS rule_name, (SELECT COUNT(*) FROM test_automation_mappings m JOIN test_automation_identities i ON i.id=m.automation_identity_id JOIN test_cases c ON c.id=m.test_case_id WHERE i.project_id<>c.project_id) AS violation_count
UNION ALL
SELECT 'attempt_import_run' AS rule_name, (SELECT COUNT(*) FROM test_attempts a JOIN test_imports i ON i.id=a.import_id JOIN test_run_cases rc ON rc.id=a.test_run_case_id WHERE i.test_run_id<>rc.test_run_id) AS violation_count
UNION ALL
SELECT 'attempt_mapping_case' AS rule_name, (SELECT COUNT(*) FROM test_attempts a JOIN test_automation_mappings m ON m.id=a.automation_mapping_id JOIN test_run_cases rc ON rc.id=a.test_run_case_id WHERE m.test_case_id<>rc.test_case_id) AS violation_count
UNION ALL
SELECT 'attempt_namespace' AS rule_name, (SELECT COUNT(*) FROM test_attempts a JOIN test_imports b ON b.id=a.import_id JOIN test_automation_mappings m ON m.id=a.automation_mapping_id JOIN test_automation_identities i ON i.id=m.automation_identity_id WHERE b.source_namespace<>i.namespace OR i.source<>'JUNIT') AS violation_count
UNION ALL
SELECT 'single_implementation_per_run_case' AS rule_name, (SELECT COUNT(*) FROM (SELECT test_run_case_id FROM test_attempts WHERE automation_mapping_id IS NOT NULL GROUP BY test_run_case_id HAVING COUNT(DISTINCT automation_mapping_id)>1) violations) AS violation_count
UNION ALL
SELECT 'defect_evidence_project' AS rule_name, (SELECT COUNT(*) FROM test_attempt_defects l JOIN test_attempts a ON a.id=l.attempt_id JOIN test_run_cases rc ON rc.id=a.test_run_case_id JOIN test_runs r ON r.id=rc.test_run_id JOIN defects d ON d.id=l.defect_id WHERE d.project_id<>r.project_id) AS violation_count
UNION ALL
SELECT 'defect_evidence_fail' AS rule_name, (SELECT COUNT(*) FROM test_attempt_defects l JOIN test_attempts a ON a.id=l.attempt_id WHERE a.status<>'FAIL') AS violation_count
UNION ALL
SELECT 'active_assignee_role' AS rule_name, (SELECT COUNT(*) FROM defects d JOIN users u ON u.id=d.assignee_id LEFT JOIN project_members m ON m.user_id=d.assignee_id AND m.project_id=d.project_id WHERE d.status<>'CLOSED' AND (u.status<>'ACTIVE' OR (u.system_role<>'ADMIN' AND (m.user_id IS NULL OR m.status<>'ACTIVE' OR m.project_role<>'DEVELOPER')))) AS violation_count
UNION ALL
SELECT 'run_nonempty' AS rule_name, (SELECT COUNT(*) FROM test_runs r WHERE NOT EXISTS (SELECT 1 FROM test_run_cases rc WHERE rc.test_run_id=r.id)) AS violation_count
UNION ALL
SELECT 'snapshot_steps_nonempty' AS rule_name, (SELECT COUNT(*) FROM test_run_cases rc WHERE NOT EXISTS (SELECT 1 FROM test_run_case_steps st WHERE st.test_run_case_id=rc.id)) AS violation_count
UNION ALL
SELECT 'snapshot_steps_contiguous' AS rule_name, (SELECT COUNT(*) FROM (SELECT test_run_case_id FROM test_run_case_steps GROUP BY test_run_case_id HAVING MIN(step_order)<>1 OR MAX(step_order)<>COUNT(*)) violations) AS violation_count
UNION ALL
SELECT 'ready_case_steps' AS rule_name, (SELECT COUNT(*) FROM test_cases c WHERE c.status='READY' AND NOT EXISTS (SELECT 1 FROM test_steps st WHERE st.test_case_id=c.id)) AS violation_count
UNION ALL
SELECT 'current_steps_contiguous' AS rule_name, (SELECT COUNT(*) FROM (SELECT test_case_id FROM test_steps GROUP BY test_case_id HAVING MIN(step_order)<>1 OR MAX(step_order)<>COUNT(*)) violations) AS violation_count
UNION ALL
SELECT 'ready_plan_nonempty' AS rule_name, (SELECT COUNT(*) FROM test_plans p WHERE p.status='READY' AND NOT EXISTS (SELECT 1 FROM test_plan_cases pc WHERE pc.test_plan_id=p.id)) AS violation_count
UNION ALL
SELECT 'ready_plan_cases_ready' AS rule_name, (SELECT COUNT(*) FROM test_plan_cases pc JOIN test_plans p ON p.id=pc.test_plan_id JOIN test_cases c ON c.id=pc.test_case_id WHERE p.status='READY' AND c.status<>'READY') AS violation_count
UNION ALL
SELECT 'completed_run_no_not_run' AS rule_name, (SELECT COUNT(*) FROM test_runs r JOIN test_run_cases rc ON rc.test_run_id=r.id WHERE r.status='COMPLETED' AND NOT EXISTS (SELECT 1 FROM test_attempts a WHERE a.test_run_case_id=rc.id)) AS violation_count
UNION ALL
SELECT 'successful_import_nonempty' AS rule_name, (SELECT COUNT(*) FROM test_imports i WHERE NOT EXISTS (SELECT 1 FROM test_attempts a WHERE a.import_id=i.id)) AS violation_count
UNION ALL
SELECT 'counter_ahead_of_keys' AS rule_name, (SELECT COUNT(*) FROM project_counters pc JOIN (SELECT project_id,'REQ' AS entity_type,MAX(key_no) AS last_key FROM requirements GROUP BY project_id UNION ALL SELECT project_id,'TC',MAX(key_no) FROM test_cases GROUP BY project_id UNION ALL SELECT project_id,'PLAN',MAX(key_no) FROM test_plans GROUP BY project_id UNION ALL SELECT project_id,'BUG',MAX(key_no) FROM defects GROUP BY project_id) k ON k.project_id=pc.project_id AND k.entity_type=pc.entity_type WHERE pc.next_value<=k.last_key) AS violation_count;
