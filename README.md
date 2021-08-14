<p><img src="https://avatars1.githubusercontent.com/u/12563465?s=200&v=4" alt="OCI logo" title="oci" align="left" height="70" /></p>
<p><img src="https://openethereum.github.io/images/logo-openethereum.svg" alt="OpenEthereum logo" title="open-ethereum" align="right" height="80" /></p>

Container File 💻 🔗 OpenEthereum
=========
![GitHub release (latest by date)](https://img.shields.io/github/v/release/0x0I/container-file-openethereum?color=yellow)
[![0x0I](https://circleci.com/gh/0x0I/container-file-openethereum.svg?style=svg)](https://circleci.com/gh/0x0I/container-file-openethereum)
[![Docker Pulls](https://img.shields.io/docker/pulls/0labs/openethereum?style=flat)](https://hub.docker.com/repository/docker/0labs/openethereum)
[![License: MIT](https://img.shields.io/badge/License-MIT-blueviolet.svg)](https://opensource.org/licenses/MIT)

Configure and operate OpenEthereum: a fast and feature-rich multi-network Ethereum client

**Overview**
  - [Setup](#setup)
    - [Build](#build)
    - [Config](#config)
  - [Operations](#operations)
  - [Examples](#examples)
  - [License](#license)
  - [Author Information](#author-information)

### Setup
--------------
Guidelines on running `0labs/openethereum` containers are available and organized according to the following software & machine provisioning stages:
* _build_
* _config_
* _operations_

#### Build

##### targets

| Name  | description |
| ------------- | ------------- |
| `builder` | image state following build of openethereum binary/artifacts |
| `test` | image containing test tools, functional test cases for validation in addition to `release` target contents |
| `release` | minimal resultant image containing service binaries, entrypoints and helper scripts |
| `tool` | setup consisting of all openethereum utilities, helper tooling in addition `release` target contents |

```bash
docker build --target <target> -t <tag> .
```

#### Config

:page_with_curl: Configuration of the `openethereum` client can be expressed in a config file written in [TOML](https://github.com/toml-lang/toml), a minimal markup format, used as an alternative to passing command-line flags at runtime. To get an idea how the config should look, reference the *openethereum* repo's full [config.toml](https://github.com/openethereum/openethereum/blob/main/bin/oe/cli/tests/config.full.toml) or [others](https://github.com/openethereum/openethereum/tree/main/bin/oe/cli) used as test examples or presets.

_The following variables can be customized to manage the location and content of this TOML configuration:_

`$OPENETHEREUM_CONFIG_DIR=</path/to/configuration/dir>` (**default**: `/root/.local/share/openethereum`)
- container path where the `openethereum` TOML configuration should be maintained

  ```bash
  OPENETHEREUM_CONFIG_DIR=/mnt/etc/openethereum
  ```

`$CONFIG-<section_keyword>-<section_property> = <property_value (string)>` **default**: *None*

- Any configuration setting/value key-pair supported by `openetherem` should be expressible and properly rendered within the associated TOML config.

    `<section_keyword>` -- represents TOML config sections:
    ```bash
    # [TOML Section 'parity']
    CONFIG-parity-<section_property>=<property_value>
    ```

    `<section_property>` -- represents a specific TOML config section property to configure:

    ```bash
    # [TOML Section 'parity']
    # Property: chain
    CONFIG-parity-chain=<property_value>
    ```

    `<property_value>` -- represents property value to configure:
    ```bash
    # [TOML Section 'parity']
    # Property: chain
    # Value: goerli
    CONFIG-parity-chain=goerli
    ```

_Additionally, the content of the TOML configuration file can either be pregenerated and mounted into a container instance:_

```bash
$ cat custom-config.toml
[parity]
chain = "ethereum"

[account]
unlock = ["0xdeadbeefcafe0000000000000000000000000000"]

# mount custom config into container
$ docker run --mount type=bind,source="$(pwd)"/custom-config.toml,target=/tmp/config.toml 0labs/openethereum:latest --config /tmp/config.toml
```

_...or developed from both a mounted config and injected environment variables (with envvars taking precedence and overriding mounted config settings):_

```bash
$ cat custom-config.toml
[network]
min_peers = 50

# mount custom config into container
$ docker run -it --env OPENETHEREUM_CONFIG_DIR=/tmp/openethereum --env CONFIG-parity-max_peers=100 \
  --mount type=bind,source="$(pwd)"/custom-config.toml,target=/tmp/openethereum/config.toml \
  0labs/openethereum:latest --config /tmp/openethereum/config.toml
```

_Moreover, see [here](https://openethereum.github.io/Configuring-OpenEthereum#cli-options) for a list of supported flags to set as runtime command-line flags._

```bash
# connect to Ethereum mainnet and enable warp sync with set barrier
docker run 0labs/openethereum:latest --chain ethereum --warp-barrier 100000
```

###### port mappings

| Port  | mapping description | type | config setting ([section]:[property]) | command-line flag |
| ------------- | ------------- | ------------- | :-------------: | :-------------: |
| `3085`    | RPC server | *TCP*  | `rpc : port` | `--jsonrpc-port` |
| `3086`    | Websocket RPC server | *TCP*  | `websockets : port` | `--ws-port` |
| `30303`    | protocol peer gossip and discovery | *TCP/UDP*  | `network : port` | `--port` |
| `8082`    | secretstore HTTP API | *TCP*  | `secretstore : http_port` | `--secretstore-http-port` |
| `8083`    | secretstore internal | *TCP*  | `secretstore : port` | `--secretstore-port` |

#### Operations

:flashlight: To assist with managing an `openethereum` client and interfacing with the *Ethereum* network, the following utility functions have been included within the image.

##### Check account balances

Display account balances of all accounts currently managed by a designated `openethereum` JSONRPC server.

```
$ openethereum-helper status check-balances --help
Usage: openethereum-helper status check-balances [OPTIONS]

  Check all client managed account balances

Options:
  --rpc-addr TEXT  server address to query for RPC calls  [default:
                   (http://localhost:8545)]
  --help           Show this message and exit.
```

`$RPC_ADDRESS=<web-address>` (**default**: `localhost:8545`)
- `openethereum` RPC server address for querying network state

The balances output consists of a JSON list of entries with the following properties:
  * __account__ - account owner's address
  * __balance__ - total balance of account in decimal

###### example

```bash
docker exec --env RPC_ADDRESS=openethereum-rpc.live.01labs.net 0labs/openethereum:latest openethereum-helper status check-balances

[
  {
   "account": 0x652eD9d222eeA1Ad843efab01E60C29bF2CF6E4c,
   "balance": 1000000
  },
  {
   "account": 0x256eDb444eeA1Ad876efaa160E60C29bF8CH3D9a,
   "balance": 2000000
  }
]
```

##### View client sync progress

View current progress of an RPC server's sync with the network if not already caughtup.

```
$ openethereum-helper status sync-progress --help
Usage: openethereum-helper status sync-progress [OPTIONS]

  Check client blockchain sync status and process

Options:
  --rpc-addr TEXT  server address to query for RPC calls  [default:
                   (http://localhost:8545)]
  --help           Show this message and exit.
```

`$RPC_ADDRESS=<web-address>` (**default**: `localhost:8545`)
- `openethereum` RPC server address for querying network state

The progress output consists of a JSON block with the following properties:
  * __progress__ - percent (%) of total blocks processed and synced by the server
  * __blocksToGo__ - number of blocks left to process/sync
  * __bps__: rate of blocks processed/synced per second
  * __percentageIncrease__ - progress percentage increase since last view
  * __etaHours__ - estimated time (hours) to complete sync

###### example

```bash
$ docker exec 0labs/openethereum:latest openethereum-helper status sync-progress

  {
   "progress":66.8226399830796,
   "blocksToGo":4298054,
   "bps":5.943412173361741,
   "percentageIncrease":0.0018371597201962686,
   "etaHours":200.87852803477827
  }
```

##### Backup and encrypt keystore

Encrypt and backup client keystore to designated container/host location.

```
$ openethereum-helper account backup-keystore --help
Usage: openethereum-helper account backup-keystore [OPTIONS] PASSWORD

  Encrypt and backup wallet keystores.

  PASSWORD password used to encrypt and secure keystore backups

Options:
  --keystore-dir TEXT  openethereum wallet key store directory to backup
                       [default: (keystore based on specified chain)]
  --chain TEXT         Ethereum network chain associated with keystore
                       [default: (kovan)]
  --backup-path TEXT   path to create openethereum wallet key store backup at
                       [default: (/tmp/backups/wallet-backup.zip)]
  --help               Show this message and exit.
```

`$password=<string>` (**required**)
- password used to encrypt and secure keystore backups. Keystore backup is encrypted using the `zip` utility's password protection feature.

`$KEYSTORE_DIR=<string>` (**default**: `/root/.ethereum/keystore`)
- container location to retrieve keys from

`$CHAIN=<string>` (**default**: `kovan`)
- Ethereum network chain associated with keystore

`$BACKUP_PATH=<string>` (**default**: `/tmp/backups`)
- container location to store encrypted keystore backups. **Note:** Using container `volume/mounts`, keystores can be backed-up to all kinds of storage solutions (e.g. USB drives or auto-synced Google Drive folders)

`$AUTO_BACKUP_KEYSTORE=<boolean>` (**default**: `false`)
- automatically backup keystore to $BACKUP_PATH location every $BACKUP_INTERVAL seconds

`$BACKUP_INTERVAL=<cron-schedule>` (**default**: `* * * * * (hourly)`)
- keystore backup frequency based on cron schedules

`$BACKUP_PASSWORD=<string>` (**required**)
- encryption password for automatic backup operations - see *$password*

##### Import backup

Decrypt and import backed-up keystore to designated container/host keystore location.

```
$ openethereum-helper account import-backup --help
Usage: openethereum-helper account import-backup [OPTIONS] PASSWORD

  Decrypt and import wallet keystore backups.

  PASSWORD password used to decrypt and import keystore backups

Options:
  --keystore-dir TEXT  openethereum wallet key store directory to backup
                       [default: (keystore based on specified chain)]
  --chain TEXT         Ethereum network chain associated with keystore
                       [default: (kovan)]
  --backup-path TEXT   path containing backup of a openethereum wallet key
                       store  [default: (/tmp/backups/wallet-backup.zip)]
  --help               Show this message and exit.
```

`$password=<string>` (**required**)
- password used to decrypt keystore backups. Keystore backup is decrypted using the `zip/unzip` utility's password protection feature.

`$KEYSTORE_DIR=<string>` (**default**: `/root/.ethereum/keystore`)
- container location to import keys

`$CHAIN=<string>` (**default**: `kovan`)
- Ethereum network chain associated with keystore

`$BACKUP_PATH=<string>` (**default**: `/tmp/backups`)
- container location to retrieve keystore backup. **Note:** Using container `volume/mounts`, keystores can be imported from all kinds of storage solutions (e.g. USB drives or auto-synced Google Drive folders)

##### Warp Barrier

Get recommended warp barrier to begin sync.

```
$ openethereum-helper status warp-barrier --help
Usage: openethereum-helper status warp-barrier [OPTIONS]

  Get recommended warp barrier to begin warp-sync

Options:
  --rpc-addr TEXT     server address to query for RPC calls  [default:
                      (http://localhost:8545)]
  --warp-offset TEXT  starting block behind latest to begin warp/snapshot sync
                      [default: dynamic]
  --help              Show this message and exit.
```

`$RPC_ADDRESS=<web-address>` (**default**: `localhost:8545`)
- `openethereum` RPC server address for querying network state

`$WARP_OFFSET=<integer>` (**default**: `10000`)
- starting block behind latest to begin warp/snapshot sync

The output consists of an integer value representing the recommended *warp barrier* to set based on the provided warp offset. Reference [OpenEthereum's wiki and warp sync documentation](https://openethereum.github.io/Warp-Sync) for more details.

##### Query RPC

Execute query against designated `openethereum` RPC server.

```
$ openethereum-helper status query-rpc --help
Usage: openethereum-helper status query-rpc [OPTIONS]

  Execute RPC query

Options:
  --rpc-addr TEXT  server address to query for RPC calls  [default:
                   (http://localhost:8545)]
  --method TEXT    RPC method to execute a part of query  [default:
                   (eth_syncing)]
  --params TEXT    comma separated list of RPC query parameters  [default: ()]
  --help           Show this message and exit.
```

`$RPC_ADDRESS=<web-address>` (**default**: `localhost:8545`)
- `openethereum` RPC server address for querying network state

`$RPC_METHOD=<openethereum-rpc-method>` (**default**: `eth_syncing`)
- `openethereum` RPC method to execute

`$RPC_PARAMS=<rpc-method-params>` (**default**: `''`)
- `openethereum` RPC method parameters to include within call

The output consists of a JSON blob corresponding to the expected return object for a given RPC method. Reference [Ethereum's RPC API wiki](https://eth.wiki/json-rpc/API) for more details.

###### example

```bash
docker exec --env RPC_ADDRESS=openethereum-rpc.live.01labs.net --env RPC_METHOD=eth_gasPrice \
    0labs/openethereum:latest openethereum-helper status query-rpc

"0xe0d7b70f7" # 60,355,735,799 wei
```

Examples
----------------

* Create account and bind data/keystore directory to host path:
```
docker run -it -v /mnt/openethereum/data:/root/.local/share/openethereum 0labs/openethereum:latest openethereum account new
```

* Launch an Ethereum archive node and connect it to the Goerli PoS (Proof of Stake) test network:
```
docker run --env CONFIG-footprint-pruning=archive 0labs/openethereum:latest openethereum --chain goerli
```

* View sync progress of active local full-node:
```
docker run --name 01-openethereum --detach 0labs/openethereum:latest openethereum --chain ethereum

docker exec 01-openethereum openethereum-helper status sync-progress
```

* Run *warp* sync with automatic daily backups of custom keystore directory:
```
barrier=$(docker run 0labs/openethereum:latest openethereum-helper status warp-barrier --rpc-addr <RPC-node> --warp-offset 10000)

docker run --env CONFIG-network-warp=true \
           --env KEYSTORE_DIR=/tmp/keys \
           --env AUTO_BACKUP_KEYSTORE=true --env BACKUP_INTERVAL="0 * * * *" \
           --env BACKUP_PASSWORD=<secret> \
           --volume ~/openethereum/keys:/tmp/keys 0labs/openethereum:latest openethereum --warp-barrier $barrier
```

* Import account from keystore backup stored on an attached USB drive:
```
docker run --name 01-openethereum --detach --env CONFIG-footprint-pruning=fast 0labs/openethereum:latest openethereum

docker exec --volume /path/to/usb/mount/keys:/tmp/keys \
            --volume ~/openethereum/data:/root/.local/share/openethereum \
            --env BACKUP_PASSWORD=<secret>
            --env BACKUP_PATH=/tmp/keys/my-wallets.zip
            01-openethereum openethereum-helper account import-backup

docker exec --volume ~/openethereum:/root/.local/share/openethereum 01-openethereum account import /root/.local/share/openethereum/keys/a-wallet
```

License
-------

MIT

Author Information
------------------

This Containerfile was created in 2021 by O1.IO.

🏆 **always happy to help & donations are always welcome** 💸

* **ETH (Ethereum):** 0x652eD9d222eeA1Ad843efec01E60C29bF2CF6E4c

* **BTC (Bitcoin):** 3E8gMxwEnfAAWbvjoPVqSz6DvPfwQ1q8Jn

* **ATOM (Cosmos):** cosmos19vmcf5t68w6ug45mrwjyauh4ey99u9htrgqv09
