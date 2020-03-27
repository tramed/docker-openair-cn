#!/bin/sh
sleep 10
until cqlsh -f /tmp/cassandra/oai_db.cql; do
  echo "cqlsh: Cassandra is unavailable to initialize - will retry later"
  sleep 10
done &

exec /docker-entrypoint.sh "$@"