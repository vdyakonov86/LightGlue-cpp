FROM ubuntu:22.04

ARG DEBIAN_FRONTEND=noninteractive

# create a non-root user
ARG USERNAME=ubuntu
ARG USER_UID=1000
ARG USER_GID=$USER_UID

RUN groupadd --gid $USER_GID $USERNAME \
    && useradd -s /bin/bash --uid $USER_UID --gid $USER_GID -m $USERNAME \
    && mkdir /home/$USERNAME/.config && chown $USER_UID:$USER_GID /home/$USERNAME/.config

# set up sudo privileges
RUN apt-get update \
    && apt-get install -y sudo \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME\
    && chmod 0440 /etc/sudoers.d/$USERNAME

# base utils
RUN apt-get install -y \
    vim \
    git \
    wget \
    curl \
    zip \
    unzip \
    python3 \
    python3-pip \
    x11-apps \
    # Autocomplete
    bash-completion \
    python3-argcomplete

# === SuperPoint
WORKDIR /SuperPoint
# WORKDIR /root/SuperPoint
COPY ws/SuperPoint .
RUN pip3 install -r requirements.txt
RUN pip3 install -e .
WORKDIR /
RUN sudo rm -r /SuperPoint

# Fix: libGL.so.1: cannot open shared object file: No such file or directory
RUN sudo apt-get update && sudo apt-get install ffmpeg libsm6 libxext6 -y
# === End SuperPoint

COPY scripts/.bashrc /home/${USERNAME}/bashrc
RUN cat /home/${USERNAME}/bashrc >> /home/${USERNAME}/.bashrc && rm /home/${USERNAME}/bashrc

# Remove folder in order to ensure to run apt-get update before installing new package 
# (without this folder 'apt-get update' will not work)
RUN rm -rf /var/lib/apt/lists/*

# switch from root to user
USER $USERNAME
# add user to video group to allow access to webcam
RUN sudo usermod --append --groups video $USERNAME

ENV LANG=en_US.UTF-8

CMD ["bash"]