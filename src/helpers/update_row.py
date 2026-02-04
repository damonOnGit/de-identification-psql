from psycopg2 import sql

def build_update_string(table: str, updated_data: dict, identifiers: dict):
  set_clause = sql.SQL(', ').join(
    sql.Composed([sql.Identifier(k), sql.SQL(" = "), sql.Placeholder(k)]) for k in updated_data.keys()
  )

  where_clause = sql.SQL(' AND ').join(
    sql.Composed([sql.Identifier(k), sql.SQL(" = "), sql.Placeholder(k)]) for k in identifiers.keys()
  )

  return sql.SQL(
    '''
    UPDATE {table_name}
    SET {updated_items}
    WHERE {identifiers}
    '''
  ).format(
    table_name=sql.Identifier(table),
    updated_items=set_clause,
    identifiers=where_clause,
  )
