{inputs, ...}: {
  imports = [
    inputs.process-compose-flake.flakeModule
  ];

  perSystem = {
    config,
    inputs',
    pkgs,
    self',
    lib,
    ...
  }:
    with lib; let
      inherit (inputs'.ethereum-nix.packages) geth prysm mev-boost-builder;
    in {
      # Add custom commands related to spinning up Ethereum PoS
      devshells.default = {
        commands = [
          {
            category = "Ethereum Dev Kit";
            name = "init";
            help = "Create the genesis configuration for the consensus and beacon chain clients";
            command = ''
              set -euo pipefail

              # sets up the genesis configuration for the go-ethereum client from a JSON file.
              ${geth}/bin/geth --datadir=./execution/ init ./execution/genesis.json

              # creates a genesis state for the beacon chain using a YAML configuration file and a deterministic set of 64 validators.
              ${prysm}/bin/prysmctl \
              testnet generate-genesis \
              --chain-config-file=./consensus/config.yml \
              --num-validators=64 \
              --output-ssz=./consensus/genesis.ssz
            '';
          }
          {
            category = "Ethereum Dev Kit";
            name = "clean";
            help = "Removes unnecessary files";
            command = ''
              set -euo pipefail

              # clean consensus, validator and genesis files
              rm -rf ./consensus/{beacon,validator,genesis.ssz}

              # clean execution folder
              rm -rf ./execution/geth
            '';
          }
          {
            category = "Ethereum Dev Kit";
            name = "up";
            help = "Start the Ethereum PoS dev environment";
            command = "nix run .#ethereum-pos-dev-kit";
          }
        ];
      };

      # Create custom process-compose configuration for spining up
      process-compose.configs = {
        ethereum-pos-dev-kit = {
          log_location = "./ethereum-dev-kit.log";
          processes = {
            # Execution Client:
            #   Runs the go-ethereum execution client with the specified, unlocked account and necessary
            #   APIs to allow for proof-of-stake consensus via Prysm.
            geth = {
              command = ''
                ${mev-boost-builder}/bin/geth \
                --allow-insecure-unlock \
                --authrpc.addr=0.0.0.0 \
                --authrpc.jwtsecret=./config/jwtsecret \
                --authrpc.vhosts="*" \
                --builder \
                --builder.beacon_endpoint=http://localhost:3500 \
                --builder.bellatrix_fork_version=0x20000091 \
                --builder.genesis_fork_version=0x20000089 \
                --builder.genesis_validators_root=0x83431ec7fcf92cfc44947fc0418e831c25e1d0806590231c439830db7ad54fda \
                --builder.local_relay=true \
                --builder.relay_secret_key=0x2e0834786285daccd064ca17f1654f67b4aef298acbb82cef9ec422fb4975622 \
                --builder.secret_key=0x2e0834786285daccd064ca17f1654f67b4aef298acbb82cef9ec422fb4975622 \
                --datadir=./execution \
                --http \
                --http.addr=0.0.0.0 \
                --http.api=engine,eth,web3,net,debug,flashbots \
                --mine \
                --miner.algotype=greedy \
                --miner.etherbase=0x123463a4B065722E99115D6c222f267d9cABb524 \
                --nodiscover \
                --password=./execution/geth_password.txt \
                --syncmode=full \
                --unlock=0x123463a4B065722E99115D6c222f267d9cABb524 \
                --verbosity=3
              '';
              environment = [
                "BUILDER_TX_SIGNING_KEY=0x2e0834786285daccd064ca17f1654f67b4aef298acbb82cef9ec422fb4975622"
              ];
            };

            # Consensus client:
            #   Runs a Prysm beacon chain from a specified genesis state created in the previous step
            #   and connects to go-ethereum in the same network as the execution client.
            #   The account used in go-ethereum is set as the suggested fee recipient for transactions
            #   proposed via the validators attached to the beacon node.
            beacon-chain = {
              command = ''
                ${prysm}/bin/beacon-chain \
                --accept-terms-of-use \
                --bootstrap-node= \
                --chain-config-file=./consensus/config.yml \
                --chain-id=32382 \
                --datadir=./consensus/beacon \
                --execution-endpoint=http://localhost:8551 \
                --genesis-state=./consensus/genesis.ssz \
                --grpc-gateway-host=0.0.0.0 \
                --http-mev-relay=http://localhost:28545 \
                --interop-eth1data-votes \
                --jwt-secret=./config/jwtsecret \
                --interop-num-validators=64 \
                --min-sync-peers=0 \
                --rpc-host=0.0.0.0 \
                --suggested-fee-recipient=0x123463a4B065722E99115D6c222f267d9cABb524
              '';
              depends_on.geth.condition = "service_started";
            };

            # Validator client:
            #   We run a validator client with 64, deterministically-generated keys that match
            #   The validator keys present in the beacon chain genesis state generated a few steps above.
            validator = {
              command = ''
                ${prysm}/bin/validator \
                --accept-terms-of-use \
                --beacon-rpc-provider=127.0.0.1:4000 \
                --chain-config-file=./consensus/config.yml \
                --datadir=./consensus/validator \
                --enable-builder \
                --interop-num-validators=64 \
                --interop-start-index=0 \
                --suggested-fee-recipient=0x123463a4B065722E99115D6c222f267d9cABb524
              '';
              depends_on.beacon-chain.condition = "service_started";
            };
          };
        };
      };
    };
}
