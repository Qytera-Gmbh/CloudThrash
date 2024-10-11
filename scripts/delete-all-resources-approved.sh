#!/bin/bash

pushd $(dirname $0) > /dev/null

./delete-all-resources.sh -y

popd > /dev/null
