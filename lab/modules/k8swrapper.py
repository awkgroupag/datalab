# ---------------------------------------------------------------------------------
# wrapper functions for Kubernetes Python library
# see https://github.com/kubernetes-client/python/
# ---------------------------------------------------------------------------------
from kubernetes import client, config, utils
from kubernetes.client.rest import ApiException
import yaml
import base64
import string
import secrets


def alphanumeric_password(length):
    """Creates a strong cryptographic secret, using only characters [a-zA-Z0-9]"""
    alphabet = string.ascii_letters + string.digits
    return ''.join(secrets.choice(alphabet) for i in range(length))


def create_secret(api, secret_name, namespace, string_data, secret_type='Opaque', pretty='true'):
    """Create a K8S Secret

    args:
        api:                kubernetes.client.CoreV1Api() instance
        secret_name (str) : Name of the Secret
        namespace   (str) : Name of namespace
        string_data (dict): Data to store as key/value (not base64-encoded!)
                            All values must be string

    raises ApiException if the Secret already exists

    returns the api answer
    """
    secret = client.V1Secret()
    secret.api_version = 'v1'
    secret.kind = 'Secret'
    secret.metadata = {'name': secret_name}
    secret.data = {k: base64.b64encode(string_data[k].encode('utf-8')).decode('utf-8') for k in string_data}
    secret.type = secret_type
    return api.create_namespaced_secret(namespace, secret, pretty=pretty)


def get_secret(api, secret_name, namespace):
    """Returns the K8S Secret data as a dict
    raises ApiException if the Secret does not exist
    """
    secret = api.read_namespaced_secret(secret_name, namespace).data
    return {k: base64.b64decode(secret[k].encode('utf-8')).decode('utf-8') for k in secret}


def get_secret_key(api, secret_name, namespace, key):
    """Returns the K8S Secret value for key as string

    Raises ApiException if the secret is not found in the namespace.
    """
    secret = api.read_namespaced_secret(secret_name, namespace).data
    return base64.b64decode(secret[key].encode('utf-8')).decode('utf-8')


def create_or_get_secret(api, secret_name, namespace, string_data, secret_type='Opaque', pretty='true'):
    try:
        create_secret(api, secret_name, namespace, string_data, secret_type, pretty)
    except ApiException:
        # Secret already exists (or we do not have the credentials to create one)
        return get_secret(api, secret_name, namespace)
    else:
        return string_data


# get pods in all/specific namespace
def get_pods_all_namespaces():
    config.load_incluster_config()
    v1 = client.CoreV1Api()
    
    return v1.list_pod_for_all_namespaces(watch=False)

def get_pods_namespace(namespace="default"):
    config.load_incluster_config()
    v1 = client.CoreV1Api()
    
    return v1.list_namespaced_pod(namespace)

# helper function to show pods
def list_pods(list_of_pods):
    for i in list_of_pods.items:
        print("%s\t%s\t%s" % (i.status.pod_ip, i.metadata.namespace, i.metadata.name))

# ---------------------------------------------------------------------------------
# create pod
def create_pod(pod_name, image_name, args=None, namespace="default"):
    config.load_incluster_config()
    v1 = client.CoreV1Api()

    container = client.V1Container(name=pod_name)
    container.image = image_name
    container.args = args

    pod = client.V1Pod()
    pod.metadata = client.V1ObjectMeta(name=pod_name)
    pod.spec =  client.V1PodSpec(containers=[container])

    return v1.create_namespaced_pod(namespace=namespace,body=pod)


# delete pod
def delete_pod(pod_name, namespace="default"):
    config.load_incluster_config()
    v1 = client.CoreV1Api()

    try:
        return v1.delete_namespaced_pod(name=pod_name, namespace=namespace, body=client.V1DeleteOptions())
        print('Pod ' + name + ' deleted.')
    except Exception as e:
        print (e)

# create a project and its instances, based on the template files
def create_project(projectType, name, data_dir, work_dir, verbose=False, data_dir_inside='/home/jovyan/data',postgresPort='5432', mySqlPort='3306',elasticPort='9200', logstashPort1='5000', logstashPort2='9600', kibanaPort='5601', neo4jHttpPort='7474', neo4jBoltPort='7687'):
    # get type and set configuration accordingly
    if (projectType == 'jupyter'):
        CONFIG_DIR = '/home/jovyan/work/datalab-stacks/jupyter/'
        templates = [['jupyter_notebook_config.tmpl.py', '.jnc.py'],
                     ['single-notebook.tmpl.yml', '.yml']]
    else:
        if (projectType == 'elk'):
            CONFIG_DIR = '/home/jovyan/work/datalab-stacks/elk/'
            templates = [['elk.tmpl.yml', '.yml']];
        else:
            if (projectType == 'mysql'):
                CONFIG_DIR = '/home/jovyan/work/datalab-stacks/mysql/'
                templates = [['mysql.tmpl.yml', '.yml']];
            else:
                if (projectType == 'postgres'):
                    CONFIG_DIR = '/home/jovyan/work/datalab-stacks/postgres/'
                    templates = [['postgres.tmpl.yml', '.yml']];
                else:
                    if (projectType == 'neo4j'):
                        CONFIG_DIR = '/home/jovyan/work/datalab-stacks/neo4j/'
                        templates = [['neo4j.tmpl.yml', '.yml']];
                    else:
                        return "Invalid project type defined.";

    try:
        for template in templates:
            with open(CONFIG_DIR+template[0], 'r') as ifp:
                with open(data_dir_inside+'/'+name+template[1], 'w') as ofp:
                    ofp.write(ifp.read()
                              .replace('PROJECT_NAME', name)
                              .replace('DATALAB_DATA_DIR', data_dir)
                              .replace('DATALAB_SOURCECODE_DIR', work_dir)
                              .replace('DATALAB_POSTGRES_PORT', postgresPort)
                              .replace('DATALAB_MYSQL_PORT', mySqlPort)
                              .replace('DATALAB_ELK_ELASTICSEARCH_PORT', elasticPort)
                              .replace('DATALAB_ELK_LOGSTASH_PORT1', logstashPort1)
                              .replace('DATALAB_ELK_LOGSTASH_PORT2', logstashPort2)
                              .replace('DATALAB_ELK_KIBANA_PORT', kibanaPort)
                              .replace('DATALAB_NEO4J_HTTP_PORT', neo4jHttpPort)
                              .replace('DATALAB_NEO4J_BOLT_PORT', neo4jBoltPort))

        with open(data_dir_inside+'/'+name+'.yml', 'r') as stream:
            try:
                parsed_yaml=yaml.safe_load_all(stream.read())
                create_with_yml_objects(name, parsed_yaml, verbose)
            except yaml.YAMLError as exc:
                print(exc)
        print('Pod ' + name + ' created.')
        print('Configuration is written to ' + data_dir_inside + '/' + name + '.yml')
    except Exception as e:
        print (e)

def create_with_yml(pod_name, yml_file, verbose=False):
    config.load_incluster_config()
    k8s_client = client.ApiClient()

    utils.create_from_yaml(k8s_client, yml_file, None, verbose)

def create_with_yml_objects(pod_name, yml_objects, verbose=False):
    config.load_incluster_config()
    k8s_client = client.ApiClient()

    utils.create_from_yaml(k8s_client, None, yml_objects, verbose)

# get Jupyter Lab access URL (written to logfile on each start of pod .. token changes)
def get_project_url(project_name):
    import re
    import time

    config.load_incluster_config()
    v1 = client.CoreV1Api()

    i = 0
    try:
        while i < 5:
            pod_logs = v1.read_namespaced_pod_log(name=project_name, namespace="default")
            for line in pod_logs.splitlines():
                #print (line)
                if (line.find('http://127.0.0.1') != -1):
                    token = re.sub('^.*http://127.0.0.1.*lab\?token=','', line)
                    return ('https://localhost/'+project_name+'/lab?token='+token)
                    i = 10
                    break
            i += 1
            time.sleep(3)
        return 'Not ready yet, please try again.'
    except ApiException as e:
        print("Exception when calling get_project_url: %s\n" % e)

# get Kibana first time access URL (written to logfile on first start of pod .. code changes)
def get_kibana_setup_url(project_name):
    import re
    import time

    config.load_incluster_config()
    v1 = client.CoreV1Api()

    i = 0
    try:
        while i < 5:
            pod_logs = v1.read_namespaced_pod_log(name=project_name+"-elastic", container="kibana", namespace="default")
            for line in pod_logs.splitlines():
                #print (line)
                if (line.find('Go to http://0.0.0.0') != -1):
                    code = re.sub('^.*http://0.0.0.0.*\?code=','', line)
                    return ('Go to https://localhost/'+project_name+'-kibana/?code='+code)
            i += 1
            time.sleep(3)
        return 'Not ready yet, please try again.'
    except ApiException as e:
        print("Exception when calling get_project_url: %s\n" % e)

# delete all objects that are defined in the projects .yml
def delete_project(project_name, namespace = 'default', data_dir='/home/jovyan/data'):

    config.load_incluster_config()

    with open(data_dir+'/'+project_name+'.yml', 'r') as stream:
        try:
            parsed_yaml=yaml.safe_load_all(stream.read())
            for yml_document in parsed_yaml:
                if yml_document is None:
                    continue
                #import pyaml
                #print (pyaml.dump(yml_document))

                try:
                    name = yml_document["metadata"]["name"]
                    if yml_document['kind'] == 'Pod':
                        print('Deleting pod ' + name)
                        v1 = client.CoreV1Api()
                        v1.delete_namespaced_pod(name=name, namespace=namespace, body=client.V1DeleteOptions())
                    if yml_document['kind'] == 'Service':
                        print('Deleting service ' + name)
                        v1 = client.CoreV1Api()
                        v1.delete_namespaced_service(name=name, namespace=namespace, body=client.V1DeleteOptions())
                    if yml_document['kind'] == 'Ingress':
                        print('Deleting ingress ' + name)
                        v1 = client.NetworkingV1Api()
                        v1.delete_namespaced_ingress(name=name, namespace=namespace, body=client.V1DeleteOptions())
                except ApiException as e:
                    print("Exception when calling delete_project: %s\n" % e)
        except yaml.YAMLError as exc:
            print(exc)
