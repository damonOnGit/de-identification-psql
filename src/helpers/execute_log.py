from psycopg2 import sql

def insert_log(cur, log_entry):
  columns = log_entry.keys()
  log_query = sql.SQL("INSERT INTO auto_deidentifier_logs ({}) VALUES ({})").format(
    sql.SQL(', ').join(map(sql.Identifier, columns)),
    sql.SQL(', ').join(map(sql.Placeholder, columns))
  )

  cur.execute(log_query, log_entry)
