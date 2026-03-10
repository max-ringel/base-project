FROM ubuntu:25.10

ARG TARGETARCH

ARG INSTALL_CLAUDE_CODE
ARG INSTALL_PYTHON3
ARG INSTALL_NODEJS

ENV NVM_DIR=/root/.nvm
ENV NODE_VERSION=24
ENV XDG_CONFIG_HOME=/root/.config

RUN apt update && apt install -y \
    git \
    curl \
    zsh \
    ripgrep \
    build-essential \
    fonts-noto-color-emoji \
    fd-find \
    xclip \
    unzip \
    && rm -rf /var/lib/apt/lists/*

RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" --unattended
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

RUN if [ "${INSTALL_NODEJS}" = "true" ]; then \
    mkdir -p $NVM_DIR \
    && curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash \
    && . $NVM_DIR/nvm.sh \
    && nvm install $NODE_VERSION \
    && nvm alias default $NODE_VERSION \
    && nvm use default \
    && npm install -g tree-sitter-cli \
    && ln -s "$NVM_DIR/versions/node/v$(. $NVM_DIR/nvm.sh && nvm version | sed 's/v//')/bin/node" /usr/local/bin/node \
    && ln -s "$NVM_DIR/versions/node/v$(. $NVM_DIR/nvm.sh && nvm version | sed 's/v//')/bin/npm" /usr/local/bin/npm \
    && ln -s "$NVM_DIR/versions/node/v$(. $NVM_DIR/nvm.sh && nvm version | sed 's/v//')/bin/tree-sitter" /usr/local/bin/tree-sitter \
    && echo 'export NVM_DIR="/root/.nvm"' >> /root/.zshrc \
    && echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' >> /root/.zshrc; \
    else \
    apt update && apt install -y nodejs npm \
    && rm -rf /var/lib/apt/lists/* \
    && npm install -g tree-sitter-cli; \
    fi

RUN if [ "${INSTALL_CLAUDE_CODE}" = "true" ]; then \
    curl -fsSL https://claude.ai/install.sh | bash \
    && ln -s /root/.local/bin/claude /usr/local/bin/claude; \
    fi


WORKDIR /app

CMD ["tail", "-f", "/dev/null"]
