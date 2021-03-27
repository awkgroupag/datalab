* [Requirements](#requirements)
* [How-to use the AWK Datalab](#how-to-install-and-use-the-awk-datalab)
* [Run several projects simultaneously](#run-several-projects-simultaneously)
* [Supported Stacks](#supported-stacks)
* [Additions/Tweaks to JupyerLab](#additionstweaks-to-jupyerlab)
* [Good to know](#good-to-know)


# AWK Datalab
* Get your Data Analytics environment up and running in seconds
* Add and remove technology stacks as needed
* Collaborate and share your environment easily even years later - being sure that everything still runs
* Control your docker environment through a Jupyter notebook instead of command line arguments

## Requirements
* Docker installed on your system, e.g. [Docker Desktop on Windows](https://docs.docker.com/docker-for-windows/install/)
  * To test this, open a command prompt and type `docker run hello-world`
* Docker can access your files. When using Docker Desktop on Windows:
  1. Right-click on Docker in the system tray, then click settings
  2. Under General, make sure that "Use the WSL 2 based engine" is NOT selected
  3. Under Ressources, File Sharing, click the plus and add the folder (or even drive) where your source code and data is stored
  4. Click "Apply and Restart"
* Optional: If you're coding, you probably want some kind of code version management like `git`. Since we're using GitHub, try [GitHub Desktop](https://desktop.github.com/)

## How-to install and use the AWK Datalab
### 1. Create the directory structure for your new project
If you publish your source code to GitHub, you will include your datalab and thus your entire infrastructure
* Create a new dedicated directory for your source code
* Download this entire datalab's sourcecode:
  1. Hit the green "Code"-button, then Download ZIP
  2. Unzip the downloaded ZIP-file into the source code folder you just created
  3. **Important**: rename the folder you justed unzipped from `datalab-master` to `datalab`
* Create another dedicated directory for your data (not within the source code directory ;-))

### 2. Set-up a few variables for your new project once
Change the values in the file `./datalab-stacks/environment.env.EXAMPLE`. Save the customized file as a new file `./datalab-stacks/environment.env`.
* `COMPOSE_PROJECT_NAME`: name of this project. Will show up in all container names associated with this project. No spaces or special characters allowed
* `DATALAB_SOURCECODE_DIR`: your Windows directory containing all your source code - including this datalab! Will appear as `/home/jovyan/work` in the Jupyter Notebook
* `DATALAB_DATA_DIR`: your Windows directory containing all data. Will be mounted as `/home/jovyan/data` in the Notebook


### 3a. Start a single Jupyter Notebook directly
Just run `run_jupyter_notebook.cmd` directly. JupyterLab will open in Chrome automatically.


### 3b. Start the controlboard if it gets more complicated
Run `run_controlboard.cmd`. Once the controlboard is up, it will be opened within Chrome.
* In the controlboard, open the directory `datalab-stacks`
* Start the notebook `ControlBoard.ipynb`
* Follow the instructions in that notebook

### 4. Do your work
As everything else will be **deleted** when recreating the Jupyter container: Make sure that
* your source code is saved to `/home/jovyan/work`
* your data lives in `/home/jovyan/data`

### 5. Stop and/or remove the containers when done
* If you only started Jupyter (3a), `stop_jupyter_notebook.cmd` stops the container - configurations like additional Python packages are kept. `rm_jupyter_notebook.cmd` removes the container, thus resetting everything.
* If you used the controlboard (3b): Be sure to stop any other stacks you might have started from within the controlboard first. Then run `rm_controlboard.cmd`.

## Run several projects simultaneously
Easily run several projects at the same time. Make sure that you choose different project-names in `./datalab-stacks/environment.env` and also set different, **unique** values for all the ports.

If your head starts spinning because you don't know which project's container talks to which other project's container: set-up a dedicated network e.g. with `docker network create project-A-network` and replace **all** strings `datalab-network`  with  `project-A-network` in all files for project A. 


## Supported Stacks
Run the following stacks on your local machine or remote server:
* ["Vanilla" Jupyterlab](https://jupyterlab.readthedocs.io/en/stable/)
* [PostgreSQL Database](https://www.postgresql.org/)
* [Neo4j](https://neo4j.com/)
* [MySQL Database](https://www.mysql.com/)
* [Elastic Stack (formerly ELK-Stack)](https://www.elastic.co/de/products/)

## Additions/Tweaks to JupyerLab
Major additional Python modules
* [h2o AutoML](http://docs.h2o.ai/h2o/latest-stable/h2o-py/docs/index.html)
* [Pandas Profiling](https://pandas-profiling.github.io/pandas-profiling/docs/master/rtd/)
* [NLTK: Natural Language Toolkit](https://www.nltk.org/)
* [spaCy: Industrial-strength NLP](https://spacy.io/)
* [Streamlit: Create apps](https://docs.streamlit.io/en/stable/)

Visualizations
* [Altair: Declarative Visualization in Python](https://altair-viz.github.io/)

Database stuff
* [sqlalchemy-utils](https://sqlalchemy-utils.readthedocs.io/en/latest/)
* [sqlalchemy_schemadisplay](https://github.com/fschulze/sqlalchemy_schemadisplay)
* [psycopg2 PostgreSQL Connector](https://www.psycopg.org/docs/)
* [mysql-connector-python MySQL Connector](https://dev.mysql.com/doc/connector-python/en/)

Tools
* [lxml - XML and HTML with Python](https://lxml.de/)

### JupyterLab plugins
* [jupyterlab-git](https://github.com/jupyterlab/jupyterlab-git)
* [Language Server Protocol integration for Jupyter](https://github.com/krassowski/jupyterlab-lsp)
* [JupyterLab System Monitor](https://github.com/jtpio/jupyterlab-system-monitor)


## Good to know
* You can safely ignore this warning:
```
WARNING: Found orphan containers
```
* Docker containers such as this controlboard or the different stacks will keep on running forever, even if you restart your machine. So remember [to stop them](#5-stop-andor-remove-the-containers-when-done).
