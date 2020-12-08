#!/usr/bin/env fish
helm install -n portainer portainer portainer/portainer --set service.type=ClusterIP
# This needs to be updated to be idempotent
# Also need to update install to not rely on relative path for chart reference
for service_file in (ls helm_values/headless-service)
    set service_name (string split '_' $service_file)[1]
    helm install $service_name ../headless-service -f helm_values/headless-service/$service_file
end
helm install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --version v1.1.0 \
  --set installCRDs=true \
  --set 'extraArgs={--dns01-recursive-nameservers-only,--dns01-recursive-nameservers=8.8.8.8:53\,1.1.1.1:53}'
helm install -n traefik traefik traefik/traefik -f traefik/traefik-values.yml
