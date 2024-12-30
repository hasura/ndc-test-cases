import json
import os
import pandas as pd
from sqlalchemy import create_engine, text
import re
import argparse
import sys
import urllib.parse

def sanitize_table_name(filename):
    """Convert filename to valid SQL Server table name."""
    # Remove the numeric prefix and file extension
    table_name = filename.split('_', 1)[1] if '_' in filename else filename
    table_name = os.path.splitext(table_name)[0]

    # Replace any non-alphanumeric characters with underscore
    table_name = re.sub(r'\W+', '_', table_name)

    # Ensure name starts with letter
    if not table_name[0].isalpha():
        table_name = 'table_' + table_name

    return table_name

def create_table_from_json(json_data, table_name, engine):
    """Create and populate SQL Server table from JSON data."""
    # Convert JSON to DataFrame
    df = pd.DataFrame(json_data)

    # Check if table exists
    with engine.connect() as conn:
        result = conn.execute(text(f"SELECT OBJECT_ID('{table_name}') as table_exists"))
        table_exists = result.scalar() is not None

        if not table_exists:
            print(f"Error: Table '{table_name}' does not exist")
            sys.exit(1)

    # Create table and insert data
    try:
        df.to_sql(
            table_name,
            engine,
            if_exists='append',
            index=False,
            schema='dbo'  # SQL Server specific: specify default schema
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

    # Create SQL Server connection string
    password = urllib.parse.quote_plus(db_params['password'])  # Handle special characters in password
    conn_str = (
        f"mssql+pyodbc://{db_params['user']}:{password}@"
        f"{db_params['host']},{db_params['port']}/{db_params['database']}"
        "?driver=ODBC+Driver+17+for+SQL+Server"
        "&TrustServerCertificate=yes"
    )

    # Create SQLAlchemy engine
    engine = create_engine(conn_str)

    # Count JSON files
    json_files = sorted([f for f in os.listdir(json_directory) if f.endswith('.json')],
                       key=lambda x: int(x.split('_')[0]))

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
            sys.exit(1)
        except Exception as e:
            print(f"Error processing file {filename}: {str(e)}")
            sys.exit(1)

def main():
    # Set up argument parser
    parser = argparse.ArgumentParser(
        description='Import JSON files into SQL Server tables'
    )
    parser.add_argument(
        'json_directory',
        help='Directory containing JSON files to import'
    )
    parser.add_argument(
        '--host',
        default='localhost',
        help='SQL Server host (default: localhost)'
    )
    parser.add_argument(
        '--port',
        default='1433',
        help='SQL Server port (default: 1433)'
    )
    parser.add_argument(
        '--database',
        required=True,
        help='SQL Server database name'
    )
    parser.add_argument(
        '--user',
        required=True,
        help='SQL Server username'
    )
    parser.add_argument(
        '--password',
        required=True,
        help='SQL Server password'
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
