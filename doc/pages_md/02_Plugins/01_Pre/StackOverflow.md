title: Stack Overflow
navi_name: StackOverflow


# Stack Overflow

The Stack Overflow plugin retrieves [Stack Overflow](https://stackoverflow.com) questions and answers related to the project tag, and provides a summary, a list of hot questions and recommendations to ensure a fine support to users on the web site.

Check the [plugin Perl documentation](http://alambic.io/perldoc/Alambic/Plugins/StackOverflow.pm.html) in the [perldoc](http://alambic.io/perldoc/index.html) section.

----

# Basic information

* **ID**: StackOverflow
* **Abilities**: metrics, figs, recs, viz
* **Description**:
  Retrieves questions and answers related to a specific tag from the Stack Overflow question/answer web site.
* **Parameters**:
    * `so_keyword` A Stack Overflow tag to retrieve questions from.

-----

# Provides

## Metrics

* SO_QUESTIONS_VOL_5Y
* SO_ANSWERS_VOL_5Y
* SO_ANSWER_RATE_5Y
* SO_VOTES_VOL_5Y
* SO_VIEWS_VOL_5Y
* SO_ASKERS_5Y

## Figures

* hudson_pie.html A pie chart of the status of jobs.

## Recommendations

* SO_IMPROVE_SUPPORT
* SO_WATCH_QUESTION

## Visualisation

* Stack Overflow

-----

Notes:

* The queried time range spans the last 5 years.
* The Stack Overflow API uses daily quotas. Default is 300. If the Alambic instance exceeds this volume a OAuth-based setup is required.

Dependencies:

This plugin requires for execution a working R environment, and the following packages:

* ggplot2
* snowballC
* wordcloud
* tm
* xtable
* xts

-----

# Screenshot

![Capture du 2016-09-26 11-41-16.png](/images/Capture%20du%202016-09-26%2011-41-16.png)
