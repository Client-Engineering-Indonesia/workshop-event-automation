#!/bin/sh
echo "Installing ArgoCD..."
oc apply -f resources/00-gitops-subscription.yaml
i=0
while [ -z $(oc get pods --no-headers -n openshift-gitops | awk '$3=="Running" { ++count } END { print count }') ] && [ $i -lt 5 ]
do
    echo "Checking status... " $i
    echo "Sleeping for one minute..."
    sleep 60
    let "i++"
done
if [ ! -z $(oc get pods --no-headers -n openshift-gitops | awk '$3=="Running" { ++count } END { print count }') ]
then
    i=0
    while [ $(oc get pods --no-headers -n openshift-gitops | awk '$3=="Running" { ++count } END { print count }') -lt 8 ] && [ $i -lt 5 ]
    do
        echo "Checking status... " $i
        echo "Sleeping for one minute..."
        sleep 60
        let "i++"
    done
    if [ $(oc get pods --no-headers -n openshift-gitops | awk '$3=="Running" { ++count } END { print count }') -ge 8 ]
    then
        oc apply -f resources/00-gitops-rolebinding.yaml
        # The cluster issuer is not needed by ArgoCD, but rather some of the capabilities deployed via ArgoCD
        oc apply -f resources/00-gitops-clusterissuer.yaml
        oc patch argocd -n openshift-gitops openshift-gitops --patch '{"spec":{"kustomizeBuildOptions":"--enable-alpha-plugins=true --enable-exec"}}' --type=merge
        echo "ArgoCD is Ready."
        ARGOCD_URL=$(oc get argocd -n openshift-gitops openshift-gitops -o jsonpath='{.status.host}')
        ARGOCD_PWD=$(oc get secret -n openshift-gitops openshift-gitops-cluster -o jsonpath='{.data.admin\.password}' | base64 -d)
        echo "ARGOCD UI URL: https://"$ARGOCD_URL
        echo "ARGOCD admin user: admin"
        echo "ARGOCD admin password: "$ARGOCD_PWD
    else 
        echo "Something is wrong!"
        exit
    fi
fi
echo "Done!"