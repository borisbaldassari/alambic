
# Create the required databases: alambic_db and minion_db
PGPASSWORD=pass4alambic psql -h postgres < ~/alambic/resources/docker/psql_init.sql

cd /home/alambic/alambic/mojo
cat alambic.conf 

# Initialise the app: create tables, init instance.
script/alambic alambic init

morbo script/alambic

