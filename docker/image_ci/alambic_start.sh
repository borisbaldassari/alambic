
# Script to start an Alambic instance.
echo "# Alambic script for init start."
echo "Waiting 20 seconds for the db to init correctly."
sleep 20

# Make sure we use the right perl from perlbrew
source ~/.bashrc
perl -v

cd /home/alambic/alambic/mojo

# Start main process for mojo
hypnotoad script/alambic

# Start workers for jobs
script/alambic minion worker
