import time
import sys
import os
import logging

from .common import isdir, mkdir, show_md, run_cmd, copy_dir, standard_url
from .common import root_datalab_stacks, skip_stacks, jupyter_home_dir
from .common import jupyter_data_dir, datalab_home_dir

logger = logging.getLogger()


def start_notebook(sourcode_dir, data_dir, notebook, notebook_version,
                   container, port):
    sourcode_dir = get_valid_dir(sourcode_dir)
    # Docker command to start the container with parameters specified
    show_md('Waiting for the container to start up\n')
    command = ['sudo docker container run',
        '-d',
        f'-p {port}:8888',
        '-e JUPYTER_ENABLE_LAB=yes',
        f'-v "{sourcode_dir}:{jupyter_home_dir}"',
        f'-v "{data_dir}:{jupyter_data_dir}"',
        f'--name {container}',
        '--network=datalab-network',
        f'{notebook}:{notebook_version}'
    ]
    command = ' '.join(command)
    already_running = run_cmd(command, raise_exception=False).returncode != 0
    # Wait until the container log features an entry with the token needed
    # to access the notebook
    old_url = None
    attempt = 0
    while old_url is None:
        output = run_cmd(f'sudo docker logs {container}',
                         raise_exception=False)
        log = output.stderr.decode(sys.getdefaultencoding())
        for line in log.split('\n'):
            if standard_url in line:
                old_url = line
                break
        else:
            attempt += 1
            if attempt == 10:
                break
            time.sleep(1)
    # We might not be able to grab a token, e.g. if container failed to start
    if old_url is None:
        logger.error(output.stderr.decode(sys.getdefaultencoding()))
        show_md('ERROR: Did not find the JupyterLab URL in the log above')
        return
    if already_running:
        show_md(f'Container {container} is already running! Returning its previous URL')
    # Replace the standard port (8888) with the port specified by the user
    url = standard_url[:-4] + str(port) + old_url.split(standard_url, 1)[1]
    show_md(f'**Your JupyterLab URL is {url}**')
    copy_stacks(sourcode_dir, container)
    return url


def get_valid_dir(work_dir):
    # TODO: Paths when using Linux OS instead of Windows
    # Need to convert Windows path for Docker (linux-based VM)
    # We CANNOT check if work_dir is valid since it's not mounted!
    work_dir = '//' + work_dir.replace("\\", "/").replace(":", "")
    return work_dir


def copy_stacks(work_dir, container):
    new_stacks = []
    existing_stacks = []
    mkdir(container, datalab_home_dir)
    for stack in datalab_stack_dir_names():
        target_dir = os.path.join(datalab_home_dir, stack)
        if not isdir(container, target_dir):
            new_stacks.append(stack)
            copy_dir(container,
                     f'{root_datalab_stacks}/{stack}',
                     target_dir,
                     exclude=skip_stacks)
        else:
            existing_stacks.append(stack)
    show_md(f'Created the following new stacks in the project directory: {new_stacks}')
    show_md(f'The following stacks already exist in the project directory (are left unchanged): {existing_stacks}')


def datalab_stack_dir_names():
    for item in os.listdir(root_datalab_stacks):
        file_or_folder = os.path.join(root_datalab_stacks, item)
        if os.path.isdir(file_or_folder) and not item in skip_stacks:
            yield item
