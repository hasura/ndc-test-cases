from databricks.sdk import WorkspaceClient
from databricks.sdk.service import sql
import json
import os
import pandas as pd
import re
import argparse
import sys
import time
from typing import Optional

class DatabricksConnection:
    def __init__(
        self,
        host: str,
        token: str,
        warehouse_id: str,
        catalog: str = "hive_metastore",
        schema: str = "default"
    ):
        """Initialize Databricks connection parameters."""
        self.host = host
        self.token = token
        self.warehouse_id = warehouse_id
        self.catalog = catalog
        self.schema = schema
        self.client = None

    def connect(self) -> None:
        """Establish connection to Databricks."""
        try:
            self.client = WorkspaceClient(
                host=self.host,
                token=self.token,
            )
            print("✓ Successfully created Databricks client")
        except Exception as e:
            print(f"❌ Failed to create Databricks client: {str(e)}")
            raise

    def test_connection(self) -> bool:
        """Test the Databricks connection with various checks."""
        try:
            start_time = time.time()

            # Test 1: Basic connectivity by listing warehouses
            warehouses = self.client.warehouses.list()
            print("✓ Successfully connected to Databricks workspace")

            # Test 2: Find and verify specific warehouse
            warehouse = next(
                (w for w in warehouses if w.id == self.warehouse_id),
                None
            )
            if warehouse:
                print(f"✓ Found warehouse: {warehouse.name} (ID: {warehouse.id})")
                print(f"  Status: {warehouse.state.value}")
            else:
                print(f"❌ Warehouse with ID {self.warehouse_id} not found")
                return False

            # Test 3: Check schema access
            self.execute_query(f"USE {self.catalog}.{self.schema}")
            print(f"✓ Successfully accessed schema: {self.schema}")

            # Test 4: List tables permission
            tables = self.execute_query(
                f"SELECT table_name FROM information_schema.tables "
                f"WHERE table_schema = '{self.schema}' LIMIT 5"
            )
            print(f"✓ Successfully listed tables in schema {self.schema}, tables: {tables.data_array}")

            if tables:
                print(f"  Found {len(tables.data_array)} tables (showing up to 5):")
                for row in tables.data_array:
                    print( f"row: {row}")


            elapsed_time = time.time() - start_time
            print(f"\n✓ All connection tests passed in {elapsed_time:.2f} seconds")
            return True

        except Exception as e:
            print("\n❌ Connection test failed!")
            print(f"Error: {str(e)}")
            print("\nTroubleshooting tips:")
            print("1. Verify your access token is valid")
            print("2. Check if the warehouse is running")
            print("3. Confirm you have access to the specified schema")
            print("4. Verify your network can reach Databricks")
            return False

    def execute_query(self, query: str) -> Optional[list]:
        """Execute a SQL query and return results."""
        try:
            statement = self.client.statement_execution.execute_statement(
                warehouse_id=self.warehouse_id,
                catalog=self.catalog,
                schema=self.schema,
                statement=query
            )

            print(f"Executing statement: {query}")

            # Wait for the statement to complete
            while True:
                status = self.client.statement_execution.get_statement(statement.statement_id)
                print(f"Statement status: {status.status.state}")
                if status.status.state == sql.StatementState.SUCCEEDED:
                    break
                time.sleep(1)

            print(f"Statement executed successfully: {query}")

            # Get the result
            # result = self.client.statement_execution.get_statement_result(statement.statement_id)
            result = self.client.statement_execution.get_statement_result_chunk_n(statement.statement_id, 0)
            print(f"Statement result: {result}")
            return result

        except Exception as e:
            print(f"Error executing query: {str(e)}")
            raise

def sanitize_table_name(filename):
    """Convert filename to valid Databricks table name."""
    table_name = filename.split('_', 1)[1] if '_' in filename else filename
    table_name = os.path.splitext(table_name)[0]
    table_name = re.sub(r'\W+', '_', table_name)
    return table_name.lower() if table_name[0].isalpha() else 'table_' + table_name.lower()

def create_table_from_json(json_data: list, table_name: str, connection: DatabricksConnection):
    """Create and populate Databricks table from JSON data."""
    try:
        # Check if table exists
        result = connection.execute_query(
            f"SELECT COUNT(*) FROM information_schema.tables "
            f"WHERE table_schema = '{connection.schema}' "
            f"AND table_name = '{table_name}'"
        )

        print(f"Table exists: {result.data_array}")

        table_exists = int(result.data_array[0][0]) if result else 0

        if not table_exists:
            print(f"Error: Table '{connection.schema}.{table_name}' does not exist")
            sys.exit(1)

        # Convert JSON to DataFrame
        df = pd.DataFrame(json_data)

        # Get column definitions
        columns = ", ".join([f"{col} STRING" for col in df.columns])

        # Create temporary view
        records = df.to_dict('records')
        values = []
        for record in records:
            row_values = []
            for value in record.values():
                if value is None:
                    row_values.append('NULL')
                elif isinstance(value, (int, float)):
                    row_values.append(str(value))
                else:
                    # Escape single quotes and wrap in quotes
                    escaped_value = str(value).replace("'", "''")
                    row_values.append(f"'{escaped_value}'")
            values.append(f"({', '.join(row_values)})")

        values_str = ",\n".join(values)
        insert_query = f"""
            INSERT INTO {connection.schema}.{table_name}
            VALUES
            {values_str}
        """

        connection.execute_query(insert_query)
        print(f"Successfully populated table: {connection.schema}.{table_name}")

    except Exception as e:
        print(f"Error creating/populating table {connection.schema}.{table_name}: {str(e)}")
        raise

def process_json_files(json_directory: str, connection: DatabricksConnection):
    """Process all JSON files in the specified directory."""
    if not os.path.exists(json_directory) or not os.path.isdir(json_directory):
        print(f"Error: '{json_directory}' is not a valid directory")
        sys.exit(1)

    # Run connection test first
    print("\nRunning connection tests...")
    if not connection.test_connection():
        sys.exit(1)
    print("\nStarting file processing...")

    # Get sorted JSON files
    json_files = sorted(
        [f for f in os.listdir(json_directory) if f.endswith('.json')],
        key=lambda x: int(x.split('_')[0])
    )

    if not json_files:
        print(f"No JSON files found in '{json_directory}'")
        sys.exit(1)

    print(f"Found {len(json_files)} JSON files to process")

    # Process each JSON file
    for filename in json_files:
        file_path = os.path.join(json_directory, filename)
        table_name = sanitize_table_name(filename)

        try:
            # Read and process JSON file
            with open(file_path, 'r') as file:
                json_data = json.load(file)

            # Convert single object to list if needed
            if isinstance(json_data, dict):
                json_data = [json_data]

            create_table_from_json(json_data, table_name, connection)

        except json.JSONDecodeError as e:
            print(f"Error reading JSON file {filename}: {str(e)}")
            sys.exit(1)
        except Exception as e:
            print(f"Error processing file {filename}: {str(e)}")
            sys.exit(1)

def main():
    parser = argparse.ArgumentParser(
        description='Import JSON files into Databricks tables'
    )
    parser.add_argument(
        'json_directory',
        help='Directory containing JSON files to import'
    )
    parser.add_argument(
        '--host',
        required=True,
        help='Databricks workspace URL'
    )
    parser.add_argument(
        '--token',
        help='Databricks access token (can also be set via DATABRICKS_TOKEN env var)'
    )
    parser.add_argument(
        '--warehouse-id',
        required=True,
        help='SQL warehouse ID'
    )
    parser.add_argument(
        '--catalog',
        default="hive_metastore",
        help='Catalog name (default: hive_metastore)'
    )
    parser.add_argument(
        '--schema',
        required=True,
        help='Schema name'
    )
    parser.add_argument(
        '--test-only',
        action='store_true',
        help='Only run connection test without processing files'
    )

    args = parser.parse_args()

    # Get token from args or environment
    token = args.token or os.environ.get('DATABRICKS_TOKEN')
    if not token:
        parser.error("Token must be provided via --token or DATABRICKS_TOKEN environment variable")

    try:
        # Initialize and test connection
        connection = DatabricksConnection(
            host=args.host,
            token=token,
            warehouse_id=args.warehouse_id,
            catalog=args.catalog,
            schema=args.schema
        )

        # Connect to Databricks
        connection.connect()

        if args.test_only:
            print("\nRunning connection test only...")
            if connection.test_connection():
                print("\nConnection test successful! Use without --test-only to process files.")
            sys.exit(0)

        process_json_files(args.json_directory, connection)

    except Exception as e:
        print(f"Error: {str(e)}")
        sys.exit(1)

if __name__ == "__main__":
    main()
