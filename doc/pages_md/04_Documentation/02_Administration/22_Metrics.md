title: Metrics
navi_name: Metrics

# Metrics

# Indicators

On the other hand from the bottom up **measures** are converted to **indicators** using a 4-thresholds **scale**. Indicators are then **aggregated** up from the leaves to the root of the quality model tree. As an example:

* Metric 'Number of commits' has value 56 and a scale such as [5,10,50,100] => Indicator 'Number of commits' has value 4 out of 5
* Metric 'Number of commmitted files' has value 13 and a scale such as [5,10,50,100] => Indicator 'Number of committed files' has value 3 out of 5
* Metric 'Number of emails' has value 24 and a scale such as [5,10,25,50] => Indicator 'Number of commits' has value 3 out of 5
* Metric 'Number of messages' has value 7 and a scale such as [5,10,25,50] => Indicator 'Number of commits' has value 2 out of 5

The Activity's value is the average of all its children, which is in this case 3 out of 5. Other attributes are computed the same way, and values are aggregated up to the root of the quality model.

# File format

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
