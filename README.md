# Data De-identification Walkthrough

This programs allows users to obscure personally identifiable information from their database tables. It does this by creating two additional tables:

#### "configurations" Table
```sql
CREATE TABLE configurations (
    configuration_name      TEXT PRIMARY KEY,
    table_name              VARCHAR NOT NULL,
    sensitive_columns       TEXT[],
    identifiers             TEXT[],
    method                  VARCHAR(255) DEFAULT 'default'

    CONSTRAINT check_method_type
        CHECK (method IN ('default', 'censor', 'scramble'))
    CONSTRAINT identifiers_not_empty
        CHECK (cardinality(identifiers) > 0)
);
```

Users create a new configuration with a unique `configuration_name`. Inside that configuration, they specify the `table_name`, the columns they want to obscure in `sensitive_columns` and their primary keys in `identifiers`.

Note you can obscure a primary key column by including it in **both** `sensitive_columns` and `identifiers`.

#### "auto_deidentifier_logs" Table
```sql
CREATE TABLE auto_deidentifier_logs (
    log_id UUID             PRIMARY KEY DEFAULT gen_random_uuid(),
    time                    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    configuration_name      TEXT REFERENCES configurations(configuration_name),
    table_name              TEXT,
    type                    TEXT,
    details                 TEXT,

    CONSTRAINT check_log_type
        CHECK (type IN ('success', 'error', 'warning'))
);
```
All updates/errors run also generate logs, these can be viewed in this table.

#### Usage
1. Create a new configuration by inserting into the `configurations` table.
2. Run the script `./main.py <configuration_name>`, this attempts to update all rows inside the specified table. Additional logic/changes to obscuration strategies can be made inside `ObscurerEngine.py`.
3. Review changes made in `auto_deidentifier_logs` table.

#### Or to run the project from this repo
This project requires `python` and `postgres` installed and running.

1. Create a virtual environemnt with `python -m venv`.
2. `pip install -r requirements.txt` into your virtual env.
3. Setup your `.env` file, it must include:
```env
db_uri="postgresql://<db_user>:<password>@<host>:<port>/<db_name>"
```
4. (optional) Run the `load_sample_data.sql` file to populate the database.
5. Run `./main.py <configuration_name>` automatically deidentify data.
    e.g. `./main.py donors-example-config`
