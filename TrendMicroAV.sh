#!/bin/bash
 
# PROXY_ADDR_PORT and PROXY_CREDENTIAL define proxy for software download and Agent activation
PROXY_ADDR_PORT='10.168.206.102:8080'
PROXY_CREDENTIAL='7472b2c9ac5a4087;TrendMicroDSA;:0ad1ffd3d6b8629345b145c74e9f70d2e514c207'
 
# RELAY_PROXY_ADDR_PORT and RELAY_PROXY_CREDENTIAL define proxy for Agent and Relay communication
RELAY_PROXY_ADDR_PORT='10.168.206.102:8080'
RELAY_PROXY_CREDENTIAL='08d8bf6a4d9849e9;TrendMicroDSA;:821b3e4b871c65482dcec7ba8ade96b4eb9f4a7e'
 
# HTTP_PROXY is exported for compatibility purpose, remove it if it is not needed in your environment 
export HTTP_PROXY=http://$PROXY_CREDENTIAL@$PROXY_ADDR_PORT/
export HTTPS_PROXY=http://$PROXY_CREDENTIAL@$PROXY_ADDR_PORT/
 
ACTIVATIONURL='dsm://agents.workload.in-1.cloudone.trendmicro.com:443/'
MANAGERURL='https://workload.in-1.cloudone.trendmicro.com:443'
CURLOPTIONS='--silent --tlsv1.2'
linuxPlatform='';
isRPM='';
 
if [[ $(/usr/bin/id -u) -ne 0 ]]; then
    echo You are not running as the root user.  Please try again with root privileges.;
    logger -t You are not running as the root user.  Please try again with root privileges.;
    exit 1;
fi;
 
if ! type curl >/dev/null 2>&1; then
    echo "Please install CURL before running this script."
    logger -t Please install CURL before running this script
    exit 1
fi
 
CURLOUT=$(eval curl -L $MANAGERURL/software/deploymentscript/platform/linuxdetectscriptv1/ -o /tmp/PlatformDetection $CURLOPTIONS;)
err=$?
if [[ $err -eq 60 ]]; then
    echo "TLS certificate validation for the agent package download has failed. Please check that your Workload Security Manager TLS certificate is signed by a trusted root certificate authority. For more information, search for \"deployment scripts\" in the Deep Security Help Center."
    logger -t TLS certificate validation for the agent package download has failed. Please check that your Workload Security Manager TLS certificate is signed by a trusted root certificate authority. For more information, search for \"deployment scripts\" in the Deep Security Help Center.
    exit 1;
fi
 
if [ -s /tmp/PlatformDetection ]; then
    . /tmp/PlatformDetection
else
    echo "Failed to download the agent installation support script."
    logger -t Failed to download the Deep Security Agent installation support script
    exit 1
fi
 
platform_detect
if [[ -z "${linuxPlatform}" ]] || [[ -z "${isRPM}" ]]; then
    echo Unsupported platform is detected
    logger -t Unsupported platform is detected
    exit 1
fi
 
if [[ ${linuxPlatform} == *"SuSE_15"* ]]; then
    if ! type pidof &> /dev/null || ! type start_daemon &> /dev/null || ! type killproc &> /dev/null; then
        echo Please install sysvinit-tools before running this script
        logger -t Please install sysvinit-tools before running this script
        exit 1
    fi
fi
 
echo Downloading agent package...
if [[ $isRPM == 1 ]]; then package='agent.rpm'
    else package='agent.deb'
fi
curl -H "Agent-Version-Control: on" -L $MANAGERURL/software/agent/${runningPlatform}${majorVersion}/${archType}/$package?tenantID=13810 -o /tmp/$package $CURLOPTIONS
 
echo Installing agent package...
rc=1
if [[ $isRPM == 1 && -s /tmp/agent.rpm ]]; then
    rpm -ihv /tmp/agent.rpm
    rc=$?
elif [[ -s /tmp/agent.deb ]]; then
    dpkg -i /tmp/agent.deb
    rc=$?
else
    echo Failed to download the agent package. Please make sure the package is imported in the Workload Security Manager
    logger -t Failed to download the agent package. Please make sure the package is imported in the Workload Security Manager
    exit 1
fi
if [[ ${rc} != 0 ]]; then
    echo Failed to install the agent package
    logger -t Failed to install the agent package
    exit 1
fi
 
echo Install the agent package successfully
 
sleep 15
/opt/ds_agent/dsa_control -r
/opt/ds_agent/dsa_control -x dsm_proxy://$PROXY_ADDR_PORT/
/opt/ds_agent/dsa_control -u $PROXY_CREDENTIAL
/opt/ds_agent/dsa_control -y relay_proxy://$RELAY_PROXY_ADDR_PORT/
/opt/ds_agent/dsa_control -w $RELAY_PROXY_CREDENTIAL
/opt/ds_agent/dsa_control -a $ACTIVATIONURL "tenantID:D89EEB1A-AB0F-E498-423B-C25C86DBD851" "token:8176635D-411D-1713-9C76-83844636E393"
# /opt/ds_agent/dsa_control -a dsm://agents.workload.in-1.cloudone.trendmicro.com:443/ "tenantID:D89EEB1A-AB0F-E498-423B-C25C86DBD851" "token:8176635D-411D-1713-9C76-83844636E393"
