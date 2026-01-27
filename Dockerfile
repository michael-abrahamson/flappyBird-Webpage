FROM node:20-slim

WORKDIR /app

# Install pnpm
RUN npm install -g pnpm

RUN npm install -g prettier prettier-plugin-svelte

# Copy only package files first
COPY package.json pnpm-lock.yaml* ./

# Install deps inside Linux (no Windows junk)
RUN pnpm install

# Copy rest of project (now safe because of .dockerignore)
COPY . .

CMD ["pnpm", "run", "model-pipeline:run"]
