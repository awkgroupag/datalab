* [Requirements](#requirements)
* [Installation](#installation)
* [Usage](#usage)
  * [Windows](#windows)
  * [Linux and helm](#linux-and-helm)
* [Supported Stacks](#supported-stacks)
* [Additions/Tweaks to JupyerLab](#additionstweaks-to-jupyerlab)


# Eraneos Data Science Lab
* Get your Data Analytics environment up and running in seconds, using Kubernetes
* Add and remove technology stacks as needed
* Collaborate and share your environment easily even years later - being sure that everything still runs
* Control your Kubernetes environment through the Jupyter Notebook `controlboard` instead of command line arguments

## Requirements
* Windows:
  * WSL set-up (see [ACL Onboarding, setup for WSL](https://github.com/awkgroupag/ITA-ACL-Onboarding/blob/main/General_topics/dev-setup.md#wsl) for instructions on how to get WSL ready)
  * [Rancher Desktop](https://docs.rancherdesktop.io/getting-started/installation) installed
  * In the Rancher preferences, make sure that `Enable Traefik` is activated (it is enabled by default)
* Linux:
  * Another Kubernetes distribution up and running, e.g. [K3S](https://k3s.io/):
    ```console
    $ curl -sfL https://get.k3s.io | sh -
    ```
  * [Traefik deployed](https://doc.traefik.io/traefik/getting-started/install-traefik/) in your cluster before getting started. If you use K3S, Traefik should already have been deployed.
  * [helm](https://helm.sh/docs/intro/install/) installed:
    ```console
    $ curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
    $ chmod 700 get_helm.sh
    $ ./get_helm.sh
    ```
* A code version management like `git` (used below). Since we're using GitHub, try [GitHub Desktop](https://desktop.github.com/) that comes bundled with `git`.

### Test requirements with [Podinfo](https://github.com/stefanprodan/podinfo)
Open a command prompt/terminal and enter the following to install Podinfo:
```console
$ helm repo add podinfo https://stefanprodan.github.io/podinfo
"podinfo" has been added to your repositories

$ helm upgrade -i testrelease podinfo/podinfo
Release "testrelease" does not exist. Installing it now.
NAME: testrelease
LAST DEPLOYED: Tue Jul 19 08:05:01 2022
NAMESPACE: default
STATUS: deployed
REVISION: 1
NOTES:
1. Get the application URL by running these commands:
  echo "Visit http://127.0.0.1:8080 to use your application"
  kubectl -n default port-forward deploy/testrelease-podinfo 8080:9898
```
Check whether the Podinfo Kubernetes pod is running (`testrelease-podinfo-6d4c7fcd7d-zzsv9` below); `STATUS` should be `Running`. You might need to wait a bit.
```console
$ kubectl get pods -A

NAMESPACE     NAME                                      READY   STATUS      RESTARTS        AGE
kube-system   local-path-provisioner-6c79684f77-vm9hc   1/1     Running     1 (7m17s ago)   14m
kube-system   coredns-d76bd69b-pwsf7                    1/1     Running     1 (7m17s ago)   14m
kube-system   svclb-traefik-60fa6f09-qwz7p              2/2     Running     0               5m14s
kube-system   helm-install-traefik-crd-2qjhl            0/1     Completed   0               5m38s
kube-system   helm-install-traefik-hsrgq                0/1     Completed   0               5m38s
kube-system   metrics-server-7cd5fcb6b7-h5g98           1/1     Running     1 (7m17s ago)   14m
kube-system   traefik-df4ff85d6-wx9nt                   1/1     Running     1 (7m17s ago)   13m
default       testrelease-podinfo-6d4c7fcd7d-zzsv9       1/1     Running     0               46s
```
To actually connect to your Podinfo pod within Kubernetes, follow the `NOTES:` that the `helm upgrade -i` command above printed - port `9898` might be different for you! The next command will **not return** (prompt seems to hang).
```console
$ kubectl -n default port-forward deploy/testrelease-podinfo 8080:9898
Forwarding from 127.0.0.1:8080 -> 9898
Forwarding from [::1]:8080 -> 9898
```
Using a browser, go to `localhost:8080`. You should get a friendly greeting from a kraken.

Once your test has been successful, return to the command prompt, hit `CTRL+C` to stop the port-forwarding and have the command prompt return. Remove Podinfo from Kubernetes:
```console
$ helm delete testrelease
release "testrelease" uninstalled
```

## Installation
### 1. Create the directory structure for your new project
* Create a new dedicated directory for your source code on your local machine where you want the Data Science Lab to run
* Download this entire data science lab's sourcecode:
  1. Hit the green `Code`-button on GitHub, then `Download ZIP`
  2. Unzip the downloaded ZIP-file into the source code folder you just created
  3. **Important**: rename the folder you justed unzipped from `datalab-master` to `datalab`
* Create another dedicated directory for your data - NOT within the source code directory since you don't want to upload your data to the internet

Resulting example folder structure for a new project `my_new_project` - **only the directory `datalab` is tracked with `git`/GitHub!**
> :warning: This prevents you uploading customer data to GitHub, potentially open for everyone to see :warning:
```
my_new_project
├──datalab
|  ├──lab
|  |  ├──elastic
|  |  |  └──...
|  |  ├──jupyter
|  |  |  └──...
|  |  ├──modules
|  |  |  └──...
|  |  ├──resources
|  |  |  └──...
|  |  ├──controlboard.ipynb
|  |  ├──database_getting_started.ipynb
|  |  ├──database_SAP_S4HANA.ipynb
|  |  ├──myvalues.yaml.EXAMPLE
|  ├──resources
|  |  └──...
|  ├──.gitignore
|  ├──delete_controlboard.cmd
|  ├──delete_jupyter.cmd
|  ├──README.md
|  ├──run_controlboard.cmd
|  └──run_jupyter.cmd
|
|
├──data
|  └──...
```

### 2. Define your project in a `myvalues.yaml`
Change the values in the file `./lab/myvalues.yaml.EXAMPLE`. Save the customized file as a new file `./lab/myvalues.yaml`. `myvalues.yaml` will not be saved, version-tracked and uploaded by git/GitHub - edit `.gitignore` if you don't want that. 

Normally, you will need to set only 4 variables:
* `sourcecodeDirectory`: the new directory you just created above, containing all your source code, including the folder `datalab`. The folder you map here will appear as `/home/jovyan/work` in the Jupyter Notebook
* `dataDirectory`: the directory containing all data. Will be mounted as `/home/jovyan/data` in the Notebook
* `namespace`: The Kubernetes namespace to use. Think of it as a project name. Use a dedicated namespace per project (you can run several in parallel. `myproject` is fine if you are uninspired
  * Use ASCII characters only, no spaces, no underscores or such!
  * There's a limit of about 20 characters max!
* `jupyterReleaseName`: name the Jupyter Notebook will receive (=helm release name). `jupyter` is fine. You can run several Notebooks per namespace, e.g. if your project team consists of several data scientists. 
  * Use ASCII characters only, no spaces, no underscores or such!
  * There's a limit of about 20 characters max!

If you need to fine-tune your Jupyter Kubernetes pod, check `lab/jupyter/values.yaml` for further customization. Copy anything you want changed into `myvalues.yaml` and set new values.


### 3. Set-up GitHub repository for backup, version-control & collaboration
1. Create a new **empty** repository (usually a private one, thus visible for AWK employees only) on the [AWK GitHub page](https://github.com/awkgroupag) (the green `New`-button). Note the new URL to your new repo, e.g. https://github.com/awkgroupag/MY-NEW-REPO
2. Open a command prompt and navigate to your source code folder (`datalab` in the diagram above)
  * :warning: Be sure to NOT have any data in the directory you are currently in! See above :warning:
3. Type (replacing the URL)
```console
$ git init
# git's default branch name is master, let's change this to GitHub's main
$ git branch -M main
$ git remote add origin https://github.com/awkgroupag/MY-NEW-REPO
# Add the entire datalab to your first commit
$ git add .
$ git commit -m "initial commit"
# Actually upload the files to GitHub.com
# Save GitHub credentials so you don't need to auth again and again
$ git config --global credential.helper store
$ git push --set-upstream origin main
```
4. You should be prompted for your GitHub credentials after the last command above
5. Check [Atlassian's Comparing Workflows](https://www.atlassian.com/git/tutorials/comparing-workflows) to get started with `git`. See the [Git-flow-Workflow](https://www.atlassian.com/git/tutorials/comparing-workflows/gitflow-workflow) to understand collaboration with other team members.
    * Use `git pull` to get the latest changes from GitHub
    * Use `git commit` and `git push` to push your changes to GitHub
    * Work with dedicated new branches for changes, do not work directly with the branch `main`!

## Usage

> #### :warning: be aware that if you use the lab for first time, more than 8 GB will have to be downloaded!

> #### :cyclone: You can start a `controlboard` with special priviledges to configure Kubernetes. This is really handy to start additional Kubernetes stacks from a Jupyter Notebook - without using the command line. 

> #### :information_source: You can easily have several Notebooks running within a namespace (=project). And several namespaces (projects) running simultaneously. Until you run out of CPU or RAM.

> #### :rainbow: Any Linux commands will also work using the Windows command prompt.


### Windows
#### 1a. Start a single Jupyter Notebook directly
In your `datalab` directory, just run `run_jupyter.cmd` directly. JupyterLab will open in Chrome automatically.

#### 1b. Start the controlboard if it gets more complicated
* Run `run_controlboard.cmd`.
* Once the controlboard is up, it will be opened within Chrome.
* Just follow the instructions in the notebook `controlboard.ipynb` which is opened automatically.
  * The controlboard is granted priviledges to configure Kubernetes. To remind you of the fact that you're NOT dealing with a "normal" Jupyter Notebook, the Notebook's GUI is dark

#### 2. Do your work
As everything else will be **deleted** when the Notebook Kubernetes pod is deleted: Make sure that
* your source code is saved to `/home/jovyan/work`
* your data lives in `/home/jovyan/data`
* if you installed additional Python packages, be sure to read `controlboard.ipynb` and safe your computational PIP and/or Anaconda context!

#### 3. If you stop working: Shut down Rancher Desktop 
* You can simply stop all your running notebooks by stopping **Rancher Desktop**. They will all restart once you start Rancher Desktop again.

#### 4. Cleaning up: Remove the Kubernetes pods when done
* Calling `delete_jupyter.cmd` removes the pod, thus resetting everything
* If you used the controlboard to start other tech stacks like PostgreSQL: Be sure to stop any other stacks (=delete their helm releases) you might have started from within the controlboard first. Then run `delete_controlboard.cmd`.


### Linux and helm
####  1. Use helm to start your Jupyter Notebook
* Using the command prompt, navigate to your source code folder, `datalab` above. Then cd into `lab` so you're actually working within `datalab/lab`
* We assume you used the following values in your `myvalues.yaml`:
  ```yaml
  namespace: myproject
  jupyterReleaseName: jupyter
  ```
* Start your Jupyter Notebook by passing it `myvalues.yaml`:
```console
$ helm upgrade -i -n myproject --create-namespace -f myvalues.yaml --wait jupyter jupyter/
Release "jupyter" does not exist. Installing it now.
NAME: jupyter
LAST DEPLOYED: Fri Aug 19 15:54:31 2022
NAMESPACE: myproject
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
Jupyterlab
==========
Kubernetes secret for Jupyter token has not been fully deployed yet. To get
the correct URL for your Jupyter notebook, simply re-try the exact same
command you just used, e.g. "helm install" or "helm upgrade", in a few
seconds

CLEANUP
=======
If you want to completely clean up your Kubernetes resources using the command line, do the following:
1) Delete the helm chart (this will leave secrets and PVCs (=your data) intact):

    helm uninstall -n myproject jupyter

2) Delete the entire namespace. This will also delete any other helm
   releases such as PostgreSQL, INCLUDING Kubernetes secrets and your data (stored in PVCs):

    kubectl delete namespace myproject

```
The first time you run this command, you will NOT get an URL, just like you see above. In that case, simply re-run exactly the same command again. 

#### 2. Restart linux & get the Notebooks URL
If you restart Linux, you're Jupyter pod should automatically be restarted as well. To retreive its URL, type exactly the same command as above:
```console
$ helm upgrade -i -n myproject --create-namespace -f myvalues.yaml --wait jupyter jupyter/
```

#### 3. Start your controlboard if you need more than a single Notebook
Same command as above, simply append `--set controlboard=true` and change the release name to `controlboard` (or anything, really):
```console
$ helm upgrade -i -n myproject --create-namespace -f myvalues.yaml --wait controlboard jupyter/ --set controlboard=true
Release "controlboard" does not exist. Installing it now.
NAME: controlboard
LAST DEPLOYED: Fri Aug 19 16:07:10 2022
NAMESPACE: myproject
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
Controlboard
============
Use the following URL to access your Jupyter notebook:

  Controlboard: http://localhost/myproject/controlboard/lab/tree/work/lab/controlboard.ipynb?token=RyrrkfAodMV3QpMJmIV64rkJxAOdV77vzdvVm1lt9cf3PMXAps4t3IrXSyZj7Vfp

CLEANUP
=======
If you want to completely clean up your Kubernetes resources using the command line, do the following:
1) Delete the helm chart (this will leave secrets and PVCs (=your data) intact):

    helm uninstall -n myproject controlboard

2) Delete the entire namespace. This will also delete any other helm
   releases such as PostgreSQL, INCLUDING Kubernetes secrets and your data (stored in PVCs):

    kubectl delete namespace myproject

```

#### 4. Delete Jupyter Notebook
To delete the normal Jupyter Notebook named `jupyter` that you installed above for your project named `myproject`:
```console
$ helm uninstall -n myproject jupyter
release "jupyter" uninstalled
```
To delete your controlboard named `controlboard`:
```console
$ helm uninstall -n myproject controlboard
release "controlboard" uninstalled
```
To also delete any left-over [Kubernetes secrets](https://kubernetes.io/docs/concepts/configuration/secret/) and/or [Kubernetes Persistent Volume Claims (PVCs)](https://kubernetes.io/docs/concepts/storage/persistent-volumes/) and really start from scratch, delete the entire namespace (=project). Be aware that this will also remove your data for e.g. PostgreSQL.
```console
$ kubectl delete namespace myproject
namespace "myproject" deleted
```

## Supported Stacks
Run the following stacks:
* [Jupyterlab](https://jupyterlab.readthedocs.io/en/stable/)
* [PostgreSQL Database](https://www.postgresql.org/)
* [MySQL Database](https://www.mysql.com/)
* [Elastic Stack including Elasticsearch and Kibana](https://www.elastic.co/de/products/)

## Additions/Tweaks to JupyerLab

The following packages are installed on-top of the [jupyter/datascience-notebook](https://jupyter-docker-stacks.readthedocs.io/en/latest/using/selecting.html).

Data engineering
* [dbt](https://docs.getdbt.com/docs/introduction): the "T" in ELT
  - Usage: **YOU HAVE TO USE THE DEDICATED ANACONDA ENVIRONMENT dbt**: switch the Jupyter Notebook kernel to `dbt`

Automation
* [h2o AutoML](https://docs.h2o.ai/h2o/latest-stable/h2o-docs/automl.html): Automatic machine learning
* [TPOT](http://epistasislab.github.io/tpot/): optimize machine learning pipelines using genetic programming

Feature Engineering
* [Featuretools](https://featuretools.alteryx.com/en/stable/), an open source python framework for automated feature engineering
* [TsFresh](https://tsfresh.readthedocs.io/en/latest/) best open source Python tool available for time series classification and regression. Integrates with Featuretools

Explainable AI
* [Lime](https://github.com/marcotcr/lime): Explaining the predictions of any machine learning classifier
* [SHAP (SHapley Additive exPlanations)](https://github.com/slundberg/shap): game theoretic approach to explain the output of any machine learning model

Natural Language Processing
* [Natural Language Toolkit (NLTK)](https://www.nltk.org/): leading platform for building Python programs to work with human language data
* [spaCy](https://spacy.io/): Industrial-strength NLP. Includes pretrained [English](https://spacy.io/models/en#en_core_web_md) and [German](https://spacy.io/models/de#de_core_news_md) model
* [Wordcloud](https://github.com/amueller/word_cloud): fill any space with a word cloud

Visualizations
* [Plotly](https://plotly.com/python/): Graphing library for interactive, publication-quality graphs
* [Altair](https://altair-viz.github.io/): Declarative Visualization in Python

Frontend and apps
* [Streamlit](https://docs.streamlit.io/en/stable/): The fastest way to build and share data apps

Databases:
* [psycopg2 PostgreSQL Connector](https://www.psycopg.org/docs/): most popular PostgreSQL database adapter for the Python
* [sqlalchemy-utils](https://sqlalchemy-utils.readthedocs.io/en/latest/): custom data types and various utility functions for SQLAlchemy
* [sqlalchemy_schemadisplay](https://github.com/fschulze/sqlalchemy_schemadisplay): Turn SQLAlchemy DB Model into a graph
* [mysql-connector-python MySQL Connector](https://dev.mysql.com/doc/connector-python/en/)

Web scraping
* [Scrapy](https://scrapy.org/): framework for extracting data from websites
* [Beautiful Soup](https://www.crummy.com/software/BeautifulSoup/bs4/doc/): pull data out of HTML and XML files

Tools
* [Pandas Profiling](https://pandas-profiling.ydata.ai/docs/master/index.html): Create profiling reports from pandas DataFrame objects
* [lxml](https://lxml.de/): secure and fast XML and HTML with Python

JupyterLab plugins
* [jupyterlab-git](https://github.com/jupyterlab/jupyterlab-git): Version control using Git within Jupyter
* [Language Server Protocol integration](https://github.com/krassowski/jupyterlab-lsp): Coding assistance for JupyterLab - code navigation + hover suggestions + linters + autocompletion + rename
* [jupyter-resource-usage](https://github.com/jupyter-server/jupyter-resource-usage): Monitor RAM and CPU usage within a Jupyter notebook
