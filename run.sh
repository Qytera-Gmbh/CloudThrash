#!/bin/bash

pushd ui

./mvnw clean install
./mvnw javafx:run 

popd
