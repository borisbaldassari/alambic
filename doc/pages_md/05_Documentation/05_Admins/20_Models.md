title: Admin > Models
navi_name: Models


# Admin > Models

In Alambic all models (i.e. quality model, quality attributes and metrics) are stored in the database. They are usually configured by reading JSON files from the file system.

For more details on the models customisation, see the [dedicated section](/Documentation/Tasks/Models.html).

![Alambic Admin Web UI](/images/admins_models.png)

The **Metrics** section lists files stored in `$ALAMBIC_HOME/mojo/lib/Alambic/files/models/metrics/`. Usually each plugin contributes its own metrics in separate JSON files. Click on the import button on the right of the metrics file to import it into the database.

The **Attributes** section lists files stored in `$ALAMBIC_HOME/mojo/lib/Alambic/files/models/attributes/`. Click on the import button on the right of the attributes file to import it into the database.

The **Quality Model** section lists files stored in `$ALAMBIC_HOME/mojo/lib/Alambic/files/models/qm/`. As of now, Alambic can have only one quality modle at a time, and installing a new quality model automatically replaces (and deletes) the previous one. Click on the import button on the right of the file to import it into the database.
