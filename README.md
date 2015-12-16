nginx-letsencrypt-proxy
=====

nginx-letsencrypt-proxy is based on the officiel [nginx](https://registry.hub.docker.com/_/nginx/) image and includes a [docker-gen](https://hub.docker.com/r/jwilder/docker-gen/) template to generate vhosts configured to work with letsencrypt.

The idea is to have a default vhosts running on port 80 that will serve the acme-challenge files, or return a 301 to the https version of your site.

### Usage

First, create a data-only container for letsencrypt certificates.

    $ docker run -it \
      --name letsencrypt-data \
      --entrypoint /bin/echo \
      quay.io/letsencrypt/letsencrypt \
      "Data only container"

Next, start `nginx-letsencrypt-proxy` and `docker-gen`:

    $ docker run -it -d \
      --name nginx \
      --volumes-from letsencrypt-data \
      -p 80:80 \
      -p 443:443 \
      arnaudrebts/nginx-letsencrypt-proxy

    $ docker run -it -d \
      --name docker-gen \
      --volumes-from nginx \
      -v /var/run/docker.sock:/tmp/docker.sock:ro \
      jwilder/docker-gen \
      --watch \
      -only-exposed \
      -notify-sighup nginx \
      /etc/nginx/conf.d/99-vhosts.conf.tmpl \
      /etc/nginx/conf.d/99-vhosts.conf


Next, run letsencrypt to get the initial certificate, using the webroot authentication method:

    $ docker run -it --rm \
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
      --email foo@bar.com \
      -d bar.com


We can now start the backend containers:

    $ docker run -e VIRTUAL_HOST=bar.com ...

The containers must expose the port, using the EXPOSE directive in their Dockerfile, or using the --expose flag to `docker run` or `docker create`.

#### Custom letsencrypt domain name

By default, `nginx-letsencrypt-proxy` will use `VIRTUAL_HOST` to find the certificates in `/etc/letsencrypt/live`. You can override this with the `CERT_NAME` environment variable on the backend container:

    $ docker run -e VIRTUAL_HOST=foo.bar.com -e CERT_NAME=bar.com

#### SSL Backends

If your backend is using HTTPS, set `PROXY_SCHEME=https` on the backend container.
