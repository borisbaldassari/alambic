title: Terminology
navi_name: Terminology


# Terminology

## Quality attributes

**Quality attributes** represent features of quality you want to achieve, like maintainability (for product) or activity (for community). It is defined on a scale from 1 (poor) to 5 (excellent). Attributes also have a confidence interval (e.g. 5/7) that shows how many metrics were actually used to compute it, compared to the total number of metrics that should have been used (in the case of missing metrics).

Since everybody has a different meaning for such characteristics, it is vital to precisely define them to setup a semantic foundation for all participants. It is a good idea to rely on existing models for these definitions, like ISO 9126 or ISO 250xx.

The complete list of attributes for an Alambic instance is self-documented on the instance itself, in the Documentation > Attributes section. En example can be found on one of the demonstration instances, e.g. [eclipse.alambic.io](http://eclipse.castalia.camp/documentation/attributes.html).

In Alambic attributes are defined through an ID, a name, and a description. See [Admins > Models](/Documentation/Admins/Models.html) for more details about the JSON format.

## Indicators

Indicators range from 1 (bad) to 5 (excellent). They are entirely subjective, since they will vary depending on the project's context and on people's understanding of what is good or not. In other words they are a localised judgement on the raw numbers collected from the data sources.

Indicators are computed from metrics using the scales.

## Scales

Scales define what is bad, good or excellent regarding the collected numbers. They are a way of *adapting* raw numbers to the local context and give hints about the interpretation of numbers.

Scales provide thresholds, so they are defined as an array of 4 integers as in: `[15, 30, 50, 80]`. In this case, percentages from 0 to 15% would be classified 1/5, from 16 to 30% would be 2/5, from 31 to 50% would be 3/5, from 51 to 80% would be 4/5, and over 81% would be 5/5.

![alambic_presentation_metrics.jpeg](/images/alambic_presentation_metrics.jpeg)

It should be noted that:

* Different tools may induce a different meaning for the same metric. With Git, having a huge number of branches is considered normal, since most projects use branches to develop new features and fixes. In subversion a similar high number of branches would probably indicate a bad branch management.
* Different processes or contexts may also impact scales: some projects try to treat and close bugs as soon as possible while others let them exist for a very long time, until someone simply treat them. Those are different ways of managing issues, none is really wrong, just choose yours and apply sensible limits (i.e. scales).

## Metrics

Metrics are the base measures used to assess the quality model. Examples of metrics include `Number of emails sent on the developer mailing list during last week` or `Number of commits during last week`.

The complete list of metrics for an Alambic instance is self-documented on the instance itself, in the Documentation > Metrics section. En example can be found on one of the demonstration instances, e.g. [eclipse.alambic.io](http://eclipse.castalia.camp/documentation/metrics.html).

In Alambic metrics are defined through an ID, a name, description, and an associated scale. See [Admins > Models](/Documentation/Admins/Models.html) for more details about the JSON format.
