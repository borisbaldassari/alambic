title: Customising Alambic
navi_name: Customise

# Customising Alambic

## The templating system

Mojolicious -- and Alambic -- use embedded Perl as a [templating system](http://www.mojolicious.org/perldoc/Mojolicious/Guides/Rendering). It is  basically composed of pure HTML and Perl code snippets and can be easily customised to display different layouts or types of information. Mojolicious generates pages according to:

* A [layout](http://www.mojolicious.org/perldoc/Mojolicious/Guides/Rendering#Layouts) that provides headers and footers and defines the overall site look and feel (i.e. theme). One can have several layouts and switch forth and back. The default layout used in Alambic is defined in `$ALAMBIC_HOME/mojo/lib/Alambic/files/templates/layouts/`.

* Distinct [embedded Perl](http://www.mojolicious.org/perldoc/Mojolicious/Guides/Rendering#Embedded-Perl) pages for the different pages of the web site. These really define the content and design of each page and can be found for Alambic in `$ALAMBIC_HOME/mojo/lib/Alambic/files/templates/alambic/`.

## Example pages

All pages are stored in `$ALAMBIC_HOME/mojo/lib/Alambic/files/templates/alambic/*`.

* The user dashboard UI pages can be found in `$ALAMBIC_HOME/mojo/lib/Alambic/files/templates/alambic/dashboard/*`.
* Project Summary is `$ALAMBIC_HOME/mojo/lib/Alambic/files/templates/alambic/dashboard/dashboard.html.ep`.
* Quality Model is `$ALAMBIC_HOME/mojo/lib/Alambic/files/templates/alambic/dashboard/qm.html.ep`.
* History is `$ALAMBIC_HOME/mojo/lib/Alambic/files/templates/alambic/dashboard/history.html.ep`.

The existing files (along with all `*.html.ep` files in the `$ALAMBIC_HOME/mojo/Alambic/files/templates/alambic`) can also serve as examples.
