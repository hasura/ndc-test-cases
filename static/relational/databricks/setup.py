from databricks.sdk import WorkspaceClient
from databricks.sdk.service import sql
import os
import argparse
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

            # Test 3: Execute a simple query
            statement = self.client.statement_execution.execute_statement(
                warehouse_id=self.warehouse_id,
                catalog=self.catalog,
                schema=self.schema,
                statement="SELECT CURRENT_TIMESTAMP()"
            )

            result = self.client.statement_execution.wait_get_statement_result(
                statement.statement_id
            )

            if result and result.data:
                print(f"✓ Successfully executed test query")
                print(f"  Result: {result.data[0]['value_as_string']}")

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
            # Execute the query
            statement = self.client.statement_execution.execute_statement(
                warehouse_id=self.warehouse_id,
                catalog=self.catalog,
                schema=self.schema,
                statement=query
            )

            # Wait for and get results
            result = self.client.statement_execution.wait_get_statement_result(
                statement.statement_id
            )

            if result and result.data:
                return result.data
            return None

        except Exception as e:
            print(f"Error executing query: {str(e)}")
            return None

def main():
    parser = argparse.ArgumentParser(
        description='Test Databricks SDK connection'
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
        default="default",
        help='Schema name (default: default)'
    )
    parser.add_argument(
        '--query',
        help='Optional SQL query to execute after connection test'
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

        # Run connection test
        if not connection.test_connection():
            return

        # Execute optional query
        if args.query:
            print(f"\nExecuting query: {args.query}")
            results = connection.execute_query(args.query)
            if results:
                print("\nQuery results:")
                for row in results:
                    print(row)
            else:
                print("No results returned")

    except Exception as e:
        print(f"Error: {str(e)}")

if __name__ == "__main__":
    main()
