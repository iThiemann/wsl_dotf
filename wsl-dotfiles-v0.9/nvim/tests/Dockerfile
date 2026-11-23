# Reproducible test of the whole setup on a clean Ubuntu 24.04:
#   docker build -f nvim/tests/Dockerfile -t nvim-devops-test .      (from the wsl-dotfiles root)
#   podman build -f nvim/tests/Dockerfile -t nvim-devops-test .
FROM ubuntu:24.04
ENV DEBIAN_FRONTEND=noninteractive LANG=C.UTF-8
RUN apt-get update -qq && apt-get install -y -qq sudo git curl ca-certificates jq \
 && useradd -m -s /bin/bash dev && echo 'dev ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/dev
USER dev
WORKDIR /home/dev
COPY --chown=dev:dev . /home/dev/wsl-dotfiles
# no zsh/WT in CI; everything else exactly as on your machine
RUN cd wsl-dotfiles && ./install.sh --no-zsh --no-wt
RUN bash -lc 'wsl-dotfiles/nvim/tests/run.sh'
