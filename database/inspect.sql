-- Introspection of the selected schema; counts come from MySQL, not source regexes.
SELECT VERSION() AS mysql_version,@@port AS port,@@innodb_page_size AS innodb_page_size,
 @@sql_mode AS sql_mode,@@foreign_key_checks AS foreign_key_checks;
SELECT 'tables' AS object_type,COUNT(*) AS object_count FROM information_schema.tables WHERE table_schema=DATABASE() AND table_type='BASE TABLE'
UNION ALL SELECT 'columns',COUNT(*) FROM information_schema.columns WHERE table_schema=DATABASE()
UNION ALL SELECT constraint_type,COUNT(*) FROM information_schema.table_constraints WHERE constraint_schema=DATABASE() GROUP BY constraint_type
UNION ALL SELECT 'all_indexes',COUNT(*) FROM (SELECT table_name,index_name FROM information_schema.statistics WHERE table_schema=DATABASE() GROUP BY table_name,index_name) i
UNION ALL SELECT 'ordinary_indexes',COUNT(*) FROM (SELECT table_name,index_name FROM information_schema.statistics WHERE table_schema=DATABASE() AND non_unique=1 GROUP BY table_name,index_name) i
UNION ALL SELECT 'routines',COUNT(*) FROM information_schema.routines WHERE routine_schema=DATABASE()
UNION ALL SELECT 'triggers',COUNT(*) FROM information_schema.triggers WHERE trigger_schema=DATABASE()
UNION ALL SELECT 'views',COUNT(*) FROM information_schema.views WHERE table_schema=DATABASE();
SELECT table_name,constraint_name,delete_rule,update_rule FROM information_schema.referential_constraints WHERE constraint_schema=DATABASE() ORDER BY table_name,constraint_name;
SELECT table_name,index_name,non_unique,GROUP_CONCAT(column_name ORDER BY seq_in_index) AS columns_in_order FROM information_schema.statistics WHERE table_schema=DATABASE() GROUP BY table_name,index_name,non_unique ORDER BY table_name,index_name;
SELECT constraint_name,enforced FROM information_schema.table_constraints WHERE constraint_schema=DATABASE() AND constraint_type='CHECK' ORDER BY constraint_name;
SELECT 'users' AS table_name,COUNT(*) AS row_count FROM `users`
UNION ALL SELECT 'projects' AS table_name,COUNT(*) AS row_count FROM `projects`
UNION ALL SELECT 'project_members' AS table_name,COUNT(*) AS row_count FROM `project_members`
UNION ALL SELECT 'project_counters' AS table_name,COUNT(*) AS row_count FROM `project_counters`
UNION ALL SELECT 'requirements' AS table_name,COUNT(*) AS row_count FROM `requirements`
UNION ALL SELECT 'test_cases' AS table_name,COUNT(*) AS row_count FROM `test_cases`
UNION ALL SELECT 'test_automation_identities' AS table_name,COUNT(*) AS row_count FROM `test_automation_identities`
UNION ALL SELECT 'test_automation_mappings' AS table_name,COUNT(*) AS row_count FROM `test_automation_mappings`
UNION ALL SELECT 'test_steps' AS table_name,COUNT(*) AS row_count FROM `test_steps`
UNION ALL SELECT 'test_case_requirements' AS table_name,COUNT(*) AS row_count FROM `test_case_requirements`
UNION ALL SELECT 'test_plans' AS table_name,COUNT(*) AS row_count FROM `test_plans`
UNION ALL SELECT 'test_plan_cases' AS table_name,COUNT(*) AS row_count FROM `test_plan_cases`
UNION ALL SELECT 'test_runs' AS table_name,COUNT(*) AS row_count FROM `test_runs`
UNION ALL SELECT 'test_run_cases' AS table_name,COUNT(*) AS row_count FROM `test_run_cases`
UNION ALL SELECT 'test_run_case_steps' AS table_name,COUNT(*) AS row_count FROM `test_run_case_steps`
UNION ALL SELECT 'test_imports' AS table_name,COUNT(*) AS row_count FROM `test_imports`
UNION ALL SELECT 'test_attempts' AS table_name,COUNT(*) AS row_count FROM `test_attempts`
UNION ALL SELECT 'defects' AS table_name,COUNT(*) AS row_count FROM `defects`
UNION ALL SELECT 'test_attempt_defects' AS table_name,COUNT(*) AS row_count FROM `test_attempt_defects`;
