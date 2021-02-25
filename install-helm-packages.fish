#!/usr/bin/env fish
function check_date
    set service_name $argv[1]
    set service_file $argv[2]
    set func_name $argv[3]
    set modified_ts (stat -c%y $service_file)
    set installed_ts (helm list --all-namespaces | grep $service_name | awk -F'\t' '{print $4}')
    set result (./test_dates.py "$modified_ts" "$installed_ts")
    if [ -n "$result" ]
        eval $func_name
    end
end

function install_traefik
    echo 'installing traefik'
    kubectl create namespace traefik
    helm install -n traefik traefik traefik/traefik -f traefik/traefik-values.yml
end

function upgrade_traefik
    echo 'updating/upgrading traefik'
    helm upgrade -n traefik traefik traefik/traefik -f traefik/traefik-values.yml
end

helm repo add traefik https://containous.github.io/traefik-helm-chart
helm repo add jetstack https://charts.jetstack.io
helm repo add openfaas https://openfaas.github.io/faas-netes/
helm repo add portainer https://portainer.github.io/k8s/
helm repo add wise-charts https://wise-charts.developingwisdom.org
helm repo update

set installed_charts (helm list --all-namespaces | tail -n +2 | awk '{print $1}')

## PORTAINER
if contains portainer $installed_charts
    echo 'portainer is already installed...skipping'

else
    echo 'intalling portainer'
    kubectl create namespace portainer
    helm install -n portainer portainer portainer/portainer --set service.type=ClusterIP
end

## TRAEFIK
if contains traefik $installed_charts
    echo 'traefik is already installed'
    check_date traefik traefik/traefik-values.yml upgrade_traefik
else
    install_traefik
end

## CERT-MANAGER
if contains cert-manager $installed_charts
    echo 'cert-manager is already install...skipping'
else
    echo 'installing cert-manager'
    kubectl create namespace cert-manager
    helm install cert-manager jetstack/cert-manager \
      --namespace cert-manager \
      --version v1.1.0 \
      --set installCRDs=true \
      --set 'extraArgs={--dns01-recursive-nameservers-only,--dns01-recursive-nameservers=8.8.8.8:53\,1.1.1.1:53}'
    echo sleeping for 30 seconds...
    sleep 30
    kubectl apply -f cert-manager/letsencrypt-issuer-prod.yaml
    kubectl apply -f cert-manager/letsencrypt-issuer-staging.yaml
end

## MISC CHARTS
# Also need to update install to not rely on relative path for chart reference
for service_file in (ls helm_values/headless-service)
    # excluding sample.yaml
    if string match '*.yml' $service_file >> /dev/null
        set service_name (string split '_' $service_file)[1]"-headless"
        if contains $service_name $installed_charts
            # test to see if it was updated since install
            set modified_ts (stat -c%y helm_values/headless-service/$service_file)
            set installed_ts (helm list --all-namespaces | grep $service_name | awk -F'\t' '{print $4}')
            set result (./test_dates.py "$modified_ts" "$installed_ts")
            if [ -n "$result" ]
                echo "Attempting to update $service_name"
                helm upgrade $service_name ../headless-service -f helm_values/headless-service/$service_file
            else
                echo "No need to update $service_name...skipping"
            end
        else
            echo "Attempting to install $service_name"
            helm install $service_name wise-charts/headless-service -f helm_values/headless-service/$service_file
        end
    end
end
