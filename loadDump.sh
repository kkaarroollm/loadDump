#!/bin/bash

usage() {
  echo "Usage: $0 path/to/.env [-p postgres_dump_file] [-m mongo_dump_files] [-h]"
  echo "  -p    Specify the PostgreSQL dump file"
  echo "  -m    Specify the MongoDB dump files (space-separated)"
  echo "  -h    Display this help message"
  exit 1
}

if [ -f "$1" ]; then
  source "$1"
else
  echo "Environment file not found!"
  exit 1
fi

shift


pg_dump_file=$PG_DUMP_FILE
mongo_dump_files=$MONGO_DUMP_FILES

restore_postgres_flag=false
restore_mongo_flag=false

while getopts ":p:m:h" opt; do
  case $opt in
    p)
      pg_dump_file=$OPTARG
      restore_postgres_flag=true
      ;;
    m)
      mongo_dump_files=$OPTARG
      restore_mongo_flag=true
      ;;
    h)
      usage
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      usage
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      usage
      ;;
  esac
done

restore_postgres() {
  export PGPASSWORD=$POSTGRES_PASSWORD
  if psql -h "$POSTGRES_HOST" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -p "$POSTGRES_PORT" -f "$pg_dump_file"; then
    echo "PostgreSQL dump uploaded successfully."
  else
    echo "Failed to upload PostgreSQL dump."
  fi
  unset PGPASSWORD
}

restore_mongo() {
  for MONGO_DUMP_FILE in $mongo_dump_files; do
    if mongorestore --host "$MONGO_HOST" --port "$MONGO_PORT" --username "$MONGO_INITDB_ROOT_USERNAME" --password "$MONGO_INITDB_ROOT_PASSWORD" --authenticationDatabase "$MONGO_AUTH_DB" --db "$MONGO_INITDB_DATABASE" "$MONGO_DUMP_FILE"; then
      echo "MongoDB dump $MONGO_DUMP_FILE uploaded successfully."
    else
      echo "Failed to upload MongoDB dump $MONGO_DUMP_FILE."
    fi
  done
}

if $restore_postgres_flag; then
  restore_postgres
fi

if $restore_mongo_flag; then
  restore_mongo
fi

if ! $restore_postgres_flag && ! $restore_mongo_flag; then
  restore_postgres
  restore_mongo
fi

