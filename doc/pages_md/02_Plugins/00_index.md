title: Alambic plugins
navi_name: Plugins
al_list_items: true


**Pre-plugins** basically collect data from a repository, and run single-source analysis on it. Plugins first collect the data and then optionnaly run checks and actions, then compute metrics or visualisation objects. Once all pre-plugins have been executed, the attributes are computed and the quality model is populated.

Then the **post-plugins** are executed, and have access to all data retrieved and computed by pre-plugins. Once the project has been successfully analysed results are displayed in the dashboard section. This section provides several pages to analyse the project's situation and zoom into the details when needed. The plugins tab displays the visualisation output of installed plugins.

Once all projects have been executed, **global plugins** are executed. They have access to data, information, recommendations, metrics and attributes from all projects and provide instance-wide insights and analysis.

Other types of plugins include:

* **Tools** used to retrieve, parse and analyse data, such as the R engine or the Git configuration management tool.
* **Wizards** enable administrators to easily setup a new project according to the settings of a specific forge. An example of wizard is the <a href="/Plugins/Wizards/EclipsePmi.html">Eclipse PMI Wizard</a>.
