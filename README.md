# AWK Datalab
* Get your Data Analytics environment up and running in seconds
* Add and remove technology stacks as needed
* Collaborate and share your environment easily even years later - being sure that everything still runs
* Control your docker environment through a Jupyter notebook instead of command line arguments

You can safely ignore this warning:
```
WARNING: Found orphan containers
```

## Requirements
* Docker installed on your system, e.g. [Docker Desktop on Windows](https://docs.docker.com/docker-for-windows/install/)
  * To test this, open a command prompt and type `docker run hello-world`
* Docker can access your files. When using Docker Desktop on Windows:
  1. Right-click on Docker in the system tray, then click settings
  2. Under General, make sure that "Use the WSL 2 based engine" is NOT selected
  3. Under Ressources, File Sharing, click the plus and add the folder (or even drive) where your source code and data is stored
  4. Click "Apply and Restart"
* Optional: If you're coding, you probably want some kind of code version management like `git`. Since we're using GitHub, try [GitHub Desktop](https://desktop.github.com/)

## How-to use the AWK Datalab
### Create the directory structure for your new project
If you publish your source code to GitHub, you will include your datalab and thus your entire infrastructure
* Create a new dedicated directory for your source code
* Download this entire datalab's sourcecode:
  1. Hit the green "Code"-button, then Download ZIP
  2. Unzip the downloaded ZIP-file into the source code folder you just created
  3. **Important**: rename the folder you justed unzipped from `datalab-master` to `datalab`
* Create another dedicated directory for your data (not within the source code directory ;-))

### Set-up a few variables for your new project once
Change the values in the file `./datalab-stacks/environment.env.EXAMPLE`. Save the customized file as a new file `./datalab-stacks/environment.env`.
* `COMPOSE_PROJECT_NAME`: name of this project. Will show up in all container names associated with this project. No spaces or special characters allowed
* `DATALAB_SOURCECODE_DIR`: your Windows directory containing all your source code - including this datalab! Will appear as `/home/jovyan/work` in the Jupyter Notebook
* `DATALAB_DATA_DIR`: your Windows directory containing all data. Will be mounted as `/home/jovyan/data` in the Notebook


### Start a single Jupyter Notebook directly
Just run `run_jupyter_notebook.cmd` directly. Stop it again with `rm_jupyter_notebook.cmd`.


### Start the controlboard if it gets more complicated
Run `run_controlboard.cmd`. Once the controlboard is up, it will be opened within Chrome.
* In the controlboard, open the directory `datalab-stacks`
* Start the notebook `ControlBoard.ipynb`
* Follow the instructions in that notebook

### Stop the controlboard
Be sure to stop any other stacks you might have started from within the controlboard first. Then run `rm_controlboard.cmd`.

## Run several projects simultaneously
Easily run several projects at the same time. Make sure that you choose different project-names in `./datalab-stacks/environment.env` and also set different, **unique** values for all the ports.

If your head starts spinning because you don't know which project's container talks to which other project's container: set-up a dedicated network e.g. with `docker network create project-A-network` and replace **all** strings `datalab-network`  with  `project-A-network` in all files for project A. 


## Remarks
Docker containers such as this controlboard or the different stacks will keep on running forever, even if you restart your machine. So remember to stop them.

## Supported Stacks
Run the following stacks on your local machine or remote server:
* ["Vanilla" Jupyterlab](https://jupyterlab.readthedocs.io/en/stable/)
* [Elastic Stack (formerly ELK-Stack)](https://www.elastic.co/de/products/)
* [PostgreSQL Database](https://www.postgresql.org/)
* [MySQL Database](https://www.mysql.com/)
* [Neo4j](https://neo4j.com/)
