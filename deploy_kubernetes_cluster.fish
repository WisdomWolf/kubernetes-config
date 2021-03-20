#!/usr/bin/env fish

./install-helm-packages.fish
set faas_installed (which faas-cli)
if test -z "$faas_installed"
    curl -sL https://cli.openfaas.com | sudo sh
else
    echo 'faas-cli is already installed...skipping'
end
set ark_installed (which arkade)
if test -z "$ark_installed"
    curl -SLsf https://dl.get-arkade.dev/ | sudo sh
else
    echo 'arkade is already installed...skipping'
end
ark install openfaas
#kubectl apply -R -f kube-vip/
kubectl apply -R -f traefik/ingress-configs/
kubectl apply -f papertrail/rkubelog-secret.yml
kubectl apply -k rkubelog
kubectl apply -f openfaas/faas-profile-noarm.yaml
kubectl apply -f openfaas/lastfm-api-secret.yaml
kubectl apply -f openfaas/ingressroute.yml
