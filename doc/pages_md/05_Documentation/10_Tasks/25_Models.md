title: Models
navi_name: Models

# Customising Models

## Models (quality model, quality attributes, metrics)

The quality model, quality attributes and metrics are stored in the database. They are usually imported from JSON files, stored in distinct folders of the install:

Quality model is defined TODO

`$ALAMBIC_HOME/mojo/lib/Alambic/files/models`

# Attributes File format

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


# Metrics File format

A working example of a JSON metrics definition file is provided in the source code at `/mojo/lib/Alambic/files/models/metrics`.

    {
        "name": "Alambic Metrics for Issue Tracking",
        "version": "0.1",
        "children": [
    	{
                "name": "ITS issues opened lifetime",
                "mnemo": "ITS_OPENED",
                "desc": [
    		"Number of issues opened during the overall time range covered by the analysis.",
    		"The subset of tickets considered from the issue tracking system are those specified [SNIP]."
                ],
                "scale": [1,2,3,4]
    	}
        ]
    }


# Quality Model File format

The quality model is defined as a json file. A working example of a JSON quality model is provided in the source code at `/mojo/lib/Alambic/files/models/qm`.

    {
        "name": "Alambic Quality Model",
        "version": "0.1",
        "children": [
          {
            "mnemo" => "ATTR1",
            "type" => "attribute",
            "active": "true",
            "children" => [
              {
                "mnemo" => "METRIC1",
                "type" => "metric",
                "active": "true",
              }
            ]
          }
        ];
    }
