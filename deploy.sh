#!/bin/bash

TARGET=$1

BLUE_SERVER="15.207.254.148"
GREEN_SERVER="13.200.222.94"

KEY="/var/lib/jenkins/.ssh/Firstkey.pem"

if [ "$TARGET" == "blue" ]; then

    SERVER=$BLUE_SERVER

    echo "<h1>BLUE Environment Deployment</h1>" > index.html

else

    SERVER=$GREEN_SERVER

    echo "<h1>GREEN Environment Deployment</h1>" > index.html

fi

echo "Deploying to $TARGET server: $SERVER"

scp -i $KEY -o StrictHostKeyChecking=no index.html ubuntu@$SERVER:/tmp/

ssh -T -i $KEY -o StrictHostKeyChecking=no ubuntu@$SERVER << EOF

sudo cp /tmp/index.html /var/www/html/index.html

sudo systemctl restart nginx

EOF

echo "Deployment completed"
