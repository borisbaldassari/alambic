
DROP TABLE IF EXISTS conf;
DROP TABLE IF EXISTS users;
DROP TABLE IF EXISTS projects_conf;
DROP TABLE IF EXISTS projects_runs;
DROP TABLE IF EXISTS projects_info;
DROP TABLE IF EXISTS projects_cdata;
DROP TABLE IF EXISTS models_metrics;
DROP TABLE IF EXISTS models_attributes;
DROP TABLE IF EXISTS models_qms;

CREATE TABLE IF NOT EXISTS conf (
    param TEXT NOT NULL, 
    val TEXT,
    PRIMARY KEY( param )
);

CREATE TABLE IF NOT EXISTS users (
    id TEXT NOT NULL, 
    name TEXT,
    email TEXT,
    passwd TEXT,
    roles JSONB,
    projects JSONB,
    notifs JSONB,
    PRIMARY KEY( id )
);

CREATE TABLE IF NOT EXISTS projects_conf (
    id TEXT, 
    name TEXT, 
    description TEXT, 
    is_active BOOLEAN, 
    plugins JSONB,
    PRIMARY KEY( id )
);

CREATE TABLE IF NOT EXISTS models_attributes (
    mnemo TEXT, 
    name TEXT, 
    description JSONB, 
    PRIMARY KEY( mnemo )
);

CREATE TABLE IF NOT EXISTS models_metrics (
    mnemo TEXT, 
    name TEXT, 
    description JSONB, 
    scale JSONB, 
    PRIMARY KEY( mnemo )
);

CREATE TABLE IF NOT EXISTS models_qms (
    mnemo TEXT, 
    name TEXT, 
    model JSONB, 
    PRIMARY KEY( mnemo )
);

CREATE TABLE IF NOT EXISTS projects_runs (
    id BIGSERIAL, 
    project_id TEXT NOT NULL, 
    run_time TIMESTAMP,
    run_delay INT,
    run_user TEXT,
    metrics JSONB,
    indicators JSONB,
    attributes JSONB,
    attributes_conf JSONB,
    recs JSONB,
    PRIMARY KEY( id )
);

CREATE TABLE IF NOT EXISTS projects_cdata (
    id BIGSERIAL, 
    project_id TEXT, 
    plugin_id TEXT,  
    last_run TIMESTAMP,
    cdata JSONB, 
    PRIMARY KEY( id )
);

CREATE TABLE IF NOT EXISTS projects_info (
    project_id TEXT, 
    last_run TIMESTAMP,
    info JSONB, 
    PRIMARY KEY( project_id )
);

INSERT INTO conf (param, val)
 VALUES ('name', 'Default CLI init');
INSERT INTO conf (param, val)
 VALUES ('desc', 'Default CLI Init description');
INSERT INTO users (email, id, name, notifs, passwd, projects, roles)
 VALUES ('alambic@castalia.solutions', 'administrator', 'Administrator', '{}', '{X-PBKDF2}HMACSHA1:AAAD6A:5R2HIw==:3c7E0POr1PCmC7XQdahjgr/PDus=', '{}', '["Admin"]');
INSERT INTO projects_conf (description, id, is_active, name, plugins)
 VALUES ('<p>Eclipse Sirius enables the specification of a modeling workbench in terms of <strong>graphical</strong>, <strong>table</strong> or <strong>tree</strong> editors with validation rules and actions using declarative descriptions.</p>
', 'modeling.sirius', '1', 'Eclipse Sirius', '{"Hudson": {"hudson_url": "https://hudson.eclipse.org/sirius/"}, "EclipsePmi": {"project_pmi": "modeling.sirius"}, "StackOverflow": {"so_keyword": "eclipse-sirius"}, "ProjectSummary": {}}');
INSERT INTO projects_info (info, last_run, project_id)
 VALUES ('{"PMI_ID": "modeling.sirius", "PMI_DESC": null, "PMI_TITLE": "Eclipse Sirius", "PMI_CI_URL": "https://hudson.eclipse.org/sirius/", "MLS_USR_URL": "http://eclipse.org/forums/eclipse.sirius", "PMI_SCM_URL": "http://git.eclipse.org/c/sirius/org.eclipse.sirius.legacy.git", "PMI_MAIN_URL": "http://www.eclipse.org/sirius", "PMI_WIKI_URL": "http://wiki.eclipse.org/Sirius", "PMI_DOWNLOAD_URL": "http://www.eclipse.org/sirius/download.html", "PMI_UPDATESITE_URL": "http://download.eclipse.org/sirius/updates/releases/0.9.0/kepler", "PMI_BUGZILLA_PRODUCT": "Sirius", "PMI_DOCUMENTATION_URL": "http://www.eclipse.org/sirius/doc", "PMI_BUGZILLA_COMPONENT": "", "PMI_BUGZILLA_QUERY_URL": "https://bugs.eclipse.org/bugs/buglist.cgi?product=Sirius", "PMI_GETTINGSTARTED_URL": "http://wiki.eclipse.org/Sirius/Getting_Started", "PMI_BUGZILLA_CREATE_URL": "https://bugs.eclipse.org/bugs/enter_bug.cgi?product=Sirius"}', '2017-07-29 09:00:08', 'modeling.sirius');
INSERT INTO projects_runs (attributes, attributes_conf, id, indicators, metrics, project_id, recs, run_delay, run_time, run_user)
 VALUES ('null', 'null', '1', 'null', '{"CI_JOBS": 45, "CI_JOBS_RED": 8, "PMI_REL_VOL": 36, "PMI_ITS_INFO": 5, "PMI_SCM_INFO": 0, "SO_ASKERS_5Y": 18, "CI_JOBS_GREEN": 22, "CI_JOBS_YELLOW": 3, "SO_VIEWS_VOL_5Y": 2846, "SO_VOTES_VOL_5Y": 4, "CI_JOBS_FAILED_1W": 7, "SO_ANSWERS_VOL_5Y": 24, "SO_ANSWER_RATE_5Y": "0.80", "SO_QUESTIONS_VOL_5Y": 30}', 'modeling.sirius', '[{"rid": "PMI_EMPTY_TITLE", "src": "EclipsePmi", "desc": "The title entry is empty in the PMI.", "severity": 2}, {"rid": "PMI_EMPTY_PLAN", "src": "EclipsePmi", "desc": "The plan document URL is empty in the PMI. It helps people understand the roadmap of the project and should be filled.", "severity": 1}, {"rid": "PMI_EMPTY_DEV_ML", "src": "EclipsePmi", "desc": "The developer mailing list URL is empty in the PMI. It helps people know where to ask questions if they want to contribute.", "severity": 3}, {"rid": "CI_FAILING_JOBS", "src": "Hudson", "desc": "Job ecoretools-2.0 has been failing for more than 1 week. You should either disable it if it''s not relevant anymore, or fix it.", "severity": 3}, {"rid": "CI_FAILING_JOBS", "src": "Hudson", "desc": "Job ecoretools-3.1 has been failing for more than 1 week. You should either disable it if it''s not relevant anymore, or fix it.", "severity": 3}, {"rid": "CI_FAILING_JOBS", "src": "Hudson", "desc": "Job ecoretools.gerrit has been failing for more than 1 week. You should either disable it if it''s not relevant anymore, or fix it.", "severity": 3}, {"rid": "CI_FAILING_JOBS", "src": "Hudson", "desc": "Job sirius-website-check has been failing for more than 1 week. You should either disable it if it''s not relevant anymore, or fix it.", "severity": 3}, {"rid": "CI_FAILING_JOBS", "src": "Hudson", "desc": "Job sirius.rcptt-master has been failing for more than 1 week. You should either disable it if it''s not relevant anymore, or fix it.", "severity": 3}, {"rid": "CI_FAILING_JOBS", "src": "Hudson", "desc": "Job sirius.sonar-master has been failing for more than 1 week. You should either disable it if it''s not relevant anymore, or fix it.", "severity": 3}, {"rid": "CI_FAILING_JOBS", "src": "Hudson", "desc": "Job util.shell_tests has been failing for more than 1 week. You should either disable it if it''s not relevant anymore, or fix it.", "severity": 3}]', '47', '2017-07-29 08:53:12', 'administrator');
INSERT INTO projects_runs (attributes, attributes_conf, id, indicators, metrics, project_id, recs, run_delay, run_time, run_user)
 VALUES ('null', 'null', '2', 'null', '{"CI_JOBS": 45, "CI_JOBS_RED": 8, "PMI_REL_VOL": 36, "PMI_ITS_INFO": 5, "PMI_SCM_INFO": 0, "SO_ASKERS_5Y": 18, "CI_JOBS_GREEN": 22, "CI_JOBS_YELLOW": 3, "SO_VIEWS_VOL_5Y": 2846, "SO_VOTES_VOL_5Y": 4, "CI_JOBS_FAILED_1W": 7, "SO_ANSWERS_VOL_5Y": 24, "SO_ANSWER_RATE_5Y": "0.80", "SO_QUESTIONS_VOL_5Y": 30}', 'modeling.sirius', '[{"rid": "PMI_EMPTY_TITLE", "src": "EclipsePmi", "desc": "The title entry is empty in the PMI.", "severity": 2}, {"rid": "PMI_EMPTY_PLAN", "src": "EclipsePmi", "desc": "The plan document URL is empty in the PMI. It helps people understand the roadmap of the project and should be filled.", "severity": 1}, {"rid": "PMI_EMPTY_DEV_ML", "src": "EclipsePmi", "desc": "The developer mailing list URL is empty in the PMI. It helps people know where to ask questions if they want to contribute.", "severity": 3}, {"rid": "CI_FAILING_JOBS", "src": "Hudson", "desc": "Job ecoretools-2.0 has been failing for more than 1 week. You should either disable it if it''s not relevant anymore, or fix it.", "severity": 3}, {"rid": "CI_FAILING_JOBS", "src": "Hudson", "desc": "Job ecoretools-3.1 has been failing for more than 1 week. You should either disable it if it''s not relevant anymore, or fix it.", "severity": 3}, {"rid": "CI_FAILING_JOBS", "src": "Hudson", "desc": "Job ecoretools.gerrit has been failing for more than 1 week. You should either disable it if it''s not relevant anymore, or fix it.", "severity": 3}, {"rid": "CI_FAILING_JOBS", "src": "Hudson", "desc": "Job sirius-website-check has been failing for more than 1 week. You should either disable it if it''s not relevant anymore, or fix it.", "severity": 3}, {"rid": "CI_FAILING_JOBS", "src": "Hudson", "desc": "Job sirius.rcptt-master has been failing for more than 1 week. You should either disable it if it''s not relevant anymore, or fix it.", "severity": 3}, {"rid": "CI_FAILING_JOBS", "src": "Hudson", "desc": "Job sirius.sonar-master has been failing for more than 1 week. You should either disable it if it''s not relevant anymore, or fix it.", "severity": 3}, {"rid": "CI_FAILING_JOBS", "src": "Hudson", "desc": "Job util.shell_tests has been failing for more than 1 week. You should either disable it if it''s not relevant anymore, or fix it.", "severity": 3}]', '44', '2017-07-29 08:54:35', 'administrator');
INSERT INTO projects_runs (attributes, attributes_conf, id, indicators, metrics, project_id, recs, run_delay, run_time, run_user)
 VALUES ('null', 'null', '3', 'null', '{"CI_JOBS": 45, "CI_JOBS_RED": 8, "PMI_REL_VOL": 36, "PMI_ITS_INFO": 5, "PMI_SCM_INFO": 0, "SO_ASKERS_5Y": 18, "CI_JOBS_GREEN": 22, "CI_JOBS_YELLOW": 3, "SO_VIEWS_VOL_5Y": 2846, "SO_VOTES_VOL_5Y": 4, "CI_JOBS_FAILED_1W": 7, "SO_ANSWERS_VOL_5Y": 24, "SO_ANSWER_RATE_5Y": "0.80", "SO_QUESTIONS_VOL_5Y": 30}', 'modeling.sirius', '[{"rid": "PMI_EMPTY_TITLE", "src": "EclipsePmi", "desc": "The title entry is empty in the PMI.", "severity": 2}, {"rid": "PMI_EMPTY_PLAN", "src": "EclipsePmi", "desc": "The plan document URL is empty in the PMI. It helps people understand the roadmap of the project and should be filled.", "severity": 1}, {"rid": "PMI_EMPTY_DEV_ML", "src": "EclipsePmi", "desc": "The developer mailing list URL is empty in the PMI. It helps people know where to ask questions if they want to contribute.", "severity": 3}, {"rid": "CI_FAILING_JOBS", "src": "Hudson", "desc": "Job ecoretools-2.0 has been failing for more than 1 week. You should either disable it if it''s not relevant anymore, or fix it.", "severity": 3}, {"rid": "CI_FAILING_JOBS", "src": "Hudson", "desc": "Job ecoretools-3.1 has been failing for more than 1 week. You should either disable it if it''s not relevant anymore, or fix it.", "severity": 3}, {"rid": "CI_FAILING_JOBS", "src": "Hudson", "desc": "Job ecoretools.gerrit has been failing for more than 1 week. You should either disable it if it''s not relevant anymore, or fix it.", "severity": 3}, {"rid": "CI_FAILING_JOBS", "src": "Hudson", "desc": "Job sirius-website-check has been failing for more than 1 week. You should either disable it if it''s not relevant anymore, or fix it.", "severity": 3}, {"rid": "CI_FAILING_JOBS", "src": "Hudson", "desc": "Job sirius.rcptt-master has been failing for more than 1 week. You should either disable it if it''s not relevant anymore, or fix it.", "severity": 3}, {"rid": "CI_FAILING_JOBS", "src": "Hudson", "desc": "Job sirius.sonar-master has been failing for more than 1 week. You should either disable it if it''s not relevant anymore, or fix it.", "severity": 3}, {"rid": "CI_FAILING_JOBS", "src": "Hudson", "desc": "Job util.shell_tests has been failing for more than 1 week. You should either disable it if it''s not relevant anymore, or fix it.", "severity": 3}]', '49', '2017-07-29 09:00:08', 'administrator');
