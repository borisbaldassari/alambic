title: Startup Scripts
navi_name: Startup

# Systemd

There is a script in the git repository to add Alambic as a service.

<script src="https://bitbucket.org/BorisBaldassari/alambic/src/a492e0ac10ef64f40afb18602e1d29715e8866d2/resources/scripts/systemd/alambic.service?embed=t"></script>

To register and use the service:

* Open the file and edit/adapt the context and variables
  - `User=<user>` the ID of the user executing Alambic.
  - `PIDFile=<pid_file>` is the full path to the hypnotoad.pid file.
  - Update all references to Hypnotoad's binary: `/home/alambic/perl5/perlbrew/perls/perl-5.24.2/bin/hypnotoad`
  - Update all references to Alambic's home: `/home/alambic/alambic/mojo/`
* Copy the file to `/etc/systemd/system/alambic.service`
* Register the service: `# systemctl enable alambic`
* Start, stop the service:
  `systemctl start alambic`
  `systemctl stop alambic`
