#!/bin/bash

# folder containing the script is the root folder (priv/cloudi)
cd $(dirname $0)
code_path="'$(realpath `pwd`/../../_build/default/lib/pad_service_econfd_daemon/ebin)'"
ret=""

# add service
{
curl -X POST -d ''${code_path}'' http://localhost:6464/cloudi/api/rpc/code_path_add.erl
ret=$(curl -X POST -d @pad_service_econfd_daemon.conf http://localhost:6464/cloudi/api/rpc/services_add.erl)
} &> /dev/null

# check service
curl http://localhost:6464/econfd/daemons/econfd_daemon_default/status

# remove service
{
curl -X POST -d ''${ret}'' http://localhost:6464/cloudi/api/rpc/services_remove.erl
curl -X POST -d ''${code_path}'' http://localhost:6464/cloudi/api/rpc/code_path_remove.erl
} &> /dev/null

