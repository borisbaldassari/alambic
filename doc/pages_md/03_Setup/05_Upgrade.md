title: Upgrading Alambic
navi_name: Upgrade


# Upgrading Alambic

Since all data is stored into the database, any running instance of Alambic can be updated from the Alambic project repository without losing any information.

<span class="label label-warning">Warning</span> &nbsp; As usual in this situation, it is highly recommended to make a backup prior to any update.

To do the update go to the alambic directory and issue a git pull command:

    boris@camp ~/alambic $ git pull
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

Then restart (hot-reload) hypnotoad:

    boris@midkemia mojo $ hypnotoad bin/alambic
    Starting hot deployment for Hypnotoad server 21981.

If anything goes wrong, you can still get back to the previous git commit and (if things went *really* wrong) restore the last backup file. Check the [documentation on backup](Backups) for more information.
