#!/usr/bin/env python

import psycopg2
from psycopg2 import extras, sql
from dotenv import load_dotenv
import sys
import os

from helpers.execute_log import insert_log
from helpers.read_config import Config, load_config
from helpers.ObscurerEngine import ObscurerEngine
from helpers.update_row import build_update_string

load_dotenv()

if len(sys.argv) != 2:
  print("Usage: ./main.py <config_name>", file=sys.stderr)
  sys.exit(1)
config_name = sys.argv[1]

conn = cur = config = None
try:
  with psycopg2.connect(os.getenv('db_uri')) as conn:
    with conn.cursor(cursor_factory=extras.DictCursor) as cur:
      config = load_config(cur, config_name)
      print(f'Sucessfullly loaded config: {config.name}')

      query = sql.SQL("SELECT * FROM {table}").format(
        table=sql.Identifier(config.table_name),
      )

      cur.execute(query)
      rows = cur.fetchall()

      obscurer = ObscurerEngine()
      count = 0
      for row in rows:
        updated_data = {}       # <column_name, obscured_data>
        identifiers = {}        # <column_name, value>

        for i in config.identifiers:
          identifiers[i] = row[i]

        for column_name, data in row.items():
          # generate the obscured versions of sensitive columns
          if column_name not in config.sensitive_columns:
            continue

          data_type = config.columns_data[column_name]
          updated_data[column_name] = obscurer.obscure(data_type, data)

        params = updated_data | identifiers
        # TODO change this to a bulk update
        cur.execute(build_update_string(config.table_name, updated_data, identifiers), params)
        count += 1

      # Commit and log changes
      message = f'{config.table_name} successfully updated: {count} row(s) de-identified. Log created in auto_deidentifier_logs table.'
      print(message)
      insert_log(cur, {
        "configuration_name": config_name,
        "table_name": config.table_name,
        "type": "success",
        "details": message
      })

      conn.commit()

except Exception as e:
  print(f"Error: {e}")
  with psycopg2.connect(os.getenv('db_uri')) as conn:
    with conn.cursor(cursor_factory=extras.DictCursor) as cur:
      if cur and conn:
        message = f'Failed to run run {config_name}\nReason -> {e}'
        insert_log(cur, {
          "configuration_name": config_name,
          "table_name": config.table_name if config else '',
          "type": "error",
          "details": message
        })
        conn.commit()
finally:
  if conn: conn.close()
