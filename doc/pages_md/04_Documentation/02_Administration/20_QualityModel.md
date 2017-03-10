title: Quality Model
navi_name: QualityModel

One of the first things to setup when considering to use Alambic is the **quality model**.

In a nutshell, the quality model states **what** is important to you (*your* definition of quality, in this very context) and **how** to measure it. As an example, let's say we want to check the *activity* of our *community*. We decide to measure it through a set of metrics retrieved from mailing lists, forums and configuration management (git):

![polarsys_quality_model_adapted.png](/images/polarsys_quality_model_adapted.png)

So the chain looks like:

* Quality attribute **Ecosystem** is subdivided into:
    * Quality attribute **Diversity**
    * Quality attribute **Responsiveness**
    * Quality attribute **Activity** which is measured through:
        * Number of emails on the Dev ML (say during one week)
        * Number of messages on the User forums (say during one week)
        * Number of commits (say during one week)
        * Number of committed files (say during one week)

On the other hand from the bottom up **measures** are converted to **indicators** using a 4-thresholds **scale**. Indicators are then **aggregated** up from the leaves to the root of the quality model tree. As an example:

* Metric 'Number of commits' has value 56 and a scale such as [5,10,50,100] => Indicator 'Number of commits' has value 4 out of 5
* Metric 'Number of commmitted files' has value 13 and a scale such as [5,10,50,100] => Indicator 'Number of committed files' has value 3 out of 5
* Metric 'Number of emails' has value 24 and a scale such as [5,10,25,50] => Indicator 'Number of commits' has value 3 out of 5
* Metric 'Number of messages' has value 7 and a scale such as [5,10,25,50] => Indicator 'Number of commits' has value 2 out of 5

The Activity's value is the average of all its children, which is in this case 3 out of 5. Other attributes are computed the same way, and values are aggregated up to the root of the quality model.

# Terminology

### Quality attributes

[Quality attributes](Attributes) represent features of quality you want to achieve, like maintainability (for product quality) or activity (for community quality). Since everybody has a different meaning for such characteristics, it is vital to precisely define them to setup a semantic foundation for all participants. It is a good idea to rely on existing models for these definitions, like ISO 9126 or ISO 250xx.

## Indicators

Indicators range from 1 (bad) to 5 (excellent). They are entirely subjective, since they will vary depending on the project's context and on people's understanding of what is good or not. In other words they are a localised judgement on the raw numbers collected from the data sources.

## Scales

Scales define what is bad, good or excellent regarding the collected numbers. They are a way of *adapting* raw numbers to the local context.

Scales provide thresholds, so they are defined as an array of 4 integers as in: [15, 30, 50, 80]. In this case, percentages from 0 to 15% would be classified 1/5, from 16 to 30% would be 2/5, from 31 to 50% would be 3/5, from 51 to 80% would be 4/5, and over 81% would be 5/5.

![alambic_presentation_metrics.jpeg](/images/alambic_presentation_metrics.jpeg)

It should be noted that:

* Different tools may induce a different meaning for the same metric. With Git, having a huge number of branches is considered normal, since most projects use branches to develop new features and fixes. In subversion a similar high number of branches would probably indicate a bad branch management.
* Different processes or contexts may also impact scales: some projects try to treat and close bugs as soon as possible while others let them exist for a very long time, until someone simply treat them. Those are different ways of managing issues, none is really wrong, just choose yours and apply sensible limits.

## Metrics

Metrics are the base measures used to assess the quality model. Examples of metrics include `Number of emails sent on the developer mailing list during last week` or `Number of commits during last week`.


# File format

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