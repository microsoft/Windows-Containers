FROM mcr.microsoft.com/windows/servercore:ltsc2025

ENV CUSTOM_WIDTH=1920
ENV CUSTOM_HEIGHT=1080
ENV SERVICE_NAME=ResolutionService

WORKDIR /app
COPY Resolution.h .
COPY client.exe .
COPY server.exe .
COPY setres.exe .

ENTRYPOINT [ "powershell.exe" ]