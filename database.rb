require 'sqlite3'

DB = SQLite3::Database.new "seo_data.db"
DB.results_as_hash = true

# ✅ Ensure the table exists with a `crawled` flag
DB.execute <<-SQL
  CREATE TABLE IF NOT EXISTS seo_data (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    url TEXT UNIQUE,
    title TEXT,
    title_length INTEGER,
    meta_description TEXT,
    meta_description_length INTEGER,
    h1 TEXT,
    h2 TEXT,
    h3 TEXT,
    canonical TEXT,
    robots_meta TEXT,
    schema_present INTEGER,
    missing_alt_percentage REAL,
    word_count INTEGER,
    internal_links INTEGER,
    external_links INTEGER,
    broken_links INTEGER,
    load_time REAL,
    page_size REAL,
    is_https INTEGER,
    has_google_analytics INTEGER,
    has_google_tag_manager INTEGER,
    crawled INTEGER
  );
SQL
