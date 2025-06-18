FROM mcr.microsoft.com/windows/servercore:ltsc2025

SHELL ["powershell", "-Command"]

WORKDIR /tmp
RUN irm -outfile msys2-sfx.exe https://github.com/msys2/msys2-installer/releases/download/nightly-x86_64/msys2-base-x86_64-latest.sfx.exe

WORKDIR /
RUN c:\\tmp\\msys2-sfx.exe

ENV HOME=/home/ContainerAdministrator
ENV MSYS=winsymlinks:native
ENV TZ=America/New_York

CMD ["powershell"]
