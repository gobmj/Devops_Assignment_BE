# Use official Node.js image
FROM node:18

# Set the working directory
WORKDIR /app

# Copy package.json and install dependencies
COPY package.json package-lock.json ./
RUN npm install --production

# Copy application files
COPY . .

# Expose port
EXPOSE 3000

# Run the application
CMD ["node", "server.js"]
