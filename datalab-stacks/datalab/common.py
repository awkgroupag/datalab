import logging
import subprocess
import sys
from IPython.display import display, Markdown as md

logger = logging.getLogger()

# Default Jupyterlab URL in the log that we should be looking for to grab the
# Jupyterlab token
standard_url = 'http://127.0.0.1:8888'
# Points to the root directory that contains the different directory stacks
root_datalab_stacks = './stack_templates'
# Directory names that we do NOT want to copy to a new notebook
try:
    skip_stacks = [x.strip() for x in open('./.datalabignore').readlines()
                   if x.strip() and not x.startswith('#')]
except FileNotFoundError:
    skip_stacks = []
# Home directory in the Jupyter container - for the source code
jupyter_home_dir = '/home/jovyan/work'
# Separate directory for the (potentially sensitive) data
jupyter_data_dir = '/home/jovyan/data'
# Datalab directly in the project folder (mounted in Jupyter container) that
# will contain the stacks
datalab_home_dir = '/home/jovyan/work/.datalab'
# Temporary dir
tmp_dir = '/tmp/datalab'


def isdir(container, directory):
    """
    Returns True if the directory already exists in the Docker container, False
    otherwise
    TODO: will return True if a directory has just been deleted - cause is
    unknown
    """
    command = f'sudo docker exec {container} [ -d "{directory}" ] && exit 0 || exit 1'
    output = run_cmd(command, raise_exception=False)
    return output.returncode == 0


def mkdir(container, directory):
    """
    Creates a new directory in the Docker container if it does not exist
    already
    """
    run_cmd(f'sudo docker exec {container} mkdir -p {directory}')


def show_md(markdown_text):
    """
    Pass a string, it will be rendered as MarkDown in the current Jupyter cell
    """
    display(md(markdown_text))


def run_cmd(command, raise_exception=True):
    """
    Runs the bash command (string containing the bash command in all its beauty)
    within the current container using Python's subprocess. Returns a
    subprocess.CompletedProcess object.
    Raises RuntimeError if the bash process returns anything but 0 (which
    usually means that the command was successful) except if raise_exception is
    False. 
    """
    output = subprocess.run(['bash', '-c', command], capture_output=True)
    if raise_exception and output.returncode != 0:
        error_message = output.stderr.decode(sys.getdefaultencoding())
        logger.error(error_message)
        raise RuntimeError(f'Bash command did not complete successfully: {command}')
    return output


def copy_dir(container, source, target, direction='to', exclude=None):
    """
    Copy the directory with path source to the directory named target in the
    container.
    exclude: Supply a list of strings to skip the copying of files or folders
    named similarly (following the pattern). See the tar command reference for
    '--exclude'
    """
    # The docker cp copy-command does NOT allow us to skip certain folders
    # Hence make a temporary copy of the stack directory with only the items
    # that we want copied to the other container
    exclude = exclude or []
    # Create temp folder
    run_cmd(f'mkdir {tmp_dir}')
    try:
        if direction == 'to':
            # Copy the stack to the temp folder using tar (rsync not available)
            # See https://stackoverflow.com/questions/2193584/copy-folder-recursively-excluding-some-folders
            command = f'cd {source} && tar cf -'
            for pattern in exclude:
                command += f" --exclude='{pattern}'"
            command += f' . | (cd {tmp_dir} && tar xvf - )'
            run_cmd(command)
            # Now use Docker's copy mechanism to copy from the controlboard
            # container to the container
            run_cmd(f'sudo docker cp {tmp_dir} {container}:{target}')
        elif direction == 'from':
            run_cmd(f'sudo docker cp {container}:{source} {tmp_dir}')
            command = f'cd {tmp_dir} && tar cf -'
            for pattern in exclude:
                command += f" --exclude='{pattern}'"
            command += f' . | (cd {target} && tar xvf - )'
            run_cmd(command)
        else: 
            raise RuntimeError(f'Unknown direction {direction}')
    finally:
        # Ensure that we delete the temp folder even if an exception occurs
        run_cmd(f'rm -rf {tmp_dir}')
