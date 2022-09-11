title: The Alambic project
navi_name: Alambic


<div class="row">
  <div class="col-lg-6">

  <h1>Welcome to the Alambic project</h1>

  <p class="lead"><b>Alambic</b> is an <b>open-source platform and service</b> for the management and visualisation of software engineering data. </p>

    <br />

    <p>It basically <b>retrieves data from various repositories</b> (code metrics, scm metadata, stack overflow questions, etc.) and <b>makes them available for custom plugins to produce analysis, numbers, graphics, and data sets</b>. All generated files are by default anonymised using the <a href="https://github.com/borisbaldassari/data-anonymiser">Anonymise</a> utility, so as to keep a fair balance between research usability and privacy protection.</p>

    <p>A <b>flexible plugin system</b> allows to easily add new data sources (e.g. git or svn logs, bugzilla queries), analysis tools (including R scripts), visualisation and reporting (e.g. knitr or plotly graphs). Examples of plugins ready to use include <a href="/Plugins/Pre/PmdAnalysis.html">PMD Results Analysis</a>, <a href="/Plugins/Pre/StackOverflow.html">StackOverflow questions</a> and <a href="/Plugins/Pre/EclipsePmi.html">PMI Checks for Eclipse projects</a>. <b></p>

    <p>Check the complete list of plugins in the <a href="/Plugins.html">Plugins section</a>.</b></p>

    <p>Measures are aggregated in a tree-like <b>quality model</b> structure to better organise and understand the information. The <a href="/Documentation/Users/QualityModel.html">Quality Model</a> can be entirely customised, and almost any type of data source can be added through plugins. </p>
    <br />
    <p>Alambic Tests status: <a href="http://art.castalia.camp:8080/job/alambic-test">
  	  <img alt="Jenkins CI build status" src="http://art.castalia.camp:8080/job/alambic-test/job/master/lastBuild/badge/icon?job=alambic-test&build=last">
    </a></p>
    <p>Alambic Docker image status: <a href="http://art.castalia.camp:8080/job/alambic-ci">
  	  <img alt="Jenkins CI build status" src="http://art.castalia.camp:8080/job/alambic-ci/job/master/lastBuild/badge/icon?job=alambic-ci&build=last">
    </a></p>
  </div>
  <div class="col-lg-6" style="font-size: 100%">
      <img src="/images/alambic.jpg" align="left" width="100%" style="margin:10px; max-width:600px" alt="alambic" />
  </div>
</div>

-----

<div class="row">
  <div class="col-lg-2 text-center">
    <a href="https://bitbucket.org/BorisBaldassari/alambic"><i class="fa fa-bitbucket fa-2x"></i><br />
      BitBucket
    </a>
  </div>
  <div class="col-lg-2 text-center">
    <a href="/About.html"><i class="fa fa-flask fa-2x"></i><br />
    About Alambic
    </a>
  </div>
  <div class="col-lg-2 text-center">
    <a href="/Plugins.html"><i class="fa fa-cubes fa-2x"></i><br />
      Plugins
    </a>
  </div>
  <div class="col-lg-2 text-center">
    <a href="/Setup.html"><i class="fa fa-bolt fa-2x"></i><br />
    Setup
    </a>
  </div>
  <div class="col-lg-2 text-center">
    <a href="/Documentation.html"><i class="fa fa-life-ring fa-2x"></i><br />
    Documentation
    </a>
  </div>
  <div class="col-lg-2 text-center">
    <a href="/Development.html"><i class="fa fa-code fa-2x"></i><br />
    Development
    </a>
  </div>
</div>
