
cat /home/boris/alambic/mojo/alambic.conf
PGPASSWORD=pass4alambic psql -h postgres < psql_init.sql

cd /home/alambic/alambic/mojo
perl -Ilib t/unit/Model/Alambic.t

echo 0

