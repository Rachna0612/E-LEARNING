# Use Nginx Alpine – lightweight web server for static HTML/CSS/JS
FROM nginx:alpine
 
# Remove default nginx page
RUN rm -rf /usr/share/nginx/html/*
 
# Copy your entire project into nginx's serving directory
COPY . /usr/share/nginx/html
 
# Expose port 80
EXPOSE 80
 
# Start nginx
CMD ["nginx", "-g", "daemon off;"]