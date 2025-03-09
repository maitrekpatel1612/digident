FROM debian:bullseye-slim

# Install dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    unzip \
    xz-utils \
    libglu1-mesa \
    && rm -rf /var/lib/apt/lists/*

# Set up Flutter
ENV FLUTTER_HOME=/flutter
RUN git clone https://github.com/flutter/flutter.git $FLUTTER_HOME
ENV PATH="$FLUTTER_HOME/bin:$PATH"

# Set Flutter to stable channel
RUN flutter channel stable
RUN flutter upgrade
RUN flutter config --no-analytics

# Set up the app
WORKDIR /app
COPY . .

# Get Flutter dependencies
RUN flutter pub get

# Build the web version
RUN flutter build web --release

# Expose port for serving
EXPOSE 8080

# Serve the web app
CMD ["flutter", "run", "-d", "web-server", "--web-port", "8080", "--web-hostname", "0.0.0.0"] 