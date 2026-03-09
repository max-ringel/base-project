FROM ubuntu:25.10

ARG TARGETARCH

RUN apt update && apt install -y \
    git \
    curl \
    zsh \
    ripgrep \
    build-essential \
    fonts-noto-color-emoji \
    nodejs \
    fd-find \
    xclip \
    unzip \
    npm \
    && rm -rf /var/lib/apt/lists/*

RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" --unattended
RUN npm install -g tree-sitter-cli
RUN ln -s $(which fdfind) /usr/local/bin/fd

RUN set -ex; \
    if [ "$TARGETARCH" = "amd64" ]; then \
        NVIM_ARCH="x86_64"; \
    elif [ "$TARGETARCH" = "arm64" ]; then \
        NVIM_ARCH="arm64"; \
    else \
        echo "Unsupported architecture: $TARGETARCH"; exit 1; \
    fi; \
    curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-$NVIM_ARCH.tar.gz; \
    rm -rf /opt/nvim-linux-$NVIM_ARCH; \
    tar -C /opt -xzf nvim-linux-$NVIM_ARCH.tar.gz; \
    rm "nvim-linux-$NVIM_ARCH.tar.gz"; \
    ln -s /opt/nvim-linux-$NVIM_ARCH/bin/nvim /usr/local/bin/nvim;
    
RUN git clone https://github.com/max-ringel/kickstart.nvim.git "${XDG_CONFIG_HOME:-$HOME/.config}"/nvim

WORKDIR /app

CMD ["tail", "-f", "/dev/null"]
