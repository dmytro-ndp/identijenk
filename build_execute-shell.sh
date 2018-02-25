# default arguments
COMPOSE_ARGS=" -f jenkins.yml -p jenkins "

# stop and remove all old containers
sudo docker-compose $COMPOSE_ARGS stop
sudo docker-compose $COMPOSE_ARGS rm --force -v

# build an image
sudo docker-compose $COMPOSE_ARGS build --no-cache
sudo docker-compose $COMPOSE_ARGS up -d

# execute unit tests
sudo docker-compose $COMPOSE_ARGS run --no-deps --rm -e ENV=UNIT identidock
ERR=$?

# system-wide testing
if [ $ERR -eq 0 ]; then
  IP=$(sudo docker inspect -f {{.NetworkSettings.IPAddress}} jenkins_identidock_1)
  CODE=$(curl -sL -w "%{http_code}" $IP:9090/monster/bla -o /dev/null) || true
  if [ $CODE -eq 200 ]; then
    echo "Test passed - Tagging"
    HASH=$(git rev-parse --short HEAD)
    sudo docker tag jenkins_identidock ndp-home:5000/identidock:$HASH
    sudo docker tag jenkins_identidock ndp-home:5000/identidock:newest
    echo "Pushing"
    sudo docker push ndp-home:5000/identidock:$HASH
    sudo docker push ndp-home:5000/identidock:newest
  else
    echo "Site returned " $CODE
    ERR=1
  fi
fi

# stop and remove system
sudo docker-compose $COMPOSE_ARGS stop
sudo docker-compose $COMPOSE_ARGS rm --force -v

return $ERR