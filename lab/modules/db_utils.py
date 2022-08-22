from sqlalchemy import create_engine, MetaData
import sqlalchemy_utils
from urllib import parse


def create_db_engine(host, port, dialect, username, password, table):
	"""Creates a new sqlalchemy "engine" for the database to work with.
	Be aware that engines are "lazy" and will only raise Exceptions
	once you do something with them

	args:
		host:		string, hostname where DB is reachable
		port:		int, port number where DB is reachable
		dialect:	string, e.g. 'postgresql'. See sqlitealchemy for
					more dialects
		username:	string, username to use to connect
		password:	string, associated password
		table:		string, name of the table to work with

	Returns an sqlalchemy.engine.Engine() object
	"""
	# URL-encode password for characters like %, ä, ...
	password = parse.quote_plus(password)
	url = f'{dialect}://{username}:{password}@{host}:{port}/{table}'
	return create_engine(url)


def table_exists(engine):
	"""Returns True if the table already exists, False if not.
	You should have set the table already when creating the engine!
	args:
		engine: 	sqlalchemy engine object (use create_db_engine())

	Raises DatabaseError if e.g. the database host is not reachable
	"""
	return sqlalchemy_utils.database_exists(engine.url)


def create_table_if_not_exist(engine):
	"""Creates a new table in the database if it does not already exist.
	You should have set the table already when creating the engine!
	args:
		engine: 	sqlalchemy engine object (use create_db_engine())

	Raises DatabaseError if e.g. the database host is not reachable
	Returns True if the table got created, False if it already
	existed
	"""
	if not sqlalchemy_utils.database_exists(engine.url):
	    sqlalchemy_utils.create_database(engine.url)
	    return True
	return False


def drop_table(engine):
	"""Deletes the database's table should it exist.
	You should have set the table already when creating the engine!
	args:
		engine: 	sqlalchemy engine object (use create_db_engine())

	Raises DatabaseError if e.g. the database host is not reachable
	Returns True if the table existed and got delete, False if
	there was no table to begin with
	"""
	if sqlalchemy_utils.database_exists(engine.url):
	    sqlalchemy_utils.functions.drop_database(engine.url)
	    return True
	return False
