
echo "# Alambic script for test."
echo "Waiting 10 seconds for the db to init correctly."
sleep 10

# Create the required databases: alambic_db and minion_db
cd ~/alambic/docker/image_test/
PGPASSWORD=pass4alambic psql -h postgres < psql_init.sql

cd ~/alambic/mojo
cat alambic.conf

# Make sure we use the right perl from perlbrew
source ~/.bashrc
perl -v

# Initialise the app: create tables, init instance.
script/alambic alambic init

script/alambic test t/ui/*.t

exit $?

