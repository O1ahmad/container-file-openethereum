#!/usr/bin/env python3

from datetime import datetime
import json
import os
import subprocess
import sys

import click
import requests
import toml

@click.group()
@click.option('--debug/--no-debug', default=False)
def cli(debug):
    pass

@cli.group()
def config():
    pass

@cli.group()
def status():
    pass

###
# Commands for application configuration customization and inspection
###

DEFAULT_OPENETHEREUM_CONFIG_PATH = "/root/.local/share/openethereum/config.toml"
DEFAULT_OPENETHEREUM_DATADIR = "/root/.local/share/openethereum"
DEFAULT_OPENETHEREUM_KEYSTORE_DIR = "/root/.local/share/openethereum/keys"
DEFAULT_OPENETHEREUM_BACKUP_PATH = "/tmp/backups/wallet-backup.zip"

DEFAULT_RPC_ADDRESS = "http://localhost:8545"
DEFAULT_RPC_METHOD = "eth_syncing"
DEFAULT_RPC_PARAMS = ""

def execute_command(command):
    process = subprocess.Popen(command.split(), stdout=subprocess.PIPE)
    output, error = process.communicate()

    if process.returncode > 0:
        print('Executing command \"%s\" returned a non-zero status code %d' % (command, process.returncode))
        sys.exit(process.returncode)

    if error:
        print(error.decode('utf-8'))

    return output.decode('utf-8')

def execute_jsonrpc(rpc_address, method, params):
    req = {
        "jsonrpc": "2.0",
        "method": method,
        "params": params,
        "id": 1
    }

    result = requests.post(rpc_address, json=req, headers={'Content-Type': 'application/json'})
    if result.status_code == requests.codes.ok:
        return result
    else:
        result.raise_for_status()

@config.command()
@click.option('--config-path',
              default=DEFAULT_OPENETHEREUM_CONFIG_PATH,
              help='path to geth configuration file to generate or customize from environment config settings')
def customize(config_path):
    config_dict = dict()
    if os.path.isfile(config_path):
        config_dict = toml.load(config_path)

    for var in os.environ.keys():
        var_split = var.split('-')
        if len(var_split) == 3 and var_split[0].lower() == "config":
            config_section = var_split[1]
            section_setting = var_split[2]

            if config_section not in config_dict:
                config_dict[config_section] = {}

            value = os.environ[var]
            if value.isdigit():
                value = int(value)
            config_dict[config_section][section_setting] = value

    with open(config_path, 'w+') as f:
        toml.dump(config_dict, f)

    # TODO: determine better workaround for toml double-quotation parsing re: section names and list
    # technically, the python toml parser should be better/smarter about handling these cases

    # remove surrounding quotes from ALL section names if necessary
    subprocess.call(["sed -i 's/\[\"/\[/g' {path}".format(path=config_path)], shell=True)
    subprocess.call(["sed -i 's/\"\]/\]/g' {path}".format(path=config_path)], shell=True)
    # remove surrounding quotes from ALL list setting values if necessary
    subprocess.call(["sed -i 's/\"\[/\[/g' {path}".format(path=config_path)], shell=True)
    subprocess.call(["sed -i 's/\]\"/\]/g' {path}".format(path=config_path)], shell=True)

@status.command()
@click.option('--rpc-addr',
              default=lambda: os.environ.get("RPC_ADDRESS", DEFAULT_RPC_ADDRESS),
              show_default=DEFAULT_RPC_ADDRESS,
              help='server address to query for RPC calls')
@click.option('--method',
              default=lambda: os.environ.get("RPC_METHOD", DEFAULT_RPC_METHOD),
              show_default=DEFAULT_RPC_METHOD,
              help='RPC method to execute a part of query')
@click.option('--params',
              default=lambda: os.environ.get("RPC_PARAMS", DEFAULT_RPC_PARAMS),
              show_default=DEFAULT_RPC_PARAMS,
              help='comma separated list of RPC query parameters')
def query_rpc(rpc_addr, method, params):
    """Execute RPC query
    """

    result = execute_jsonrpc(
        rpc_addr,
        method,
        params=[] if len(params) == 0 else params.split(',')
    ).json()
    if 'error' in result:
        print(json.dumps(result['error']))
    else:
        print(json.dumps(result['result']))

if __name__ == "__main__":
    cli()
