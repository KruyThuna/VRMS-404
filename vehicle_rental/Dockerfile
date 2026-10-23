FROM nginx:alpine

# Copy static flutter web build files
COPY build/web /usr/share/nginx/html

# Copy nginx configuration
COPY ../nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]

