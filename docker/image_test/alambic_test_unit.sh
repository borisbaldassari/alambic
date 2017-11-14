
echo "# Alambic script for test."
echo "Waiting 10 seconds for the db to init correctly."
sleep 10

# Create the required databases: alambic_db and minion_db
PGPASSWORD=pass4alambic psql -h postgres < ~/alambic/resources/scripts/psql_init.sql

cd /home/alambic/alambic/mojo
cp /home/alambic/alambic/docker/image_test/alambic.conf .

cat alambic.conf

# Make sure we use the right perl from perlbrew
source ~/.bashrc
perl -v

# Initialise the app: create tables, init instance.
bin/alambic init

bin/alambic test t/unit/*/*.t

exit $?


