FROM fedora

RUN yum -y update && yum -y install --allowerasing \
    git \
    automake \
    autoconf \
    bash \
    coreutils \
    expect \
    libtool \
    sed \
    libtpms \
    libtpms-devel \
    fuse \
    fuse-devel \
    glib2 \
    glib2-devel \
    net-tools \
    python3 \
    python3-twisted \
    selinux-policy-devel \
    trousers \
    tpm-tools \
    gnutls \
    gnutls-devel \
    gnutls-utils \
    libtasn1 \
    libtasn1-tools \
    libtasn1-devel \
    nspr-devel \
    openssl-devel \
    glibc-headers \
    nss-devel \
    nss-softokn-freebl-devel \
    nss-softokn-devel \
    gmp-devel \
    automake \
    autoconf \
    libtool \
    make \
    gcc \
    socat \
    glibc-headers \
    openssl-devel \
    bzip2 \
    libseccomp-devel \
    gdb

RUN git clone https://github.com/stefanberger/libtpms.git \
    && cd libtpms \
    && ./autogen.sh --with-tpm2 --with-openssl --prefix=/usr \
    && ./configure --prefix=/usr --with-openssl --with-tpm2 --enable-debug \
    && make \
    && make install

RUN git clone https://github.com/stefanberger/swtpm.git \
    && cd swtpm \
    && git checkout v0.2.0 \
    && ./autogen.sh  \
    && ./configure --with-openssl --prefix=/usr --enable-debug \
    && make \
    && make install

RUN mkdir /tpm
WORKDIR /tpm
RUN mkdir tpm-state
ADD swtpm-setup.conf swtpm-setup.conf
ADD swtpm-localca.conf swtpm-localca.conf
ADD swtpm-localca.options swtpm-localca.options

ENTRYPOINT \
  cd /tpm \
    && \
  swtpm_setup.sh --tpm2 --tpm-state tpm-state --create-ek-cert \
    --create-platform-cert --overwrite --config swtpm-setup.conf \
    && \
  gdb -ex run --args swtpm socket --tpmstate dir=tpm-state --tpm2 \
    --flags not-need-init \
    --ctrl type=tcp,port=2321,bindaddr=0.0.0.0 \
    --server type=tcp,port=2322,bindaddr=0.0.0.0 \
    --runas `id -un` --log file=log,level=11,truncate
