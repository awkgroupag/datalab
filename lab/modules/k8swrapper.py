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
import re


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


def create_or_get_secret(api, secret_name, namespace, string_data,
                         secret_type='Opaque', pretty='true'):
    """If a k8s secret secret_name [str] exists in namespace, return it as a
    dict of key value pairs. If not, create it based on string_data [dict],
    consisting of key value pairs.
    Returns the secret (existing or just created) as a dict
    """
    try:
        create_secret(api, secret_name, namespace, string_data, secret_type, pretty)
    except ApiException:
        # Secret already exists (or we do not have the credentials to create one)
        return get_secret(api, secret_name, namespace)
    else:
        return string_data


def dict_to_env_file(filename, dictionary):
    """
    Helper function to create *.env files from a (flat) dictionary [dict]
    Writes the dictionary as key value pairs into filename [str], for example
        dictionary = {'KEY1': 'value1', 'KEY2': 'value2', 'KEY3': 12345}
        generated file:
            KEY1="value1"
            KEY2="value2"
            KEY3="12345"
    Overwrites any existing file!
    The dictionary keys must consist of of uppercase letters and digits only,
    underscores are also ok [A-Z0-9_]. The keys must not start with a digit.
    Otherwise, ValueError is raised.
    The dictionary values may only be str, int or float, otherwise ValueError
    is raised.
    """
    # Check if key in dictionary only contains letters and underscore
    # and starts with a letter or underscore
    for key, value in dictionary.items():
        if not bool(re.match('^[A-Z_][A-Z0-9_]*$', str(key))):
            raise ValueError(f'dictionary key invalid for environment variable'
                             f' name: {key}')
        if not isinstance(value, (str, int, float)):
            raise ValueError(f'dictionary value for key {key} must be either '
                             f'str, int or float, not {type(value)}')
    with open(filename, 'w') as f:
        for key, value in dictionary.items():
            f.write(f'{key}="{value}"\n')
