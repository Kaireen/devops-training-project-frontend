FROM node:16-alpine as builder

ARG API_ROOT="http://apiurl"

WORKDIR /app
COPY ./package.json ./
RUN npm install > /dev/null 2>&1

COPY ./ ./
RUN sed -i "s+^const API_ROOT =.*;$+const API_ROOT = \"${API_ROOT}\";+" src/agent.js && \
    npm run build && \
    sed -i "s+/static/js/+/js/+" ./build/index.html


FROM nginx:1.22-alpine as production

LABEL version="1.4"
LABEL owner="AleksandrPenko@coherentsolutions.com"

ENV API_ROOT="http://localhost:8080" \
    APP_NAME="webapp" \
    BACKEND_IP="localhost" \
    BACKEND_PORT="8081"

WORKDIR /usr/share/nginx/html

RUN apk upgrade --no-cache && \
    rm -rf ./*

COPY ./frontend-nginx.conf.tpl /etc/nginx/conf.d/
COPY --from=builder /app/build/* ./
RUN chown -R nginx:nginx /usr/share/nginx && chmod -R 755 /usr/share/nginx && \
    chown -R nginx:nginx /var/cache/nginx && \
    chown -R nginx:nginx /var/log/nginx && \
    chown nginx:nginx /etc/nginx && \
    chown -R nginx:nginx /etc/nginx/* && \
    touch /var/run/nginx.pid && \
    chown nginx:nginx /var/run/nginx.pid

USER nginx

EXPOSE 8080

CMD envsubst '$$APP_NAME $$BACKEND_IP $$BACKEND_PORT' < \
        /etc/nginx/conf.d/frontend-nginx.conf.tpl > \
        /etc/nginx/conf.d/default.conf && \
    sed -i "s+http://apiurl+${API_ROOT}+" /usr/share/nginx/html/js/main.*.js && \    
    nginx -g 'daemon off;'
