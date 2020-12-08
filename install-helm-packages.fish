#!/usr/bin/env fish
helm install -n portainer portainer portainer/portainer --set service.type=ClusterIP
for service_file in (ls helm_values/headless-service)
    set service_name (string split '_' $service_file)[1]
    helm install $service_name ../headless-service -f helm_values/headless-service/$service_file
end
