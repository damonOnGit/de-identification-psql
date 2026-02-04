from uuid import uuid4
import hashlib

class ObscurerEngine:
  '''
  Handles holds the strategies for obscuration of different data types recognised in postgres. Extend its scope by including a data type and mapping it to an obscuration function.

  Note: in the case that one of these fields are primary keys, we should be careful that we obscure them with unique values for that table.
  '''

  def __init__(self) -> None:
    self.increment = 1
    self.strategy = {
      'uuid': self.custom_uuid_scramble,
      'character varying': self.hash,
      'date': self.hide_date,
      'numeric': self.unique_number,
    }

  def obscure(self, data_type, data):
    if data_type not in self.strategy:
      raise Exception('Error during de-identification: Unrecognised data type')

    try:
      return self.strategy[data_type](data)
    except Exception as e:
      raise Exception(f'Cannot obscure: "{data}" of type <{data_type}>\nDetails: ' + str(e))

  def custom_uuid_scramble(self, data):
    while (new_id := uuid4()) != data:
      return new_id

  def hide_date(self, data):
    return '2000-01-01'

  def hash(self, data):
    # add the increment to avoid duplicates
    hashed = hashlib.sha256((data + str(self.increment)).encode('utf-8')).hexdigest()
    self.increment += 1
    return hashed[:len(data)]

  def unique_number(self, data):
    self.increment += 1
    return self.increment - 1
