title: Eclipse PMI
navi_name: EclipsePmi

# Eclipse PMI

This plugin retrieves information from [the PMI repository](http://projects.eclipse.org) and checks for inconsistencies and bad data in its entries.

The Project Management Infrastructure is described in the Eclipse wiki:

* [https://wiki.eclipse.org/Project_Management_Infrastructure](https://wiki.eclipse.org/Project_Management_Infrastructure)
* [https://wiki.eclipse.org/Project_Management_Infrastructure/Overview](https://wiki.eclipse.org/Project_Management_Infrastructure/Overview)
* [https://wiki.eclipse.org/Project_Management_Infrastructure/Development](https://wiki.eclipse.org/Project_Management_Infrastructure/Development)
* [https://wiki.eclipse.org/Project_Management_Infrastructure/Technology_Choices](https://wiki.eclipse.org/Project_Management_Infrastructure/Technology_Choices)
* [https://wiki.eclipse.org/Project_Management_Infrastructure/Overview_and_Design](https://wiki.eclipse.org/Project_Management_Infrastructure/Overview_and_Design)

Check the [plugin Perl documentation](http://alambic.io/perldoc/Alambic/Plugins/EclipsePmi.pm.html) in the [perldoc](http://alambic.io/perldoc/index.html) section.

-----

# Basic information

* **ID**: EclipsePmi
* **Abilities**: metrics, info, data, recs, viz
* **Description**:
  Eclipse PMI Retrieves meta data about the project from the Eclipse PMI infrastructure.
See the project's wiki for more information.
* **Parameters**:
  * `project_pmi` The project ID used to identify the project on the PMI server. Look for it in the URL of the project on [http://projects.eclipse.org](http://projects.eclipse.org).

-----

# Provides

## Downloads

* `pmi.json`: The PMI file as returned by the Eclipse repository (JSON).
* `pmi_checks.csv`: The list of PMI checks and their results (CSV).
* `pmi_checks.json`: The list of PMI checks and their results (JSON).

## Figures

## Information

MLS_DEV_URL, MLS_USR_URL, PMI_BUGZILLA_COMPONENT, PMI_BUGZILLA_CREATE_URL, PMI_BUGZILLA_PRODUCT, PMI_BUGZILLA_QUERY_URL, PMI_CI_URL, PMI_DESC, PMI_DOCUMENTATION_URL, PMI_DOWNLOAD_URL, PMI_GETTINGSTARTED_URL, PMI_ID, PMI_MAIN_URL, PMI_SCM_URL, PMI_TITLE, PMI_UPDATESITE_URL, PMI_WIKI_URL

## Metrics

* PMI_ITS_INFO,
  The quantity of ITS-related information made available through the PMI.
* PMI_SCM_INFO
  The quantity of SCM-related information made available through the PMI.

## Recommendations

PMI_EMPTY_BUGZILLA_CREATE, PMI_EMPTY_BUGZILLA_QUERY, PMI_EMPTY_CI, PMI_EMPTY_DEV_ML, PMI_EMPTY_DOC, PMI_EMPTY_DOWNLOAD, PMI_EMPTY_GETTING_STARTED, PMI_EMPTY_PLAN, PMI_EMPTY_PROPOSAL, PMI_EMPTY_REL, PMI_EMPTY_SCM, PMI_EMPTY_TITLE, PMI_EMPTY_UPDATE, PMI_EMPTY_USER_ML, PMI_EMPTY_WEB, PMI_EMPTY_WIKI, PMI_NOK_BUGZILLA_CREATE, PMI_NOK_BUGZILLA_QUERY, PMI_NOK_CI, PMI_NOK_DEV_ML, PMI_NOK_DOC, PMI_NOK_DOWNLOAD, PMI_NOK_GETTING_STARTED, PMI_NOK_PLAN, PMI_NOK_PROPOSAL, PMI_NOK_SCM, PMI_NOK_UPDATE, PMI_NOK_USER_ML, PMI_NOK_WEB, PMI_NOK_WIKI

## Visualisation

* Eclipse PMI Checks

# PMI Checks

* PMI_EMPTY_BUGZILLA_PRODUCT
  The Bugzilla product entry is empty in the PMI. People willing to enter a bug for the first time will look for it.
* PMI_EMPTY_BUGZILLA_CREATE
  The Bugzilla URL entry to create a bug is empty in the PMI. People willing to enter a bug for the first time will look for it.
* PMI_NOK_BUGZILLA_CREATE
  The Bugzilla URL entry to create bug in the PMI cannot be accessed.
* PMI_EMPTY_BUGZILLA_QUERY
  The Bugzilla URL entry to query bugs is empty in the PMI. People willing to search for a bug for the first time will look for it.
* PMI_NOK_BUGZILLA_QUERY
  The Bugzilla URL entry to query bugs in the PMI cannot be accessed. People willing to search for a bug for the first time will look for it.
* PMI_EMPTY_TITLE
  The title entry is empty in the PMI.
* PMI_NOK_WEB
  The web site URL cannot be retrieved in the PMI. The URL should be checked.
* PMI_EMPTY_WEB
  The web site URL is missing in the PMI.
* PMI_NOK_WIKI
  The wiki URL in the PMI cannot be retrieved. It helps people understand and use the product and should be fixed.
* PMI_EMPTY_WIKI
  The wiki URL is missing in the PMI. It helps people understand and use the product and should be filled.
* PMI_NOK_DOWNLOAD
  The download URL cannot be retrieved in the PMI. People need it to download, use, and contribute to the project and should be correctly filled
* PMI_EMPTY_DOWNLOAD
  The download URL is empty in the PMI. People need it to download, use, and contribute to the project and should be correctly filled.
* PMI_NOK_GETTING_STARTED
  The getting started URL cannot be retrieved in the PMI. It helps people use, and contribute to, the project and should be correctly filled.
* PMI_EMPTY_GETTING_STARTED
  The getting started URL is empty in the PMI. It helps people use, and contribute to, the project and should be correctly filled.
* PMI_NOK_DOC
  The documentation URL cannot be retrieved in the PMI. It helps people use, and contribute to, the project and should be correctly filled.
* PMI_EMPTY_DOC
  The documentation URL is empty in the PMI. It helps people use, and contribute to, the project and should be correctly filled.
* PMI_NOK_PLAN
  The plan document URL cannot be retrieved in the PMI. It helps people understand the roadmap of the project and should be correctly filled.
* PMI_EMPTY_PLAN
  The plan document URL is empty in the PMI. It helps people understand the roadmap of the project and should be filled.
* PMI_NOK_PROPOSAL
  The proposal document URL cannot be retrieved in the PMI. It helps people understand the genesis of the project and should be correctly filled.
* PMI_EMPTY_PROPOSAL
  The proposal document URL is empty in the PMI. It helps people understand the genesis of the project and should be filled.
* PMI_NOK_DEV_ML
  The developer mailing list URL in the PMI cannot be retrieved. It helps people know where to ask questions if they want to contribute.
* PMI_EMPTY_DEV_ML
  The developer mailing list URL is empty in the PMI. It helps people know where to ask questions if they want to contribute.
* PMI_NOK_USER_ML
  The user mailing list / forum URL in the PMI cannot be retrieved. It helps people know where to ask questions if they want to use the product and should be fixed.
* PMI_EMPTY_USER_ML
  The user mailing list URL is empty in the PMI. It helps people know where to ask questions if they want to use the product and should be filled.
* PMI_NOK_SCM
  The source repository URL in the PMI cannot be retrieved. People need it if they want to contribute to the product, and it should be fixed.
* PMI_EMPTY_SCM
  The source repository URL is empty in the PMI. People need it if they want to contribute to the product, and it should be filled.
* PMI_NOK_UPDATE
  The update site URL in the PMI cannot be retrieved. People need it if they want to use the product, and it should be fixed.
* PMI_EMPTY_UPDATE
  The update site URL is empty in the PMI. People need it if they want to use the product, and it should be filled.
* PMI_NOK_CI
  The Hudson CI engine URL [$url] in the PMI is not detected as the root of a Hudson instance.
* PMI_EMPTY_CI
  The Hudson CI engine URL [$url] in the PMI is empty.
* PMI_EMPTY_REL
  There is no release defined in the PMI. Adding releases helps people evaluate the evolution and organisation of the project.

-----

# Screenshot

![eclipse_pmi.png](/images/eclipse_pmi.png)
