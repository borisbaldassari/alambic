title: Quality Model
navi_name: QualityModel


# The Alambic quality model

One of the first things to setup when considering to use Alambic is the **quality model**.

In a nutshell, the quality model states **what** is important to you (*your* definition of quality, in this very context) and **how** to measure it. It makes the link between the quality attributes and the metrics gathered or computed by Alambic.

**Note**
See the definition of quality attributes, indicators, metrics and scales in the [Terminology section](/Documentation/Basics/Terminology.html).

## Structure

The quality model is defined as a tree structure. The main quality attribute (at the root of the tree) is the main rating for the project (e.g. Project's Quality or Maturity). Each attribute is computed from its children, up to the leaves of the tree: the metrics retrieved or computed by Alambic.

As an example, let's say we want to check the *activity* of our *ecosystem*. We decide to measure it through a set of metrics retrieved from mailing lists, forums and configuration management (git):

![quality_model.png](/images/basic_quality_model.png)

When the project is analysed, **metrics** are populated, converted to **indicators** using **scales**, and aggregated up to the root of the quality model.

## Aggregating values

So from top to bottom the chain looks like:

* Quality attribute **Ecosystem** is subdivided into:
    * Quality attribute **Activity** which is measured through:
        * Number of emails on the Dev ML (say during one week)
        * Number of messages on the User forums (say during one week)
        * Number of commits (say during one week)
        * Number of committed files (say during one week)
    * Quality attribute **Diversity**
    * Quality attribute **Responsiveness**

On the other hand from the bottom up **measures** are converted to **indicators** using a 4-thresholds **scale**. Indicators are then **aggregated** up from the leaves to the root of the quality model tree. As an example:

* Metric 'Number of commits' has value `56` and a scale such as `[5,10,50,100]` => Indicator 'Number of commits' has value 4 out of 5
* Metric 'Number of commmitted files' has value `13` and a scale such as `[5,10,50,100]` => Indicator 'Number of committed files' has value 3 out of 5
* Metric 'Number of emails' has value `24` and a scale such as `[5,10,25,50]` => Indicator 'Number of emails' has value 3 out of 5
* Metric 'Number of messages' has value `7` and a scale such as `[5,10,25,50]` => Indicator 'Number of messages' has value 2 out of 5

The Activity's value is the average of all its children, which is in this case 3 out of 5. Other attributes are computed the same way, and values are aggregated up to the root of the quality model.
