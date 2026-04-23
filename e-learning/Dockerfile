FROM nginx:alpine

# Remove default nginx files
RUN rm -rf /usr/share/nginx/html/*

# Copy all project files
COPY . /usr/share/nginx/html

EXPOSE 80