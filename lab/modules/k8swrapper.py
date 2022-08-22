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
