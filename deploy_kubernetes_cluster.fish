#!/usr/bin/env fish

kubectl apply -R -f MetalLB/
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
ark install openfaas --load-balancer
