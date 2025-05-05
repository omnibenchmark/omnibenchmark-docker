FROM ubuntu:24.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive

# Create non-root user for running the container
RUN groupadd -r user && useradd -r -g user -m -s /bin/bash user && \
    mkdir -p /omni && \
    chown -R user:user /omni && \
    mkdir -p /opt/easybuild && \
    chown -R user:user /opt/easybuild && \
    chmod 755 /root

# Install base system utilities
RUN apt-get update && apt-get install -y \
    software-properties-common \
    apt-utils \
    bash \
    coreutils \
    git \
    wget \
    curl \
    vim-tiny \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install python and other python deps
RUN apt-get update && apt-get install -y \
    python3-pip \
    python3-venv

# Install Miniconda (snakemake needs the conda binary)
# RUN wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O /tmp/miniconda.sh && \
#    bash /tmp/miniconda.sh -b -p /opt/conda && \
#    rm /tmp/miniconda.sh && \
#    /opt/conda/bin/conda clean -tipy && \
#    ln -s /opt/conda/etc/profile.d/conda.sh /etc/profile.d/conda.sh && \
#    echo ". /opt/conda/etc/profile.d/conda.sh" >> /etc/bash.bashrc && \
#    echo "conda activate base" >> /etc/bash.bashrc && \
#    chown -R user:user /opt/conda

# Add conda to PATH
# ENV PATH="/opt/conda/bin:$PATH"

# Install apptainer and dependencies
RUN apt-get update && add-apt-repository -y ppa:apptainer/ppa \
    && apt-get install -y \
    libopenmpi-dev \
    debootstrap \
    apptainer \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install Lmod and dependencies
RUN apt-get update && apt-get install -y \
    lua5.2 \
    liblua5.2-dev \
    lua-filesystem \
    lua-posix \
    tcl \
    tcl-dev \
    lmod \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Initialize Lmod for both interactive and non-interactive shells
# TODO: copy to user dir
RUN echo 'source /etc/profile.d/lmod.sh' >> ~/.bashrc && \
    # Create a .profile that sources modules for non-interactive shells
    echo 'source /etc/profile.d/lmod.sh' > ~/.profile && \
    # Create a modules directory for the user
    mkdir -p ~/.lmod/cache

# Add Lmod to PATH
ENV PATH="/usr/share/lmod/lmod/libexec:/home/user/.pixi/bin:$PATH"

# Install EasyBuild 5.0
RUN pip install --break-system-packages 'easybuild==5.0.0'

# Switch to non-root user
USER user
ENV HOME=/home/user \
    PATH="/home/user/.local/bin:/usr/share/lmod/lmod/libexec:$PATH" \
    EASYBUILD_PREFIX=/opt/easybuild

# Install micromamba (minimal conda implementation)
RUN mkdir -p /home/user/.local/bin && \
    mkdir -p /tmp/micromamba && \
    cd /tmp/micromamba && \
    wget -qO- https://micro.mamba.pm/api/micromamba/linux-64/latest | tar -xvj && \
    mv bin/micromamba /home/user/.local/bin/ && \
    cd / && \
    rm -rf /tmp/micromamba && \
    echo 'export PATH="/home/user/.local/bin:$PATH"' >> /home/user/.bashrc && \
    echo 'eval "$(micromamba shell hook -s bash)"' >> /home/user/.bashrc

# Install pixi (yet another alternative to conda & micromamba)
RUN curl -fsSL https://pixi.sh/install.sh | sh

# Copy bash configuration to the new user
RUN echo 'export EASYBUILD_PREFIX=/opt/easybuild' >> /home/user/.bashrc && \
    echo 'export PATH="/home/user/.local/bin:$PATH"' >> /home/user/.bashrc

# Set working directory

WORKDIR /omni

# Command to run when container starts
# To run as root: docker run --user root -it <image>
# To run as user (default): docker run -it <image>
ENTRYPOINT ["/bin/bash", "-l", "-c"]
CMD ["bash -l"]
