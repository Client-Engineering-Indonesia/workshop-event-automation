#!/bin/sh
# This script requires the oc command being installed in your environment 
# Before running the script you need to set two environment variables called "MAILTRAP_USER" and "MAILTRAP_PWD" with your maintrap info, using these command: 
# "export MAILTRAP_USER=my-mailtrap-user"
# "export MAILTRAP_PWD=my-mailtrap-pwd"
SUB_NAME=''
while [ -z "$SUB_NAME" ]
do
   echo "Entering loop..."
   SUB_NAME=$(oc get deployment cert-manager-operator-controller-manager -n cert-manager-operator --ignore-not-found -o jsonpath='{.metadata.labels.olm\.owner}')
   echo "Sleeping for 5 seconds..."
   sleep 5
done
echo $SUB_NAME
oc get csv/$SUB_NAME -n cert-manager-operator --ignore-not-found -o jsonpath='{.status.phase}'
exit 1
APIC_INST_NAME='apim-demo'
APIC_NAMESPACE='tools'
ADMIN_PWD=$(oc get secret "${APIC_INST_NAME}-mgmt-admin-pass" -n $APIC_NAMESPACE -o jsonpath="{.data.password}"| base64 -d)
echo "$ADMIN_PWD"
exit 1
if [ ! -z "$CP4I_TRACING" ]
then
echo "with NO tracing"
else
echo "with tracing"
fi
exit 1
if [ command -v runmqakm ]
then 
echo "All Good!"
else
echo "Something is wrong!"
fi
exit 1
n=$(oc get nodes  | awk '$2=="Ready" { ++count } END { print count }')
echo $n
exit 1
b=$(oc get csv --no-headers -n openshift-operators | awk '$(NF)=="Succeeded" { ++count } END { print count }')
if [ -z $b ]; then b=0; fi;
echo $b
let "b+=2"
echo $b
l=$b
echo $l
exit 1
i=0
while [ -z "$MY_ENV_VAR" ] && [ $i -lt 15 ]
do
echo $i
let "i++"
done
exit 1
if [ -z "$MAILTRAP_USER" ]; then echo "MAILTRAP_USER not set, it must be provided on the command line."; exit 1; fi;
if [ -z "$MAILTRAP_PWD" ]; then echo "MAILTRAP_PWD not set, it must be provided on the command line."; exit 1; fi;
echo "MAILTRAP_USER is set to" $MAILTRAP_USER
echo "MAILTRAP_PWD is set to" $MAILTRAP_PWD
read -p "Press <Enter> to execute script..."
i=0
while [ -z $(oc get platformnavigator --no-headers -n tools | awk '{print $4}') ] || [ $i -lt 15 ]
do
echo "Checking status..."
echo "Sleeping for five minute..."
sleep 300
let "i++"
done
if [ -z $(oc get platformnavigator --no-headers -n tools | awk '{print $4}') ]
then
echo "Something is wrong!"
curl --ssl-reqd \
--url "smtp://smtp.mailtrap.io:2525" \
--user "${MAILTRAP_USER}:${MAILTRAP_PWD}" \
--mail-from cp4i-admin@ibm.com \
--mail-rcpt cp4i-user@ibm.com \
--upload-file - <<EOF
From: CP4I Admin <cp4i-admin@ibm.com>
To: Mailtrap Inbox <cp4i-user@ibm.com>
Subject: Platform Navigator hasn't been deployed yet!
Content-Type: multipart/alternative; boundary="boundary-string"

--boundary-string
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: quoted-printable
Content-Disposition: inline

Something is wrong!

Inspect the Platform Navigator status.
Take corrective actions to complete the deployment.

Good luck! 

--boundary-string
EOF
else
i=0
while [ $(oc get platformnavigator --no-headers -n tools | awk '{print $4}') != "True" ] || [ $i -lt 15 ]
do
echo "Checking status..."
echo "Sleeping for five minute..."
sleep 300
let "i++"
done
if [ $(oc get platformnavigator --no-headers -n tools | awk '{print $4}') != "True" ]
then
echo "Something is wrong!"
curl --ssl-reqd \
--url "smtp://smtp.mailtrap.io:2525" \
--user "${MAILTRAP_USER}:${MAILTRAP_PWD}" \
--mail-from cp4i-admin@ibm.com \
--mail-rcpt cp4i-user@ibm.com \
--upload-file - <<EOF
From: CP4I Admin <cp4i-admin@ibm.com>
To: Mailtrap Inbox <cp4i-user@ibm.com>
Subject: Platform Navigator hasn't been deployed yet!
Content-Type: multipart/alternative; boundary="boundary-string"

--boundary-string
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: quoted-printable
Content-Disposition: inline

Something is wrong!

Inspect the Platform Navigator status.
Take corrective actions to complete the deployment.

Good luck! 

--boundary-string
EOF
else
echo "Platform Navigator is Ready."
curl --ssl-reqd \
--url "smtp://smtp.mailtrap.io:2525" \
--user "${MAILTRAP_USER}:${MAILTRAP_PWD}" \
--mail-from cp4i-admin@ibm.com \
--mail-rcpt cp4i-user@ibm.com \
--upload-file - <<EOF
From: CP4I Admin <cp4i-admin@ibm.com>
To: Mailtrap Inbox <cp4i-user@ibm.com>
Subject: Platform Navigator has been deployed!
Content-Type: multipart/alternative; boundary="boundary-string"

--boundary-string
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: quoted-printable
Content-Disposition: inline

Congrats Platform Navigator has been deployed.

Inspect it using the commands provided in the repo.
Now you can proceed to deploy Asset Repo.

Good luck! 

--boundary-string
EOF
fi
fi
echo "Done!"