
echo "# Alambic script for test."
echo "Waiting 20 seconds for the db to init correctly."
sleep 20

# Create the required databases: alambic_db and minion_db
PGPASSWORD=pass4alambic psql -h postgres < ~/alambic/resources/scripts/psql_init.sql

cd ~/alambic/mojo
cat alambic.conf

# Make sure we use the right perl from perlbrew
source ~/.bashrc
perl -v

# Initialise the app: create tables, init instance.
script/alambic alambic init

script/alambic test

exit $?


