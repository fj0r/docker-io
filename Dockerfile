FROM debian:testing-slim

ENV LANG=C.UTF-8 LC_ALL=C.UTF-8 TIMEZONE=Asia/Shanghai
ENV PYTHONUNBUFFERED=x

ARG nvim_repo=neovim/neovim
ARG wasmtime_repo=bytecodealliance/wasmtime
ARG just_repo=casey/just
ARG watchexec_repo=watchexec/watchexec
ARG yq_repo=mikefarah/yq
ARG websocat_repo=vi/websocat
ARG pup_repo=ericchiang/pup
ARG rg_repo=BurntSushi/ripgrep

ARG github_header="Accept: application/vnd.github.v3+json"
ARG github_api=https://api.github.com/repos

RUN set -eux \
  ; apt-get update \
  ; apt-get upgrade -y \
  ; DEBIAN_FRONTEND=noninteractive \
    apt-get install -y --no-install-recommends \
      locales tzdata sudo ca-certificates pwgen \
      openssh-client openssh-server gnupg rsync \
      inetutils-ping iproute2 nftables \
      mlocate htop procps xz-utils zstd zip unzip tree \
      zsh git curl tcpdump socat jq build-essential \
      python3 python3-dev python3-pip python3-setuptools ipython3 \
  \
  ; curl -sL https://deb.nodesource.com/setup_14.x | bash - \
  ; apt-get install -y --no-install-recommends nodejs \
  \
  ; nvim_ver=$(curl -sSL -H "'$github_header'" $github_api/${nvim_repo}/releases | jq -r '.[0].tag_name') \
  ; nvim_url=https://github.com/${nvim_repo}/releases/download/${nvim_ver}/nvim-linux64.tar.gz \
  ; curl -sSL ${nvim_url} | tar zxf - -C /usr/local --strip-components=1 \
  ; pip3 --no-cache-dir install neovim neovim-remote \
        fastapi uvicorn aiohttp aiofile \
        PyParsing decorator more-itertools \
        typer hydra-core pyyaml invoke fabric \
        cachetools chronyk fn.py \
  \
  ; ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime \
  ; echo "$TIMEZONE" > /etc/timezone \
  ; sed -i /etc/locale.gen \
        -e 's/# \(en_US.UTF-8 UTF-8\)/\1/' \
        -e 's/# \(zh_CN.UTF-8 UTF-8\)/\1/' \
  ; locale-gen \
  \
  ; sed -i 's/^.*\(%sudo.*\)ALL$/\1NOPASSWD:ALL/g' /etc/sudoers \
  ; sed -i /etc/ssh/sshd_config \
        -e 's!.*\(AuthorizedKeysFile\).*!\1 /etc/authorized_keys/%u!' \
        -e 's!.*\(GatewayPorts\).*!\1 yes!' \
        -e 's!.*\(PasswordAuthentication\).*yes!\1 no!' \
  ; apt-get autoremove -y && apt-get clean -y && rm -rf /var/lib/apt/lists/*

RUN set -ex \
  ; rg_ver=$(curl -sSL -H "'$github_header'" $github_api/${rg_repo}/releases | jq -r '.[0].tag_name') \
  ; rg_url=https://github.com/${rg_repo}/releases/download/${rg_ver}/ripgrep-${rg_ver}-x86_64-unknown-linux-musl.tar.gz \
  ; curl -sSL ${rg_url} | tar zxf - -C /usr/local/bin --strip-components=1 ripgrep-${rg_ver}-x86_64-unknown-linux-musl/rg \
  ; just_ver=$(curl -sSL -H "'$github_header'" $github_api/${just_repo}/releases | jq -r '.[0].tag_name') \
  ; just_url=https://github.com/${just_repo}/releases/download/${just_ver}/just-${just_ver}-x86_64-unknown-linux-musl.tar.gz \
  ; curl -sSL ${just_url} | tar zxf - -C /usr/local/bin just \
  ; watchexec_ver=$(curl -sSL -H "'$github_header'" $github_api/${watchexec_repo}/releases | jq -r '.[0].tag_name') \
  ; watchexec_url=https://github.com/${watchexec_repo}/releases/download/${watchexec_ver}/watchexec-${watchexec_ver}-x86_64-unknown-linux-musl.tar.xz \
  ; curl -sSL ${watchexec_url} | tar Jxf - --strip-components=1 -C /usr/local/bin watchexec-${watchexec_ver}-x86_64-unknown-linux-musl/watchexec \
  ; yq_ver=$(curl -sSL -H "'$github_header'" $github_api/${yq_repo}/releases | jq -r '.[0].tag_name') \
  ; yq_url=https://github.com/${yq_repo}/releases/download/${yq_ver}/yq_linux_amd64 \
  ; curl -sSLo /usr/local/bin/yq ${yq_url} ; chmod +x /usr/local/bin/yq \
  ; websocat_ver=$(curl -sSL -H "'$github_header'" $github_api/${websocat_repo}/releases | jq -r '.[0].tag_name') \
  ; websocat_url=https://github.com/${websocat_repo}/releases/download/${websocat_ver}/websocat_amd64-linux-static \
  ; curl -sSLo /usr/local/bin/websocat ${websocat_url} ; chmod +x /usr/local/bin/websocat \
  ; pup_ver=$(curl -sSL -H "'$github_header'" $github_api/${pup_repo}/releases | jq -r '.[0].tag_name') \
  ; pup_url=https://github.com/${pup_repo}/releases/download/${pup_ver}/pup_${pup_ver}_linux_amd64.zip \
  ; curl -sSLo pup.zip ${pup_url} && unzip pup.zip && rm -f pup.zip && chmod +x pup && mv pup /usr/local/bin/ \
  ; wasmtime_ver=$(curl -sSL -H "'$github_header'" $github_api/${wasmtime_repo}/releases | jq -r '[.[]|select(.prerelease == false)][0].tag_name') \
  ; wasmtime_url=https://github.com/${wasmtime_repo}/releases/download/${wasmtime_ver}/wasmtime-${wasmtime_ver}-x86_64-linux.tar.xz \
  ; curl -sSL ${wasmtime_url} | tar Jxf - --strip-components=1 -C /usr/local/bin wasmtime-${wasmtime_ver}-x86_64-linux/wasmtime

# conf
RUN set -eux \
  ; cfg_home=/etc/skel \
  ; mkdir $cfg_home/.zshrc.d \
  ; git clone --depth=1 https://github.com/murphil/.zshrc.d.git $cfg_home/.zshrc.d \
  ; cp $cfg_home/.zshrc.d/_zshrc $cfg_home/.zshrc \
  \
  ; mkdir -p /opt/language-server \
  ; mkdir -p /opt/vim \
  \
  ; mkdir $cfg_home/.config \
  ; nvim_home=$cfg_home/.config/nvim \
  ; git clone --depth=1 https://github.com/murphil/nvim-coc.git $nvim_home \
  ; NVIM_SETUP_PLUGINS=1 \
    nvim -u $nvim_home/init.vim --headless +'PlugInstall' +qa \
  #; rm -rf $nvim_home/plugged/*/.git \
  ; for x in $(cat $nvim_home/coc-core-extensions) \
  ; do nvim -u $nvim_home/init.vim --headless +"CocInstall -sync coc-$x" +qa; done \
  ; mv $nvim_home/coc-data /opt/vim && chmod -R 777 /opt/vim/coc-data \
  ; ln -sf /opt/vim/coc-data $nvim_home \
  ; mv $nvim_home/plugged /opt/vim \
  ; ln -sf /opt/vim/plugged $nvim_home \
  \
  ; SKIP_CYTHON_BUILD=1 $nvim_home/plugged/vimspector/install_gadget.py --enable-python \
  ; rm -f $nvim_home/plugged/vimspector/gadgets/linux/download/debugpy/*/*.zip \
  \
  ; coc_lua_bin_repo=josa42/coc-lua-binaries \
  ; lua_ls_ver=$(curl -sSL -H "'$github_header'" $github_api/${coc_lua_bin_repo}/releases | jq -r '.[0].tag_name') \
  ; lua_ls_url=https://github.com/${coc_lua_bin_repo}/releases/download/${lua_ls_ver}/lua-language-server-linux.tar.gz \
  ; lua_coc_data=$nvim_home/coc-data/extensions/coc-lua-data \
  ; mkdir -p $lua_coc_data \
  ; curl -sSL ${lua_ls_url} | tar zxf - -C $lua_coc_data \
  #; npm config set registry https://registry.npm.taobao.org \
  ; npm cache clean -f

WORKDIR /world

ENV SSH_USERS=
ENV SSH_ENABLE_ROOT=
ENV SSH_OVERRIDE_HOST_KEYS=

COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT [ "/entrypoint.sh" ]
