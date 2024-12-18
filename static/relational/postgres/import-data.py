import json
import os
import psycopg2
from psycopg2.extensions import ISOLATION_LEVEL_AUTOCOMMIT
import pandas as pd
from sqlalchemy import create_engine
from sqlalchemy.sql import text
import re
import argparse
import sys

def sanitize_table_name(filename):
    """Convert filename to valid PostgreSQL table name."""
    # Remove file extension and special characters
    table_name = os.path.splitext(filename)[0]
    # Replace any non-alphanumeric characters with underscore
    table_name = re.sub(r'\W+', '_', table_name)
    # Ensure name starts with letter
    if not table_name[0].isalpha():
        table_name = 'table_' + table_name
    return table_name

def create_table_from_json(json_data, table_name, engine):
    """Create and populate PostgreSQL table from JSON data."""
    # Convert JSON to DataFrame
    df = pd.DataFrame(json_data)

    # Check if table exists
    with engine.connect() as conn:
        result = conn.execute(text(f"SELECT EXISTS (SELECT FROM information_schema.tables WHERE table_name = '{table_name}')"))
        table_exists = result.scalar()

        if not table_exists:
            print(f"Error: Table '{table_name}' does not exist")
            sys.exit(1)

    # Create table and insert data
    try:
        df.to_sql(
            table_name,
            engine,
            if_exists='append',
            index=False
        )
        print(f"Successfully populated table: {table_name}")
    except Exception as e:
        print(f"Error creating table {table_name}: {str(e)}")

def process_json_files(json_directory, db_params):
    """Process all JSON files in the specified directory."""
    if not os.path.exists(json_directory):
        print(f"Error: Directory '{json_directory}' does not exist")
        sys.exit(1)

    if not os.path.isdir(json_directory):
        print(f"Error: '{json_directory}' is not a directory")
        sys.exit(1)

    # Create SQLAlchemy engine
    engine = create_engine(
        f"postgresql://{db_params['user']}:{db_params['password']}@"
        f"{db_params['host']}:{db_params['port']}/{db_params['database']}"
    )

    # Count JSON files
    json_files = [f for f in os.listdir(json_directory) if f.endswith('.json')]
    if not json_files:
        print(f"No JSON files found in '{json_directory}'")
        sys.exit(1)

    print(f"Found {len(json_files)} JSON files to process")

    # Process each JSON file in the directory
    for filename in json_files:
        file_path = os.path.join(json_directory, filename)
        table_name = sanitize_table_name(filename)

        try:
            # Read JSON file
            with open(file_path, 'r') as file:
                json_data = json.load(file)

            # Handle both single objects and arrays of objects
            if isinstance(json_data, dict):
                json_data = [json_data]

            create_table_from_json(json_data, table_name, engine)

        except json.JSONDecodeError as e:
            print(f"Error reading JSON file {filename}: {str(e)}")
        except Exception as e:
            print(f"Error processing file {filename}: {str(e)}")

def main():
    # Set up argument parser
    parser = argparse.ArgumentParser(
        description='Import JSON files into PostgreSQL tables'
    )
    parser.add_argument(
        'json_directory',
        help='Directory containing JSON files to import'
    )
    parser.add_argument(
        '--host',
        default='localhost',
        help='PostgreSQL host (default: localhost)'
    )
    parser.add_argument(
        '--port',
        default='5432',
        help='PostgreSQL port (default: 5432)'
    )
    parser.add_argument(
        '--database',
        required=True,
        help='PostgreSQL database name'
    )
    parser.add_argument(
        '--user',
        required=True,
        help='PostgreSQL username'
    )
    parser.add_argument(
        '--password',
        required=True,
        help='PostgreSQL password'
    )

    args = parser.parse_args()

    # Database connection parameters
    db_params = {
        'host': args.host,
        'database': args.database,
        'user': args.user,
        'password': args.password,
        'port': args.port
    }

    process_json_files(args.json_directory, db_params)

if __name__ == "__main__":
    main()
