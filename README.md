# De-identification Project

### Specification
Non-profits require can only legally hold data for a certain amount of time.
We want to build a framework that helps non-technical users obscure personally identifiable information.

Core Requirements:
- The framework must provide automation
- The framwework must be flexible to adapt to multiple schema/tables/datasets
- The framework must allow users to configure:
  - what things they consider PII
  - common filters/sorting
- Any updates to the table must be logged, this includes:
  - Successful updates
  - Unsuccessful updates/errors
  - A summary when the task is finished

### Scope Notes
- no need for a GUI, just evidence that the script works
- data may/may not be unsanitary

### Solution
A python script that takes the following arguments:
- Configuration file:
    - columns of table consided PII
    - Identifier keys to be untouched..?
    - Method of deidentification

Runs the required edits for the DB
Logs all the outputs to some other audit sql table or some logs.txt


## Agenda
1. ~~Create a collection of fake data in PSQL~~
2. ~~Configure psql connection via python, check that we can do CRUD~~
3. ~~Reading JSON from python~~
4. ~~Changing configuration to be stored in table~~
5. Research different deidentification methods
6. Dynamically deidentify required columns
7. Figure out how to log things
8. Finally, create non-technical documentation and user guide.

## Components

### 1. Config Loader
Configs can be created and stored into a config_table:
```sql
CREATE TABLE configurations (
    configuration_name VARCHAR(32) PRIMARY KEY,
    table_name VARCHAR NOT NULL,
    sensitive_columns TEXT[],
    identifiers TEXT[],
    method VARCHAR
);
```
In the DB layer, we also have to check that these columns exist.

### 2. De-identification Engine
We need to know how to handle common data types:
- primary key -> leave untouched unless specified
- varchar/text -> add with PK and hash
- date -> normalised
- timestamp -> normalised
- boolean -> scrambled
- decimal -> scrambled
- int -> scrambled

Write a function which returns the deidentified field.

`obscure(type, value) -> obscured_value`

### 3. Logging
It's hard to know how to log to sql table when we can't just conn.commit() bc that would commit all the changes in the transcation.

instead maybe we just log after every time the whole script runs instead -> save it memory and then append to the audit table in the `finally` block.


# Graveyard
### 1. Config loader
We have to do basic error checks like:
- JSON itself must have the following fields valid fields
  - table_name
  - sensitive_columns
  - identifiers
  - [method]

For example:
```json
{
  "table_name": "donors",
  "sensitive_columns": [
    "first_name",
    "last_name",
    "email",
    "phone_number",
    "date_of_birth"
  ],
  "identifiers": "",
  "method": ""
}
```
