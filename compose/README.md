# OpenEthereum :cloud: Compose

:octocat: Custom configuration of this deployment composition can be provided by setting environment variables of the operation environment explicitly:

`export chain=mainnet`

or included within an environment config file located either at a `.env` file within the same directory or specified via the `env_vars` environment variable.

`export env_vars=/home/user/.ethereum/mainnet_vars.env`

## Config


**Required**

`none`

**Optional**

| var | description | default |
| :---: | :---: | :---: |
| *image* | OpenEthereum service container image to deploy | `0labs/openethereum:latest` |
| *chain* | Ethereum network/chain to connect openethereum instance to | `kovan` |
| *OPENETHEREUM_CONFIG_DIR* | configuration directory path within container | `/etc/geth` |
| *p2p_port* | Peer-to-peer network discovery and communication listening port | `30303` |
| *rpc_port* | HTTP-RPC server listening portport | `8545` |
| *websocket_port* | WS-RPC server listening port | `8546` |
| *metrics_port* | Metrics HTTP server listening port | `3000` |
| *env_vars* | Path to environment file to load by compose Geth container | `.env` |
| *host_data_dir* | Host directory to store client runtime/operational data | `/var/tmp/geth` |
| *data_dir* | data directory within container to store client runtime/operational data | `/var/tmp/openethereum` |
| *restart_policy* | container restart policy | `unless-stopped` |
| *warp_barrier* | When warp enabled never attempt regular sync before warping to block NUM | `10000` |
| *exporter_image* | OpenEthereum data exporter image to deploy | `hunterlong/gethexporter:latest` |
| *exporter_rpc_addr* | Network address <ip:port> of geth rpc instance to export data from | `http://localhost:8545` |
| *exporter_port* | Exporter metrics collection listening port | `10090` |

## Deploy examples

* Launch an Ethereum archive node and connect it to the Goerli PoS (Proof of Stake) test network:
```
# cat .env
chain=goerli
CONFIG-footprint-pruning=archive

docker-compose up
```

* View sync progress of active local mainnet full-node:
```
# cat .env
chain=ethereum

docker-compose up -d  && docker-compose exec openethereum openethereum-helper status sync-progress
```

* Customize OpenEthereum deploy image and p2p port
```
# cat .env
image=0labs/openethereum:v0.1.0
p2p_port=30313

docker-compose up
```

* Run *warp* sync with automatic daily backups of custom keystore directory on kovan testnet:
```
# cat .env
chain=kovan
CONFIG-network-warp=true
warp_barrier=27183279
BACKUP_PATH=/tmp/openethereum/keys/my-wallets.zip
AUTO_BACKUP_KEYSTORE=true
BACKUP_INTERVAL='0 * * * *'
BACKUP_PASSWORD=<secret>
host_data_dir=/home/user/openethereum
data_dir=/tmp/openethereum

docker-compose up
```

* Expose OpenEthereum network components on *ALL* interfaces:
```
# cat .env
CONFIG-network-nat=any
CONFIG-rpc-interface=all
CONFIG-websockets-interface=all
CONFIG-metrics-interface=all

docker-compose up
```
