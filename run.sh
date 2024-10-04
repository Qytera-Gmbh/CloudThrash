#!/bin/bash

pushd app

./mvnw clean install
./mvnw javafx:run -Djavafx.run.args="-Xmx1g -Xmx4g"

popd
