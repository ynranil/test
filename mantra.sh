#!/bin/bash
echo "
╭━━━╮╱╱╱╱╱╱╭━━━╮
┃╭━╮┃╱╱╱╱╱╱┃╭━╮┃
┃┃╱╰╋━━┳┳━╮┃╰━━┳━━┳╮╱╭┳┳━┳━━┳━━┳╮╭╮
┃┃╱╭┫╭╮┣┫╭╮╋━━╮┃┃━┫┃╱┃┣┫╭┫╭━┫╭╮┃╰╯┃
┃╰━╯┃╰╯┃┃┃┃┃╰━╯┃┃━┫╰━╯┃┃┣┫╰━┫╰╯┃┃┃┃
╰━━━┻━━┻┻╯╰┻━━━┻━━┻━╮╭┻┻┻┻━━┻━━┻┻┻╯
╱╱╱╱╱╱╱╱╱╱╱╱╱╱╱╱╱╭━╯┃
╱╱╱╱╱╱╱╱╱╱╱╱╱╱╱╱╱╱╰━━╯
"

read -p "Enter WALLET name:" WALLET
echo 'export WALLET='$WALLET
read -p "Enter your MONIKER :" MONIKER
echo 'export MONIKER='$MONIKER
read -p "Enter your PORT (for example 17, default port=26):" PORT
echo 'export PORT='$PORT
read -p "Enter your WEBSITE:" WEB
echo 'export WEBSITE='$WEB
read -p "Enter details:" DET
echo 'export DETAILS='$DET

# set vars
echo "export WALLET="$WALLET"" >> $HOME/.bash_profile
echo "export MONIKER="$MONIKER"" >> $HOME/.bash_profile
echo "export MANTRA_CHAIN_ID="mantra-hongbai-1"" >> $HOME/.bash_profile
echo "export MANTRA_PORT="$PORT"" >> $HOME/.bash_profile
source $HOME/.bash_profile

printLine() {
    echo "-----------------------------------------------------"
}

printWhite() {
    echo -e "\e[1m\e[37m$1\e[0m"
}

printLine
echo -e "Moniker:        \e[1m\e[37m$MONIKER\e[0m"
echo -e "Wallet:         \e[1m\e[37m$WALLET\e[0m"
echo -e "Chain id:       \e[1m\e[37m$MANTRA_CHAIN_ID\e[0m"
echo -e "Node custom port:  \e[1m\e[37m$MANTRA_PORT\e[0m"
printLine
sleep 1

printWhite "1. Installing go..." && sleep 1
# install go, if needed
cd $HOME
VER="1.21.3"
wget "https://golang.org/dl/go$VER.linux-amd64.tar.gz"
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf "go$VER.linux-amd64.tar.gz"
rm "go$VER.linux-amd64.tar.gz"
[ ! -f ~/.bash_profile ] && touch ~/.bash_profile
echo "export PATH=$PATH:/usr/local/go/bin:~/go/bin" >> ~/.bash_profile
source $HOME/.bash_profile
[ ! -d ~/go/bin ] && mkdir -p ~/go/bin

echo $(go version) && sleep 1

source <(curl -s https://raw.githubusercontent.com/itrocket-team/testnet_guides/main/utils/dependencies_install)

printWhite "4. Installing binary..." && sleep 1
# download binary
cd $HOME
sudo wget -O /usr/lib/libwasmvm.x86_64.so https://github.com/CosmWasm/wasmvm/releases/download/v1.3.1/libwasmvm.x86_64.so
wget https://github.com/MANTRA-Finance/public/raw/main/mantrachain-hongbai/mantrachaind-linux-amd64.zip
unzip mantrachaind-linux-amd64.zip
rm mantrachaind-linux-amd64.zip
mv mantrachaind $HOME/go/bin

printWhite "5. Configuring and init app..." && sleep 1
# config and init app
mantrachaind config node tcp://localhost:${MANTRA_PORT}657
mantrachaind config keyring-backend os
mantrachaind config chain-id mantra-hongbai-1
mantrachaind init $MONIKER --chain-id mantra-hongbai-1
sleep 1
echo done

printWhite "6. Downloading genesis and addrbook..." && sleep 1
# download genesis and addrbook
wget -O $HOME/.mantrachain/config/genesis.json https://testnet-files.itrocket.net/mantra/genesis.json
wget -O $HOME/.mantrachain/config/addrbook.json https://testnet-files.itrocket.net/mantra/addrbook.json
sleep 1
echo done

printWhite "7. Adding seeds, peers, configuring custom ports, pruning, minimum gas price..." && sleep 1
# set seeds and peers
SEEDS="a9a71700397ce950a9396421877196ac19e7cde0@mantra-testnet-seed.itrocket.net:22656"
PEERS="1a46b1db53d1ff3dbec56ec93269f6a0d15faeb4@mantra-testnet-peer.itrocket.net:22656"
sed -i -e "s/^seeds *=.*/seeds = \"$SEEDS\"/; s/^persistent_peers *=.*/persistent_peers = \"$PEERS\"/" $HOME/.mantrachain/config/config.toml

# set custom ports in app.toml
sed -i.bak -e "s%:1317%:${MANTRA_PORT}317%g;
s%:8080%:${MANTRA_PORT}080%g;
s%:9090%:${MANTRA_PORT}090%g;
s%:9091%:${MANTRA_PORT}091%g;
s%:8545%:${MANTRA_PORT}545%g;
s%:8546%:${MANTRA_PORT}546%g;
s%:6065%:${MANTRA_PORT}065%g" $HOME/.mantrachain/config/app.toml


# set custom ports in config.toml file
sed -i.bak -e "s%:26658%:${MANTRA_PORT}658%g;
s%:26657%:${MANTRA_PORT}657%g;
s%:6060%:${MANTRA_PORT}060%g;
s%:26656%:${MANTRA_PORT}656%g;
s%^external_address = \"\"%external_address = \"$(wget -qO- eth0.me):${MANTRA_PORT}656\"%;
s%:26660%:${MANTRA_PORT}660%g" $HOME/.mantrachain/config/config.toml

# config pruning
sed -i -e "s/^pruning *=.*/pruning = \"custom\"/" $HOME/.mantrachain/config/app.toml
sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"100\"/" $HOME/.mantrachain/config/app.toml
sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"50\"/" $HOME/.mantrachain/config/app.toml

# set minimum gas price, enable prometheus and disable indexing
sed -i 's|minimum-gas-prices =.*|minimum-gas-prices = "0.0002uom"|g' $HOME/.mantrachain/config/app.toml
sed -i -e "s/prometheus = false/prometheus = true/" $HOME/.mantrachain/config/config.toml
sed -i -e "s/^indexer *=.*/indexer = \"null\"/" $HOME/.mantrachain/config/config.toml
sleep 1
echo done

# create service file
sudo tee /etc/systemd/system/mantrachaind.service > /dev/null <<EOF
[Unit]
Description=mantra node
After=network-online.target
[Service]
User=$USER
WorkingDirectory=$HOME/.mantrachain
ExecStart=$(which mantrachaind) start --home $HOME/.mantrachain
Restart=on-failure
RestartSec=5
LimitNOFILE=65535
[Install]
WantedBy=multi-user.target
EOF

printWhite "8. Downloading snapshot and starting node..." && sleep 1
# reset and download snapshot
mantrachaind tendermint unsafe-reset-all --home $HOME/.mantrachain
if curl -s --head curl https://testnet-files.itrocket.net/mantra/snap_mantra.tar.lz4 | head -n 1 | grep "200" > /dev/null; then
  curl https://testnet-files.itrocket.net/mantra/snap_mantra.tar.lz4 | lz4 -dc - | tar -xf - -C $HOME/.mantrachain
    else
  echo no have snap
fi

# enable and start service
sudo systemctl daemon-reload
sudo systemctl enable mantrachaind
sudo systemctl restart mantrachaind 
sleep 3
rm $HOME/validator.json
sleep 3
cd $HOME
# Create validator.json file
echo "{\"pubkey\":{\"@type\":\"/cosmos.crypto.ed25519.PubKey\",\"key\":\"$(mantrachaind comet show-validator | grep -Po '\"key\":\s*\"\K[^"]*')\"},
    \"amount\": \"1000000uward\",
    \"moniker\": \"$MONIKER\",
    \"identity\": \"\",
    \"website\": \"$WEB\",
    \"security\": \"\",
    \"details\": \"$DET\",
    \"commission-rate\": \"0.1\",
    \"commission-max-rate\": \"0.2\",
    \"commission-max-change-rate\": \"0.01\",
    \"min-self-delegation\": \"1\"
}" > validator.json
sleep 1
RPC="http://$(wget -qO- eth0.me)$(grep -A 3 "\[rpc\]" $HOME/.mantrachain/config/config.toml | egrep -o ":[0-9]+")" && echo $RPC
sleep 4
curl $RPC/status
sleep 2
echo $RPC
echo -e "sudo journalctl -u mantrachaind -f  "
sleep 1
mantrachaind keys add $WALLET
