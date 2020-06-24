# DataLab_Stack
## Supported Stacks
Run the following stacks on your local machine or remote server:
* ["Vanilla" Jupyterlab](https://jupyterlab.readthedocs.io/en/stable/)
* [Elastic Stack (formerly ELK-Stack)](https://www.elastic.co/de/products/)
* [PostgreSQL Database](https://www.postgresql.org/)
* [MySQL Database](https://www.mysql.com/)
* Coming up: [Neo4j](https://neo4j.com/)

## Controlboard
### Start the controlboard
Use the command prompt and just type
```
run_controlboard.cmd
```
Once the controlboard is up, it will be opened within Chrome.
* Open the folder `datalab-stacks`
* Start the notebook `ControlBoard.ipynb`
* Follow the instructions in that notebook

### Stop the controlboard
Be sure to **stop any other Docker stacks** you might have started from within the controlboard first. Then type the following in the command prompt:
```
stop_controlboard.cmd
```

### Update the controlboard
The controlboard uses a Docker image from the Docker repository. To get the latest, type
```
update_controlboard.cmd
```
Updating this image is **independent** of you updating this repo from Github!

## Update repo with the latest stacks from Github
To get the latest source code from Github, type
```
git pull
```
To also update the controlboard image, type
```
update_controlboard.cmd
```
