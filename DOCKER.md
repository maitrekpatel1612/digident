# Docker Setup for Digident

This document provides instructions for running the Digident project using Docker containers.

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/)
- [Docker Compose](https://docs.docker.com/compose/install/)

## Project Structure

The Digident project is containerized with Docker:

- **Backend**: Python-based server for camera streaming and WiFi hotspot functionality
- **Frontend**: Flutter-based mobile application for dental imaging and analysis

## Getting Started with Docker

### 1. Clone the Repository

```sh
git clone <repository-url>
cd digident
```

### 2. Build and Run with Docker Compose

```sh
docker-compose up --build
```

This command will:
- Build the Docker images for both backend and frontend
- Start the containers
- Set up the network between them

### 3. Access the Application

- **Backend API**: http://localhost:5000
- **Frontend Web Interface**: http://localhost:8080

## Configuration

### Environment Variables

You can modify the environment variables in the `docker-compose.yml` file:

#### Backend
- `SERVER_HOST`: The host IP address (default: 0.0.0.0)
- `SERVER_PORT`: The port number (default: 5000)

#### Frontend
- `SERVER_IP`: The backend server IP (default: backend)
- `SERVER_PORT`: The backend server port (default: 5000)

### Custom Configuration

To use custom configuration:

1. Create a `.env` file in the project root
2. Add your custom environment variables
3. Run Docker Compose with the environment file:

```sh
docker-compose --env-file .env up
```

## Development Workflow

### Running in Development Mode

For development with hot-reload:

```sh
docker-compose -f docker-compose.yml -f docker-compose.dev.yml up
```

### Rebuilding Containers

After making changes to the code:

```sh
docker-compose up --build
```

### Stopping Containers

```sh
docker-compose down
```

## Troubleshooting

### Connection Issues

If the frontend cannot connect to the backend:

1. Check that both containers are running:
   ```sh
   docker-compose ps
   ```

2. Verify network connectivity:
   ```sh
   docker network inspect digident-network
   ```

3. Check backend logs:
   ```sh
   docker-compose logs backend
   ```

### Port Conflicts

If you encounter port conflicts, modify the port mappings in `docker-compose.yml`:

```yaml
ports:
  - "8081:8080"  # Maps host port 8081 to container port 8080
```

## Production Deployment

For production deployment:

1. Build optimized images:
   ```sh
   docker-compose -f docker-compose.yml -f docker-compose.prod.yml build
   ```

2. Run in detached mode:
   ```sh
   docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d
   ```

## Additional Resources

- [Docker Documentation](https://docs.docker.com/)
- [Flutter Web Documentation](https://flutter.dev/docs/deployment/web)
- [Python Docker Guide](https://docs.docker.com/language/python/) 