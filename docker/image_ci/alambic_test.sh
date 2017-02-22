
echo "# Alambic script for test."
echo "Waiting 20 seconds for the db to init correctly."
sleep 20

# Create the required databases: alambic_db and minion_db
cd ~/alambic/docker/image_ci/
PGPASSWORD=pass4alambic psql -h postgres_ci < ~/alambic/resources/scripts/psql_init.sql

cd ~/alambic/mojo
cat alambic.conf

# Make sure we use the right perl from perlbrew
source ~/.bashrc
perl -v

# Initialise the app: create tables, init instance.
script/alambic alambic init

# Execute perl script to run tests.
perl ~/alambic/resources/scripts/alambic_test.pl
exit $?


