nginx-letsencrypt-proxy
=====

nginx-letsencrypt-proxy is based on the officiel [nginx](https://registry.hub.docker.com/_/nginx/) image and includes a [docker-gen](https://hub.docker.com/r/jwilder/docker-gen/) template to generate vhosts configured to work with letsencrypt.

The idea is to have a default vhosts running on port 80 that will serve the acme-challenge files, or return a 301 to the https version of your site.

First, create a data-only container for letsencrypt certificates.
```
docker run -it \
  --name letsencrypt-data \
  --entrypoint /bin/echo \
  quay.io/letsencrypt/letsencrypt \
  "Data only container"
```

Next, start `nginx-letsencrypt-proxy` and `docker-gen`:
```
docker run -it -d \
  --name nginx \
  --restart always \
  --volumes-from letsencrypt-data \
  -p 80:80 \
  -p 443:443 \
  nginx-letsencrypt-proxy
```
```
docker run -it -d \
  --name docker-gen \
  --volumes-from=nginx \
  -v /var/run/docker.sock:/tmp/docker.sock:ro \
  jwilder/docker-gen \
  --watch \
  -only-exposed
  -notify-sighup nginx
  /etc/nginx/conf.d/99-vhosts.conf.tmpl \
  /etc/nginx/conf.d/99-vhosts.conf
```


Now, run the letsencrypt to get the initial certificate, using the webroot authentication method:
```
docker run -it --rm \
  --name letsencrypt \
  --volumes-from letsencrypt-data \
  --volumes-from nginx \
  quay.io/letsencrypt/letsencrypt \
  certonly \
  --webroot-path /var/www/letsencrypt \
  -a webroot \
  --text \
  --agree-tos \
  --renew-by-default \
  --email email@example.com \
  -d example.com
```
