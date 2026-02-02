#!/c/Users/eelno/git-repos/deidentification-project/venv/Scripts/python

import psycopg2
from psycopg2 import extras, sql
from pprint import pprint
import sys

from helpers.read_config import load_config

if len(sys.argv) != 2:
  print("Usage: ./main.py <config_name>", file=sys.stderr)
  sys.exit(1)
config_name = sys.argv[1]

conn = None
try:
  with psycopg2.connect(
    dbname="deidentificationsamples",
    user="postgres",
    password="0497",
    host="localhost",
    port="5432"
  ) as conn:
    with conn.cursor(cursor_factory=extras.DictCursor) as cur:
      config = load_config(cur, config_name)
      print(f'Sucessfullly loaded config: {config.name}')
      pprint(config.columns_data)
      pprint(config.sensitive_columns)

      query = sql.SQL("SELECT * FROM {table}").format(
        table=sql.Identifier(config.table_name),
      )

      cur.execute(query)
      rows = cur.fetchall()
      for row in rows:
        for k in row.keys():
          print(k)
        print('-- -- ')
        for v in row.values():
          print(v)

        break
        # print(row)

      # conn.commit()

except Exception as e:
  print(f"Error connecting to database: {e}")

finally:
  if conn: conn.close()
