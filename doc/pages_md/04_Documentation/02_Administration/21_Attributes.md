title: Attributes
navi_name: Attributes

# Quality Attributes

So the chain looks like:

* Quality attribute **Ecosystem** is subdivided into:
    * Quality attribute **Diversity**
    * Quality attribute **Responsiveness**
    * Quality attribute **Activity** which is measured through:
        * Number of emails on the Dev ML (say during one week)
        * Number of messages on the User forums (say during one week)
        * Number of commits (say during one week)
        * Number of committed files (say during one week)

Indicators are then **aggregated** up from the leaves to the root of the quality model tree.

The Activity's value is the average of all its children. Other attributes are computed the same way, and values are aggregated up to the root of the quality model.

# File format

A working example of a JSON attributes definition file is provided in the source code at `/mojo/lib/Alambic/files/models/attributes`.

    {
        "name": "Alambic Attributes",
        "version": "0.1",
        "children": [
          {
            "name": "Project Maturity",
            "mnemo": "QM_QUALITY",
            "desc": [
                "The overall Maturity of the project.",
                "In the context of embedded software, Maturity is usually associated with some [SNIP]."
            ]
          }
        ]
    }
