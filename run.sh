#!/bin/bash

pushd app

./mvnw clean install
./mvnw javafx:run 

popd
