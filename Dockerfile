FROM ubuntu:25.10

ARG TARGETARCH

ARG INSTALL_CLAUDE_CODE
ARG INSTALL_PYTHON3
ARG INSTALL_NODEJS

ARG NVIM_CONFIG_REPOSITORY

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
    eza \
    fzf \
    && rm -rf /var/lib/apt/lists/*

RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" --unattended
RUN ln -s $(which fdfind) /usr/local/bin/fd

# Oh My Zsh plugins and theme
RUN git clone https://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions \
    && git clone https://github.com/zsh-users/zsh-syntax-highlighting ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting \
    && git clone https://github.com/romkatv/powerlevel10k.git ~/.oh-my-zsh/custom/themes/powerlevel10k \
    && sed -i 's/plugins=(git)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting)/' ~/.zshrc \
    && sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="powerlevel10k\/powerlevel10k"/' ~/.zshrc

# Powerlevel10k configuration
COPY p10k.zsh /root/.p10k.zsh
RUN echo '[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh' >> ~/.zshrc

# eza setup
RUN echo 'alias ls="eza --icons"' >> ~/.zshrc \
    && echo 'alias ll="eza --icons -la"' >> ~/.zshrc \
    && echo 'alias lt="eza --icons --tree --level=2"' >> ~/.zshrc

# zoxide setup
RUN curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh -s -- --bin-dir /opt/zoxide \
    && ln -s /opt/zoxide/zoxide /usr/local/bin/zoxide
RUN echo 'eval "$(zoxide init zsh)"' >> ~/.zshrc

# fzf setup
RUN echo 'source <(fzf --zsh)' >> ~/.zshrc

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

RUN git clone "${NVIM_CONFIG_REPOSITORY}" "${XDG_CONFIG_HOME:-$HOME/.config}"/nvim

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

RUN if [ "$INSTALL_PYTHON3" = "true" ]; then \
    apt update && apt install -y \
    python3 \
    python3-pip \
    python3-venv \
    python-is-python3 \
    && pip install --break-system-packages pynvim \
    && rm -rf /var/lib/apt/lists/*; \
    fi

WORKDIR /app

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

CMD ["tail", "-f", "/dev/null"]
