
# Script to start an Alambic instance.
echo "# Alambic script for init start."
echo "Waiting 20 seconds for the db to init correctly."
sleep 20

# Make sure we use the right perl from perlbrew
source ~/.bashrc
perl -v

cd /home/alambic/alambic/mojo
cp /home/alambic/alambic/docker/image_ci/alambic.conf .

# Start main process for mojo
hypnotoad bin/alambic

# Start workers for jobs
bin/alambic minion worker

