from helpers.read_config import Config
from itertools import count
from psycopg2.extras import DictRow

# TODO: consider some OOP method that would improve scalability

unique_id_generator = count(1)
def unique_number():
  # since this will always be unique in memory
  pass

def custom_uuid_scramble():
  pass

def hash():
  pass


type_to_strategy = {
  'uuid': custom_uuid_scramble,
  'character varying': hash,
  'date': hash,
  'numeric': unique_number,
}

def obsure_row(config: Config, row: DictRow):
  '''
  Docstring for obsure_row

  Given a row and config return the new transformed row
  '''
  for column_name, value in row.items():
    data_type = config.columns_data[column_name]
    # check known data type

    type_to_strategy[data_type]()
