#!/bin/bash
source db_export_settings.sh

echo "DB_HOST: $DB_HOST"
echo "DB_PORT: $DB_PORT"
echo "DB_NAME: $DB_NAME"
echo "DB_USER: $DB_USER"
echo "OUTPUT_DIR: $OUTPUT_DIR"
echo "BATCH_SIZE: $BATCH_SIZE"
echo "DBLINK_CONNECTION: $DBLINK_CONNECTION"

# Check the database connection
pg_isready -h "$DB_HOST" -p "$DB_PORT" -d "$DB_NAME" -U "$DB_USER" -t 1
exit_code=$?

# Exit if unable to connect to the kazanexpress database.
if [ $exit_code -eq 0 ]; then
  echo "SUCCESS! kazanexpress database is ready and accessible."
else
  echo "FAILED! Unable to connect to the kazanexpress database, check your connection settings."
  read -p "Press enter to continue"
  exit
fi

# Exit if the output directory is not empty
if [ -n "$(ls -A "$OUTPUT_DIR")" ]; then
  echo "$OUTPUT_DIR is not empty - clear it manually!"
  read -p "Press enter to continue"
  exit
fi

mkdir -p "$OUTPUT_DIR"

export PGPASSWORD="$DB_PASSWORD"

TOTAL_COUNT=$(psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -f "script_count.sql" -t -v dblink_connection="$DBLINK_CONNECTION"| tr -d '[:space:]')

TOTAL_BATCHES=$((TOTAL_COUNT / BATCH_SIZE + 1))

echo "$TOTAL_COUNT rows from query to export in $TOTAL_BATCHES batches of $BATCH_SIZE rows"

for ((i=0; i<TOTAL_BATCHES; i++)); do
  OFFSET=$((i * BATCH_SIZE))

  OUTPUT_FILE="$OUTPUT_DIR/profiles_$((i+1)).json"

  psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -v offset_value=$OFFSET -v limit_value=$BATCH_SIZE -f "script_select.sql" -t -o "$OUTPUT_FILE" -v dblink_connection="$DBLINK_CONNECTION"

  echo "Exported batch $((i+1))/$TOTAL_BATCHES to $OUTPUT_FILE"
done
unset PGPASSWORD

echo "Data export complete!"