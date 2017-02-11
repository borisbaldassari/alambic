# Script to initialise Alambic for the ci docker image.

# Make sure we use the right perl from perlbrew
source ~/.bashrc
perl -v

# Create the required databases: alambic_db and minion_db
PGPASSWORD=pass4alambic psql -h postgres < ~/psql_init.sql

cd /home/alambic/alambic/mojo
cat alambic.conf

# Initialise the app: create tables, init instance.
script/alambic alambic init

# Start main process for mojo
hypnotoad script/alambic

# Start workers for jobs
script/alambic minion worker
