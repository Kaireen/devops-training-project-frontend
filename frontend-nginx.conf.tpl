server {
        listen 8080;
        listen [::]:8080;

        root /usr/share/nginx/html;
        index index.html index.htm;

        server_name ${APP_NAME} www.${APP_NAME};

        location / {
                try_files $uri $uri/ =404;
        }

        location /api {
                rewrite /api/(.*) /$1 break;
                proxy_pass http://${BACKEND_IP}:${BACKEND_PORT};
        }
}