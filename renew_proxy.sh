#!/bin/bash

export X509_USER_PROXY=/tmp/x509up_u$(id -u)_kcron
ROLE=Analysis

echo -e "\ncleaning up existing proxy ...\n" 
voms-proxy-destroy

echo -e "\ncigetcert ...\n" 
kx509 -o ${X509_USER_PROXY} && \
echo "got certigicate" || \
(exitcode=$?; echo -e "Error while getting certigicate\ncigetcert exited with exit code: $exitcode"; exit $exitcode)

echo -e "\nCreate the proxy for user ${USER} with role ${ROLE} ...\n" 
voms-proxy-init -noregen -rfc -voms fermilab:/fermilab/nova/Role=${ROLE} -valid 120:00 && \
echo "proxy created" || \
(exitcode=$?; echo -e "Error while creating proxy\nvoms-proxy-init exited with exit code: $exitcode"; exit $exitcode)

echo -e "\nDisplay proxyinfo ...\n" 
voms-proxy-info -all && \
echo "the proxy is OK" || \
(exitcode=$?; echo -e "Error while checking proxy\nvoms-proxy-info exited with exit code: $exitcode"; exit $exitcode)

echo "Updating the proxy" 
mv ${X509_USER_PROXY} /var/tmp/${USER}.${ROLE}.proxy