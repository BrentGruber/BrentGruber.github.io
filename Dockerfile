FROM alpine:3.10 AS build

ENV HUGO_VERSION 0.72.0
ENV HUGO_BINARY hugo_${HUGO_VERSION}_Linux-64bit

RUN apk add --update nodejs npm

#Download and Install Hugo
RUN mkdir /usr/local/hugo
ADD https://github.com/spf13/hugo/releases/download/v${HUGO_VERSION}/${HUGO_BINARY}.tar.gz /usr/local/hugo/

RUN tar xzf /usr/local/hugo/${HUGO_BINARY}.tar.gz -C /usr/local/hugo/
RUN mv /usr/local/hugo/hugo /usr/bin/hugo
RUN rm /usr/local/hugo/${HUGO_BINARY}.tar.gz

COPY . /src

WORKDIR /src

RUN npm install -g postcss-cli
RUN npm install -g autoprefixer

RUN /usr/bin/hugo

FROM nlepage/distroless-http
COPY --from=build /src/public /www
COPY Caddyfile /Caddyfile
CMD ["-conf", "/Caddyfile"]