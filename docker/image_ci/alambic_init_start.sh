
# Script to initialise Alambic for the ci docker image.
echo "# Alambic script for init start."
echo "Waiting 30 seconds for the db to init correctly."
sleep 30

# Make sure we use the right perl from perlbrew
source ~/.bashrc
perl -v

# Create the required databases: alambic_db and minion_db
PGPASSWORD=pass4alambic psql -h postgres_ci < ~/alambic/resources/scripts/psql_init.sql

cd /home/alambic/alambic/mojo
cp /home/alambic/alambic/docker/image_ci/alambic.conf .

cat alambic.conf

# Initialise the app: create tables, init instance.
bin/alambic init

# Start main process for mojo
hypnotoad bin/alambic

# Start workers for jobs
bin/alambic minion worker
