title: Upgrading Alambic
navi_name: Upgrade


# Upgrading Alambic

Any running instance of Alambic can be updated from the Alambic project repository without losing any information. Of course, it is recommended to make a backup prior to any update.

To do the update go to the alambic directory and issue a git pull command:

    boris@camp ~/alambic$ git pull
    remote: Counting objects: 6, done.
    remote: Compressing objects: 100% (6/6), done.
    remote: Total 6 (delta 3), reused 0 (delta 0)
    Unpacking objects: 100% (6/6), done.
    From bitbucket.org:BorisBaldassari/alambic
       709aae9..eef3c49  master     -> origin/master
    Updating 709aae9..eef3c49
    Fast-forward
     mojo/public/images/alambic_presentation_data.jpg |  Bin 0 -> 110023 bytes
     1 file changed, 0 insertions(+), 0 deletions(-)
     create mode 100644 mojo/public/images/alambic_presentation_data.jpg

Then restart hypnotoad if needed and the instance should have been updated. If anything goes wrong, you can still restore the last backup file. Check the [documentation on backup](Backups) for more information.
