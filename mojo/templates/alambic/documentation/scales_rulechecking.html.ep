
              <h3>Scales &gt; Rule-checking</h3>

              <p>Well-known open-source tools like PMD and FindBugs help projects find bad patterns in their code: e.g. naming conventions, idiomatic usage, common errors. These rules can be considered as <em>coding practices</em> in the project, and are classified according to the quality attribute(s) they impact.</p> 
              <p>There are two important informations we retrieve from the output of these tools: firstly the number of violations for each category (analysability, changeability, etc.), which shows the effort needed to get rid of a bad practice or acquire a new good practice. The second measure is the percentage of acquired practices, which is the amount of rules <em>never</em> violated in the project.</p>
              <p>One may want to address first the rules that are only violated a couple of times, so it is easy to acquire this practice by simply removing the few violations. By doing such small steps the project can really learn from it and improve its practices.</p>
              
              <p>The evaluation for rules is manual, since it implies compiling the code or retrieving binaries (class files) for FindBugs. To setup the scales, we selected a list of projects and applied our analysis script on the resulting set.</p>
              
              <hr />
              
              <h4>Thresholds</h4>

              <p>The initial set of thresholds for metrics for rules impacting <strong>Analysability</strong> is the following.</p>
              
              <ul class="list-group">
                <li class="list-group-item">
                  <a href="metrics.html#NCC_ANA_IDX"><strong>Average number of non-conformities for analysability</strong></a> (NCC_ANA_IDX)<br />
                  <p><span class="label label-scale" style="background-color: #FFFF66"> 1 </span> &lt; 1 &le; <span class="label label-scale" style="background-color: #CCF24D;"> 2  </span> &lt; 0.5 &le; <span class="label label-scale" style="background-color: #99E633;"> 3  </span> &lt; 0.3 &le; <span class="label label-scale" style="background-color: #66D91A;"> 4  </span> &lt; 0.1 &le; <span class="label label-scale" style="background-color: #33CC00;"> 5 </span></p>
                </li>
                <li class="list-group-item">
                  <a href="metrics.html#ROKR_ANA"><strong>Adherence to analysability rules</strong></a> (ROKR_ANA)<br />
                  <p><span class="label label-scale" style="background-color: #FFFF66"> 1 </span> &lt; 10 &le; <span class="label label-scale" style="background-color: #CCF24D;"> 2 </span> &lt; 30 &le; <span class="label label-scale" style="background-color: #99E633;"> 3 </span> &lt; 50 &le; <span class="label label-scale" style="background-color: #66D91A;"> 4 </span> &lt; 75 &le; <span class="label label-scale" style="background-color: #33CC00;"> 5 </span></p>
                </li>
              </ul>
              
              <p>The initial set of thresholds for metrics for rules impacting <strong>Changeability</strong> is the following.</p>
              
              <ul class="list-group">
                <li class="list-group-item">
                  <a href="metrics.html#NCC_CHA_IDX"><strong>Average number of non-conformities for changeability</strong></a> (NCC_ANA_IDX)<br />
                  <p><span class="label label-scale" style="background-color: #FFFF66"> 1 </span> &lt; 3 &le; <span class="label label-scale" style="background-color: #CCF24D;"> 2  </span> &lt; 1 &le; <span class="label label-scale" style="background-color: #99E633;"> 3  </span> &lt; 0.5 &le; <span class="label label-scale" style="background-color: #66D91A;"> 4  </span> &lt; 0.3 &le; <span class="label label-scale" style="background-color: #33CC00;"> 5 </span></p>
                </li>
                <li class="list-group-item">
                  <a href="metrics.html#ROKR_CHA"><strong>Adherence to changeability rules</strong></a> (ROKR_ANA)<br />
                  <p><span class="label label-scale" style="background-color: #FFFF66"> 1 </span> &lt; 10 &le; <span class="label label-scale" style="background-color: #CCF24D;"> 2 </span> &lt; 30 &le; <span class="label label-scale" style="background-color: #99E633;"> 3 </span> &lt; 50 &le; <span class="label label-scale" style="background-color: #66D91A;"> 4 </span> &lt; 75 &le; <span class="label label-scale" style="background-color: #33CC00;"> 5 </span></p>
                </li>
              </ul>
              
              <p>The initial set of thresholds for metrics for rules impacting <strong>Reliability</strong> is the following.</p>
              
              <ul class="list-group">
                <li class="list-group-item">
                  <a href="metrics.html#NCC_REL_IDX"><strong>Average number of non-conformities for reliability</strong></a> (NCC_ANA_IDX)<br />
                  <p><span class="label label-scale" style="background-color: #FFFF66"> 1 </span> &lt; 1 &le; <span class="label label-scale" style="background-color: #CCF24D;"> 2  </span> &lt; 0.5 &le; <span class="label label-scale" style="background-color: #99E633;"> 3  </span> &lt; 0.3 &le; <span class="label label-scale" style="background-color: #66D91A;"> 4  </span> &lt; 0.1 &le; <span class="label label-scale" style="background-color: #33CC00;"> 5 </span></p>
                </li>
                <li class="list-group-item">
                  <a href="metrics.html#ROKR_REL"><strong>Adherence to reliability rules</strong></a> (ROKR_ANA)<br />
                  <p><span class="label label-scale" style="background-color: #FFFF66"> 1 </span> &lt; 10 &le; <span class="label label-scale" style="background-color: #CCF24D;"> 2 </span> &lt; 30 &le; <span class="label label-scale" style="background-color: #99E633;"> 3 </span> &lt; 50 &le; <span class="label label-scale" style="background-color: #66D91A;"> 4 </span> &lt; 75 &le; <span class="label label-scale" style="background-color: #33CC00;"> 5 </span></p>
                </li>
              </ul>
              
              <p>The initial set of thresholds for metrics for rules impacting <strong>Reusability</strong> is the following.</p>
              
              <ul class="list-group">
                <li class="list-group-item">
                  <a href="metrics.html#NCC_REU_IDX"><strong>Average number of non-conformities for reusability</strong></a> (NCC_ANA_IDX)<br />
                  <p><span class="label label-scale" style="background-color: #FFFF66"> 1 </span> &lt; 3 &le; <span class="label label-scale" style="background-color: #CCF24D;"> 2  </span> &lt; 1 &le; <span class="label label-scale" style="background-color: #99E633;"> 3  </span> &lt; 0.5 &le; <span class="label label-scale" style="background-color: #66D91A;"> 4  </span> &lt; 0.3 &le; <span class="label label-scale" style="background-color: #33CC00;"> 5 </span></p>
                </li>
                <li class="list-group-item">
                  <a href="metrics.html#ROKR_REU"><strong>Adherence to reusability rules</strong></a> (ROKR_ANA)<br />
                  <p><span class="label label-scale" style="background-color: #FFFF66"> 1 </span> &lt; 10 &le; <span class="label label-scale" style="background-color: #CCF24D;"> 2 </span> &lt; 30 &le; <span class="label label-scale" style="background-color: #99E633;"> 3 </span> &lt; 50 &le; <span class="label label-scale" style="background-color: #66D91A;"> 4 </span> &lt; 75 &le; <span class="label label-scale" style="background-color: #33CC00;"> 5 </span></p>
                </li>
              </ul>
              
              <hr />

              <h4>Discussion</h4>
              
              <p>The set of metrics used for the benchmark can be <a href="/data/metrics_rules_all.csv">downloaded here</a>.</p>
              
              <div class="row">
                <div class="col-xs-6">
                  <a href="/images/number_of_favourites_on_the_marketplace_for_eclipse_projects.svg" class="thumbnail">
                    <img src="/images/number_of_favourites_on_the_marketplace_for_eclipse_projects.svg" alt="...">
                  </a>
                </div>
                <div class="col-xs-6">
                  <p>People can select any number of projects as their favourites. This data is then displayed on the project's badge (in the UI) and made available through the Marketplace REST API. It shows the interest of people in projects. To improve this, some projects ask their users to go vote for them on the Marketplace.</p>
                </div>
              </div>
              <div class="row">
                <div class="col-xs-6">
                  <a href="/images/number_of_successful_install_on_the_marketplace_for_eclipse_projects.svg" class="thumbnail">
                    <img src="/images/number_of_successful_install_on_the_marketplace_for_eclipse_projects.svg" alt="...">
                  </a>
                </div>
              </div>
              
              <hr />

              <h4>List of projects used for the benchmark</h4>
              
              <ul class="list-group">
                <li class="list-group-item"><a href="https://www.polarsys.org/projects/polarsys.capella">Capella</a></li>
                <li class="list-group-item"><a href="http://www.eclipse.org/cdt/">CDT</a></li>
                <li class="list-group-item"><a href="https://www.eclipse.org/ease/">Eclipse Advanced Scripting Environment (EASE)</a></li>
                <li class="list-group-item"><a href="https://www.eclipse.org/egit">Egit</a></li>
                <li class="list-group-item"><a href="https://www.eclipse.org/emf/compare/">EMF-Compare</a></li>
                <li class="list-group-item"><a href="https://www.polarsys.org/projects/polarsys.capella">Capella</a></li>
                <li class="list-group-item"><a href="http://www.eclipse.org/proposals/modeling.gendoc/">Gendoc2</a></li>
                <li class="list-group-item"><a href="https://www.eclipse.org/hudson/">Hudson</a></li>
                <li class="list-group-item"><a href="http://www.eclipse.org/proposals/polarsys.kitalpha/">Kitalpha</a></li>
                <li class="list-group-item"><a href="http://www.eclipse.org/mylyn/">Mylyn</a></li>
                <li class="list-group-item"><a href="http://www.projects.eclipse.org/projects/tools.oomph">Oomph</a></li>
                <li class="list-group-item"><a href="http://www.eclipse.org/papyrus/">Papyrus</a></li>
                <li class="list-group-item"><a href="http://www.polarsys.org/projects/polarsys.reqcycle">ReqCycle</a></li>
                <li class="list-group-item"><a href="http://www.eclipse.org/sirius/">Sirius</a></li>
                <li class="list-group-item"><a href="http://www.eclipse.org/sisu/">Sisu</a></li>
                <li class="list-group-item"><a href="http://www.eclipse.org/subversive/">Subversive</a></li>
              </ul>
              
