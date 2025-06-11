# Utilisez la dernière image nginx comme base
FROM nginx:stable-alpine3.20
RUN apk update
RUN apk upgrade
RUN apk add htop

COPY app /usr/share/nginx/html


