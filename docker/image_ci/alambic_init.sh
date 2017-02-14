
# Script to initialise Alambic for the ci docker image.
echo "# Alambic script for init."
echo "Waiting 10 seconds for the db to init correctly."
sleep 10

# Make sure we use the right perl from perlbrew
source ~/.bashrc
perl -v

# Create the required databases: alambic_db and minion_db
PGPASSWORD=pass4alambic psql -h postgres < ~/alambic/resources/scripts/psql_init.sql

cd /home/alambic/alambic/mojo
cat alambic.conf

# Initialise the app: create tables, init instance.
script/alambic alambic init


