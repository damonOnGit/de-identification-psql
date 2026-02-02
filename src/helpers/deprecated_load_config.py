#!/c/Users/eelno/git-repos/deidentification-project/venv/Scripts/python

import json
import sys
from pprint import pprint

def read_config(file_path: str):
  try:
    with open(file_path, 'r') as file:
        data = json.load(file)

    print("Config file successfully loaded:")
    pprint(data)
    print()

    return data
  except FileNotFoundError:
    print(f"Error: The file '{file_path}' was not found.")
  except json.JSONDecodeError:
    print(f"Error: Could not decode JSON from the file '{file_path}'. Check file format.")
  except Exception as e:
    print(f"An unexpected error occurred: {e}")

if __name__ == "__main__":
  if len(sys.argv) != 2:
    print("Usage: ./load_config.py <file_path>", file=sys.stderr)
    sys.exit(1)
  file_path = sys.argv[1]
  read_config(file_path)
