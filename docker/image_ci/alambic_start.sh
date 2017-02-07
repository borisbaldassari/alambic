# Script to start an Alambic instance.

# Make sure we use the right perl from perlbrew
source ~/.bashrc
perl -v

cd /home/alambic/alambic/mojo

# Start main process for mojo
hypnotoad script/alambic

# Start workers for jobs
script/alambic minion worker
