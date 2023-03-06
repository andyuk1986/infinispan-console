#!/usr/bin/env bash

set -e

if [[ $1 = "--ci" ]]; then
  echo "Launch script finished"
else
  trap "trap - SIGTERM && kill -- -$$" SIGINT SIGTERM EXIT
fi

#If running on the existing server please provide the Path with this property.
EXISTING_SERVER_PATH="${EXISTING_SERVER_PATH}"
#Base directory where the server should be downloaded
BASE_DIR="server"
#The version of the server is either set as an environment variable or is the latest dev version
SERVER_VERSION="${SERVER_VERSION:-"14.0.6.Final"}"
#Root path from there the infinispan server should be downloaded
ZIP_ROOT="http://downloads.jboss.org/infinispan"
#If this environment variable is provided then it is used for downloading the server;
SERVER_DOWNLOAD_URL="${SERVER_DOWNLOAD_URL}"
#The name of the zip file;
ZIP_NAME="${ZIP_NAME:-"infinispan-server-$SERVER_VERSION.zip"}"
#The name of directory where the server should be extracted;
SERVER_UNZIP_DIR="server-unzipped"
#Path to the extracted server;
SERVER_HOME=${BASE_DIR}/${SERVER_UNZIP_DIR}

CONF_DIR_TO_COPY_FROM="scripts/"
DATA_DIR="data/"
IS_SSL_PROCESSED=0
#The working directory - the server is copied to this directory and later changes are done to this dir;
SERVER_DIR_PREFIX="infinispan-server-"
SERVER_DIRECTORIES=()
BASE_SERVER_DIR="infinispan-server-1"
#CLI command for getting the cluster size
CLUSTER_SIZE_MAIN="$SERVER_HOME/bin/cli.sh -c localhost:11322 -f batch "

USER_NAME="admin"
PASSWORD="password"

#Function prepares the server directory, i.e. downloads, extracts, copies to working directory and makes changes to configuration;
function prepareServerDir()
{
    local isCi=$1
    local confPath=$2
    local dirName=${3}

    cd ${BASE_DIR}
    if [ -n "${EXISTING_SERVER_PATH}" ]; then
      mkdir ${SERVER_UNZIP_DIR}
      cp -r ${EXISTING_SERVER_PATH} $SERVER_UNZIP_DIR
    else
      if [ ! -f ${ZIP_NAME} ]; then
        if [ -n "$SERVER_DOWNLOAD_URL" ]; then
          wget "${SERVER_DOWNLOAD_URL}"
        else
          wget "$ZIP_ROOT/$SERVER_VERSION/$ZIP_NAME";
        fi
      fi

      unzip -d $SERVER_UNZIP_DIR $ZIP_NAME
    fi

    cd ..

    if [[ -z "${SERVER_TMP}" ]]; then
         SERVER_TMP=${BASE_DIR}/${BASE_SERVER_DIR}
         mkdir ${SERVER_TMP} 2>/dev/null
         echo "Created temporary directory: $SERVER_TMP"

         cp -r ${SERVER_HOME}/*/* $SERVER_TMP
         echo "Server copied to temporary directory."
    fi

    cp -r ${SERVER_HOME}/*/server ${SERVER_TMP}/${dirName}

    cp "${CONF_DIR_TO_COPY_FROM}/${confPath}" ${SERVER_TMP}/${dirName}/conf
    echo "Infinispan configuration file ${confPath} copied to server ${dirName}."

    SERVER_DIRECTORIES+=("${SERVER_TMP}")
}

function prepareXSiteEnvironment() {
  for i in {2..4}
  do
    tmp_dir="${BASE_DIR}/${SERVER_DIR_PREFIX}${i}"
    mkdir ${tmp_dir}
    cp -r ${SERVER_DIRECTORIES[0]}/* ${tmp_dir}/
    SERVER_DIRECTORIES+=("${tmp_dir}")
  done
}

#Starts the server;
function startServer()
{
    local isCi=$1
    local confPath=$2
    local nodeName=${3}
    local jvmParam=${4}
    declare -i offset=0;

    prepareServerDir "${isCi}" ${confPath} ${nodeName}

    base_server=${SERVER_DIRECTORIES[0]}
    $base_server/bin/cli.sh user create ${USER_NAME} -p ${PASSWORD} -s ${nodeName}

    #Installing nashorn engine before server startup
    ${base_server}/bin/cli.sh install org.openjdk.nashorn:nashorn-core:15.4 --server-root=infinispan-4-e2e
    ${base_server}/bin/cli.sh install org.ow2.asm:asm:9.4  --server-root=infinispan-4-e2e
    ${base_server}/bin/cli.sh install org.ow2.asm:asm-commons:9.4  --server-root=infinispan-4-e2e
    ${base_server}/bin/cli.sh install org.ow2.asm:asm-tree:9.4  --server-root=infinispan-4-e2e
    ${base_server}/bin/cli.sh install org.ow2.asm:asm-util:9.4  --server-root=infinispan-4-e2e
    
    #Copying the adjusted server to other 3 instances for being able to run them in xsite repl state
    prepareXSiteEnvironment

    for i in "${SERVER_DIRECTORIES[@]}"
    do
      if [[ ${isCi} = "--ci" ]]; then
        nohup $i/bin/server.sh -Djavax.net.debug -Dorg.infinispan.openssl=false -c ${confPath} -s ${i}/${nodeName} -o ${offset} --node-name=${nodeName} ${jvmParam:-} &
      else
        ${i}/bin/server.sh -Djavax.net.debug -Dorg.infinispan.openssl=false -c ${confPath} -s ${i}/${nodeName} -o ${offset} --node-name=${nodeName} ${jvmParam:-} &
      fi
      offset+=100;
    done

    

    #Creating data in the server
    sleep 10
    cd $DATA_DIR/
    ./create-data.sh ${USER_NAME} ${PASSWORD}
}

#deleting the testable server directory
rm -drf server/${BASE_SERVER_DIR}
rm -drf server/${SERVER_UNZIP_DIR}

export JAVA_OPTS="-Xms512m -Xmx1024m -XX:MetaspaceSize=128M -XX:MaxMetaspaceSize=512m"

startServer "$1" infinispan-basic-auth.xml infinispan-4-e2e
echo "Infinispan Server for E2E tests has started."


if [[ $1 = "--ci" ]]; then
  echo "Launch script finished"
else
  # Wait until script stopped
  while :
  do
    sleep 5
  done
fi
