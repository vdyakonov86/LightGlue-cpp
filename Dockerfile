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
    python3.11 \
    python3-pip \
    x11-apps \
    # Autocomplete
    bash-completion \
    python3-argcomplete

# Change default python version
RUN sudo update-alternatives --install /usr/bin/python python /usr/bin/python3.11 1 \
    && sudo update-alternatives --install /usr/bin/python python /usr/bin/python3.10 2 \
    && sudo update-alternatives --set python /usr/bin/python3.11

# RUN sudo apt remove -y python3-pip
# RUN sudo apt-get install -y python3-pip
# RUN python -m pip install --upgrade pip
# RUN export PATH=/home/ubuntu/.local/bin:$PATH

# === OpenCV
# Prerequisites
RUN apt-get install -y g++
# install cmake using pip in order to get latest version
RUN pip install cmake 

# Deps to fix opencv error when run orb-slam3
# RUN apt-get install -y libgtk2.0-dev pkg-config

# download and unpack sources
RUN wget -O opencv.zip https://github.com/opencv/opencv/archive/4.9.0.zip \
    && unzip opencv.zip \
    && mv opencv-4.9.0 opencv \
    && rm opencv.zip

# build
RUN mkdir -p /opencv_build \
    && cd /opencv_build \
    && cmake -DBUILD_TESTS=OFF ../opencv \
    && make -j4

# install, remove source/build files
RUN cd /opencv_build \
    && sudo make install \
    && cd .. \
    && rm -rf /opencv /opencv_build

# === End OpenCV

# === LightGlue
RUN pip install setuptools
WORKDIR /LightGlue
COPY ws/LightGlue .
RUN python -m pip install -e .
WORKDIR /
RUN sudo rm -r /LightGlue
# === End LightGlue

# === LightGlue-ONNX
WORKDIR /LightGlue-ONNX
COPY ws/LightGlue-ONNX .
COPY scripts/setup.py /LightGlue-ONNX/setup.py
RUN python -m pip install .
WORKDIR /
RUN sudo rm -r /LightGlue-ONNX
RUN python -m pip install torch onnx PyQt5
# Fix Could not load the Qt platform plugin "xcb"
RUN sudo python -m pip uninstall opencv-python opencv-contrib-python opencv-python-headless -y
RUN python -m pip install opencv-python-headless
RUN sudo apt-get install '^libxcb.*-dev' libx11-xcb-dev libglu1-mesa-dev libxrender-dev libxi-dev libxkbcommon-dev libxkbcommon-x11-dev -y
# RUN sudo apt-get install libxcb-xinerama0 libqt5x11extras5 libxcb-cursor0 -y
# === End LightGlue-ONNX

# Fix: libGL.so.1: cannot open shared object file: No such file or directory
RUN sudo apt-get update && sudo apt-get install ffmpeg libsm6 libxext6 -y

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