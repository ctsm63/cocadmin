#!/bin/bash
apt update
apt install -y docker.io
docker run -d -p 5000:5000 -e MONGO_URI="${MONGO_URI}" cocadmin/2048-mern

