# Docker file for react web app
FROM node:20-alpine AS build

# Set the working directory
WORKDIR /app

# Copy the package.json file
COPY package*.json ./

# Install the dependencies
RUN npm install

# Copy the source code
COPY . .

# Build the app
RUN npm run build

# Production environment
FROM nginx:alpine

# Copy the build files to the nginx server
COPY --from=build /app/build /usr/share/nginx/html

# Expose the port
EXPOSE 80

# Start the server
CMD ["nginx", "-g", "daemon off;"]