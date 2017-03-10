
# Script to start an Alambic instance.
echo "# Alambic script for init start."
echo "Waiting 30 seconds for the db to init correctly."
sleep 30

# Make sure we use the right perl from perlbrew
source ~/.bashrc
perl -v

cd /home/alambic/alambic/mojo

# Start main process for mojo
hypnotoad bin/alambic

# Start workers for jobs
bin/alambic minion worker

