title: Admin > Projects
navi_name: Projects

# Admin > Projects

This section displays the list of projects, or all information about a single selected project. Administrators can add, edit or delete projects from this page.


## Proxies

Most plugins have a proxy field to access remote resources.

* Blank means no proxy
* `default` means use env vars; i.e. check environment variables HTTP_PROXY, http_proxy, HTTPS_PROXY, https_proxy, NO_PROXY and no_proxy for proxy information. Automatic proxy detection can be enabled with the MOJO_PROXY environment variable. See [Mojo::UserAgent documentation](http://mojolicious.org/perldoc/Mojo/UserAgent/Proxy) for more details on this feature.
* Anything else means use that proxy.

Various types of proxies are supported:

* HTTP CONNECT for HTTPS/WebSockets, e.g. `http://127.0.0.1:8080`
* SOCKS5, e.g. `socks://127.0.0.1:9050`
* UNIX domain socket, e.g. `http+unix://%2Ftmp%2Fproxy.sock`

For authentication put credentials in the URL itself, as in `http://sri:secret@127.0.0.1:8080`. 
Please note that any weird character must be URL-encoded.

## All projects UI

Displays the list of all projects and links to create new ones. 

![Alambic Admin Web UI](/images/admins_projects.png)

The list of projects proposes some basic information on each project, and actions to create a new project. New projects can be created either empty, or using a wizard.

* Project ID, e.g. `modeling.sirius`
* Project name, e.g. `Sirius`
* Is active, e.g. Yes or No.
* Last update, the last time a complete analysis has been run (only complete analyses store their results in database), e.g. 2017-11-23 10:54:45
* A series of actions to:
  - show the project's details
  - start a full analysis (i.e. submit a job)
  - delete the project (warning: this action cannot be undone!)

## Information displayed for a single project

Displays all information pertaining to a single project, and means to edit the plugins, run a complete or partial analysis, and set the project's parameters (name, description, active, etc.).

![Alambic Admin Web UI](/images/admins_projectpng)

* Project ID, e.g. `modeling.sirius`
* Project name, e.g. `Sirius`
* Project description, e.g. `Eclipse Sirius enables the specification of a modeling ....`
* Is active, e.g. Yes or No.
* Last run, the last time a complete analysis has been run (only complete analyses store their results in database), e.g. `2017-11-23 10:54:45`

It also shows the information available from the latest analysis, with links to go to the dedicated pages:

* Info
* Data
* Figures
* Metrics
* Indicators
* Attributes
* Recommendations

It also shows the list of runs and generated files.
