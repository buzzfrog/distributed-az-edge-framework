#!/bin/bash
git clone --single-branch --branch deploy-to-azure https://github.com/buzzfrog/distributed-az-edge-framework.git gitsource
sleep 15

cd ./gitsource/iotedge/Distributed.IoT.Edge
DATAGATEWAYIMAGE=datagatewaymodule:$TAG
SIMTEMPIMAGE=simulatedtemperaturesensormodule:$TAG
az acr build --image $DATAGATEWAYIMAGE --registry $ACRNAME --file Distributed.IoT.Edge.DataGatewayModule/Dockerfile .
az acr build --image $SIMTEMPIMAGE --registry $ACRNAME --file Distributed.IoT.Edge.SimulatedTemperatureSensorModule/Dockerfile .

az aks install-cli

curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh

az aks get-credentials --admin --name $AKSNAME --resource-group $RESOURCEGROUPNAME --overwrite-existing

#----- Dapr
helm repo add dapr https://dapr.github.io/helm-charts/
helm repo update
helm upgrade --install dapr dapr/dapr \
    --version=1.5 \
    --namespace dapr-system \
    --create-namespace \
    --wait

#----- Redis
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
helm install redis bitnami/redis --set cluster.enabled=false --wait

DATAGATEWAYIMAGEFULL="${ACRNAME}.azurecr.io/${DATAGATEWAYIMAGE}"
SIMTEMPIMAGEFULL="${ACRNAME}.azurecr.io/${SIMTEMPIMAGE}"

helm install iot-edge-accelerator ../../deployment/helm/iot-edge-accelerator --set-string images.datagatewaymodule=$DATAGATEWAYIMAGEFULL --set-string images.simulatedtemperaturesensormodule=$SIMTEMPIMAGEFULL --set-string dataGatewayModule.eventHubConnectionString=$EVENTHUB_CONNECTIONSTRING --set-string dataGatewayModule.storageAccountName=$STORAGENAME --set-string dataGatewayModule.storageAccountKey=$STORAGEKEY --wait
