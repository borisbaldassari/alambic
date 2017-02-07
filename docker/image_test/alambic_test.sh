
# Create the required databases: alambic_db and minion_db
cd ~/alambic/docker/image_test/
PGPASSWORD=pass4alambic psql -h postgres < psql_init.sql

cd ~/alambic/mojo
cat alambic.conf

# Initialise the app: create tables, init instance.
script/alambic alambic init

# Execute perl script to run tests.
perl ../resources/scripts/alambic_test.pl


