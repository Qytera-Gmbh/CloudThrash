#!/bin/bash

pushd $(dirname $0) > /dev/null

./stop-test.sh --all

popd > /dev/null
