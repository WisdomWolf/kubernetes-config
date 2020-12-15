#!/usr/bin/env fish
set installed_charts (helm list --all-namespaces | tail -n +2 | awk '{print $1}')

## PORTAINER
if contains portainer $installed_charts
    echo 'skipping portainer install'
else
    helm install -n portainer portainer portainer/portainer --set service.type=ClusterIP
end

## TRAEFIK
if contains traefik $installed_charts
    echo 'traefik is already installed...skipping'
else
    helm install -n traefik traefik traefik/traefik -f traefik/traefik-values.yml
end

## CERT-MANAGER
if contains cert-manager $installed_charts
    echo 'cert-manager is already install...skipping'
else
    helm install cert-manager jetstack/cert-manager \
      --namespace cert-manager \
      --version v1.1.0 \
      --set installCRDs=true \
      --set 'extraArgs={--dns01-recursive-nameservers-only,--dns01-recursive-nameservers=8.8.8.8:53\,1.1.1.1:53}'
end

## MISC CHARTS
# Also need to update install to not rely on relative path for chart reference
for service_file in (ls helm_values/headless-service)
    set service_name (string split '_' $service_file)[1]
    if contains $service_name $installed_charts
        echo "skipping install of $service_name because it is already installed"
    else
        helm install $service_name ../headless-service -f helm_values/headless-service/$service_file
    end
end
