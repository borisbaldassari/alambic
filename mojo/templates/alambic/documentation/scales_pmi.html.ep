
              <h3>Scales &gt; PMI</h3>

              <p>The PMI (Project Management Infrastructure) maintains a list of Eclipse projects with a set of associated meta data. It includes information about the various documentation pieces for the project (web site, wiki, getting started guide, etc.), the repositories used for development (code, bugzilla), and releases (date, milestones, review, etc.).</p>
              
              <p>To setup the scales, we retrieved the <a href="http://projects.eclipse.org/list-of-projects">complete list of projects</a> registered in the PMI repository (251 at the time of writing), and extracted our metrics on the resulting set. You can download it <a href="/data/metrics_pmi_all.csv">here</a> (CSV format) and play with the data at your wish.</p>
              
              <hr />
              
              <h4>Thresholds</h4>

              <p>The initial set of thresholds for metrics in PMI is the following.</p>

              <ul class="list-group">
                <li class="list-group-item">
                  <a href="metrics.html#PLAN_MILESTONES_VOL"><strong>Number of milestones</strong></a> (PLAN_MILESTONES_VOL)<br />
                  <p><span class="label label-scale" style="background-color: #FFFF66"> 1 </span> &lt; 1 &le; <span class="label label-scale" style="background-color: #CCF24D;"> 2  </span> &lt; 5 &le; <span class="label label-scale" style="background-color: #99E633;"> 3  </span> &lt; 10 &le; <span class="label label-scale" style="background-color: #66D91A;"> 4  </span> &lt; 20 &le; <span class="label label-scale" style="background-color: #33CC00;"> 5 </span></p>
                </li>
                <li class="list-group-item">
                  <a href="metrics.html#PLAN_REVIEWS_SUCCESS_RATE"><strong>Milestone success rate</strong></a> (PLAN_REVIEWS_SUCCESS_RATE)<br />
                  <p><span class="label label-scale" style="background-color: #FFFF66"> 1 </span> &lt; 20 &le; <span class="label label-scale" style="background-color: #CCF24D;"> 2  </span> &lt; 40 &le; <span class="label label-scale" style="background-color: #99E633;"> 3  </span> &lt; 60 &le; <span class="label label-scale" style="background-color: #66D91A;"> 4  </span> &lt; 80 &le; <span class="label label-scale" style="background-color: #33CC00;"> 5 </span></p>
                </li>
                <li class="list-group-item">
                  <a href="metrics.html#PUB_SCM_INFO_PMI"><strong>SCM information</strong></a> (PUB_SCM_INFO_PMI)<br />
                  <p><span class="label label-scale" style="background-color: #FFFF66"> 1 </span> &lt; 2 &le; <span class="label label-scale" style="background-color: #CCF24D;"> 2  </span> &lt; 3 &le; <span class="label label-scale" style="background-color: #99E633;"> 3  </span> &lt; 4 &le; <span class="label label-scale" style="background-color: #66D91A;"> 4  </span> &lt; 5 &le; <span class="label label-scale" style="background-color: #33CC00;"> 5 </span></p>
                </li>
                <li class="list-group-item">
                  <a href="metrics.html#PUB_ITS_INFO_PMI"><strong>ITS information</strong></a> (PUB_ITS_INFO_PMI)<br />
                  <p><span class="label label-scale" style="background-color: #FFFF66"> 1 </span> &lt; 2 &le; <span class="label label-scale" style="background-color: #CCF24D;"> 2  </span> &lt; 3 &le; <span class="label label-scale" style="background-color: #99E633;"> 3  </span> &lt; 4 &le; <span class="label label-scale" style="background-color: #66D91A;"> 4  </span> &lt; 5 &le; <span class="label label-scale" style="background-color: #33CC00;"> 5 </span></p>
                </li>
              </ul>
              
              <hr />
              
              <h4>Discussion</h4>
              
              <div class="row">
                <div class="col-xs-6">
                  <a href="#" class="thumbnail">
                    <img src="/images/percentage_of_release_reviews_marked_as_successful_for_eclipse_projects.svg" alt="percentage_of_release_reviews_marked_as_successful_for_eclipse_projects">
                  </a>
                </div>
                <div class="col-xs-6">
                  <p>The plot on the left shows the percentage of reviews marked as successful for the last five releases for our sample data set. Many projects have null values, most probably because the field was not correctly filled. By making sure the information is correct, projects allow their users to know what happened, enhancing transparency and predictability.</p>
                </div>
              </div>

              <div class="row">
                <div class="col-xs-6">
                  <a href="#" class="thumbnail">
                    <img src="/images/planning_management_number_of_milestones_during_the_last_5_releases_for_eclipse_projects.svg" alt="planning_management_number_of_milestones_during_the_last_5_releases_for_eclipse_projects">
                  </a>
                </div>
                <div class="col-xs-6">
                  <p>Projects can define as many milestones for each release as they want. Milestones allow to better evaluate and improve the maturity of the upcoming release, both for the project developers and users.</p>
                </div>
              </div>

              <div class="row">
                <div class="col-xs-6">
                  <a href="#" class="thumbnail">
                    <img src="/images/access_to_scm_its_information_in_pmi_for_eclipse_projects.svg" alt="access_to_scm_its_information_in_pmi_for_eclipse_projects">
                  </a>
                </div>
                <div class="col-xs-6">
                  <p>The PMI defines two fields for SCM (software configuration management) and ITS (issue tracking system). These provide all the information needed to access and use both systems, with urls (query, create) and parameters (e.g. component/product). Correctly filling these fields help users know and contribute to the project.</p>
                </div>
              </div>
              
