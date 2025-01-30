# Use Node.js as base image
FROM node:18-alpine

# Set working directory
WORKDIR /app

# Copy package.json and install dependencies
COPY package.json package-lock.json ./
RUN npm config set fetch-retry-mintimeout 20000 \
    && npm config set fetch-retry-maxtimeout 120000 \
    && npm install --only=production


# Copy the rest of the app files
COPY . .

# Build the React app
RUN npm run build

# Install `serve` to serve static files
RUN npm install -g serve

# Set the default command to serve the app
CMD ["serve", "-s", "build", "-l", "3000"]


