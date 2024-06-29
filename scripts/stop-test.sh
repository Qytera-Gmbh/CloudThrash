#!/bin/bash

pushd $(dirname $0) > /dev/null
pushd ../terraform > /dev/null

terraform destroy -target=module.ecs -auto-approve
terraform destroy -target=module.network -auto-approve

popd > /dev/null
popd > /dev/null
