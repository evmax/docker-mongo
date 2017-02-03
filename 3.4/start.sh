#!/bin/bash
ADMIN=${MONGO_ADMIN_USERNAME:-"admin"}
USER=${MONGO_USER_USERNAME:-"user"}
DATABASE=${MONGO_SSO_DB:-"ssodb"}
PASS=${MONGO_ADMIN_PASS:-"1234"}


echo "=> start MongoDB"
mongod --fork --logpath /var/log/mongodb.log --auth --smallfiles &
RET=1
while [[ RET -ne 0 ]]; do
    echo "=> Waiting for MongoDB service startup"
    sleep 5
    mongo admin --eval "help" >/dev/null 2>&1
    RET=$?
done

if [ ! -f /.configured ]; then
  echo "=> Creating root admin: ${ADMIN}@admin"
  mongo admin --eval "db.createUser({user: '$ADMIN', pwd: '$PASS', roles:['root']});"
  echo "=> Creating ${USER}@${DATABASE}"
  mongo admin -u "${ADMIN}" -p "${PASS}" << EOF
use $DATABASE
db.createUser({user: '$USER', pwd: '$PASS', roles:[{role:'dbOwner', db:'$DATABASE'}]})
EOF
echo "=> Done!"
touch /.configured
fi

tail -f /var/log/mongodb.log
exec "$@"
