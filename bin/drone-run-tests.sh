#!/bin/sh
docker-compose --file docker-compose.drone-tests.yml rm -f # remove old containers
docker-compose --file docker-compose.drone-tests.yml up --build

echo "Inspecting exited containers:"
docker-compose --file docker-compose.drone-tests.yml ps
docker-compose --file docker-compose.drone-tests.yml ps -q | xargs docker inspect -f '{{ .State.ExitCode }}' | while read code; do
    if [ "$code" != "0" ]; then
       exit $code
    fi
done
