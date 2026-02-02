from typing import List, Tuple
from psycopg2.extras import DictCursor, DictRow

class Config:
  '''
  Docstring for Config

  :var name: configuration name
  :var table_name: target table's name
  :var sensitive_columns: columns that are considered PII
  :var identifiers: columns that must remain as keys
  :var method: hash | censor | scramble, dictates the stragety for deidentification

  :var columns_data: list which maps all column names to their type
  '''
  def __init__(self, config_db: DictRow, columns_data: dict[str, str]) -> None:
    self.name: str = config_db['configuration_name']
    self.table_name: str = config_db['table_name']
    self.sensitive_columns: list[str] = config_db['sensitive_columns']
    self.identifiers: list[str] = config_db['identifiers']
    self.method: str = config_db['method']

    self.columns_data = columns_data

def load_config(cur: DictCursor, config_name: str):
  '''
  Finds the corresponding configuration for a given configuration name.
  Validates the configuration against that table's structure.
  Also recoverers data about the target table's columns and types.
  '''

  query = '''
    SELECT * FROM configurations WHERE (%s) = configuration_name LIMIT 1;
  '''

  cur.execute(query, (config_name,))
  config = cur.fetchone()
  if not config:
    raise Exception(f'Config: {config_name} not found')

  # check table exists in DB
  query = '''
    SELECT table_name
    FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = %s
    AND table_type = 'BASE TABLE'
    LIMIT 1;
  '''

  cur.execute(query, (config['table_name'],))
  data = cur.fetchone();
  if not data:
    raise Exception(f'Table: {config['table_name']} not found')

  # check columns exists in that table
  query = '''
    SELECT column_name, data_type
    FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = %s
  '''

  cur.execute(query, (config['table_name'],))
  columns = cur.fetchall();

  areColumnsValid = set(config['sensitive_columns']).issubset(set(map(lambda c: c['column_name'], columns)))
  columns_data = dict(map(lambda cd: (cd['column_name'], cd['data_type']), columns))

  if not areColumnsValid:
    raise Exception(f'Config: Columns: {config['sensitive_columns']} cannot be mapped to {config['table_name']} columns')

  return Config(config, columns_data)
