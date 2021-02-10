#!/usr/bin/env fish

kubectl apply -R -f MetalLB/
./install-helm-packages.fish
