# Set the base image to use for subsequent instructions
FROM mcr.microsoft.com/powershell

# Set the working directory inside the container
WORKDIR /usr/src

# Copy any source file(s) required for the action
COPY start.ps1 .

# Configure the container to be run as an executable
ENTRYPOINT ["pwsh", "/usr/src/start.ps1"]