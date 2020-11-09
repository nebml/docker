FROM ubuntu:18.04

ENV DEBIAN_FRONTEND noninteractive

ARG GITHUB_TOKEN
ARG NODE_VERSION=12.18.3
ARG LLVM=10
ENV NODE_VERSION $NODE_VERSION
ENV YARN_VERSION 1.13.0

# default uid
ARG host_uid=1000 
ENV env_host_uid=$host_uid
# default gid
ARG host_gid=1000 
ENV env_host_gid=$host_gid
RUN echo $env_host_gid
RUN echo $env_host_uid

# use "latest" or "next" version for Theia packages
ARG version=latest

# Optionally build a striped Theia application with no map file or .ts sources.
# Makes image ~150MB smaller when enabled
ARG strip=true
ENV strip=$strip

#Common deps
RUN apt-get update && \
    apt-get -y install build-essential \
                       curl \
                       nano \
                       vim \
                       git \
                       gpg \
                       python \
                       python3 \
                       wget \
                       xz-utils && \
    rm -rf /var/lib/apt/lists/*

#Install node and yarn
#From: https://github.com/nodejs/docker-node/blob/6b8d86d6ad59e0d1e7a94cec2e909cad137a028f/8/Dockerfile

# gpg keys listed at https://github.com/nodejs/node#release-keys
RUN set -ex \
    && for key in \
    4ED778F539E3634C779C87C6D7062848A1AB005C \
    B9E2F5981AA6E0CD28160D9FF13993A75599653C \
    94AE36675C464D64BAFA68DD7434390BDBE9B9C5 \
    B9AE9905FFD7803F25714661B63B535A4C206CA9 \
    77984A986EBC2AA786BC0F66B01FBB92821C587A \
    71DCFD284A79C3B38668286BC97EC7A07EDE3FC1 \
    FD3A5288F042B6850C66B31F09FE44734EB7990E \
    8FCCA13FEF1D0C2E91008E09770F7A9A5AE15600 \
    C4F0DFFF4E8C1A8236409D08E73BC641CC11F4C8 \
    DD8F2338BAE7501E3DD5AC78C273792F7D83545D \
    A48C2BEE680E841632CD4E44F07496B3EB3C1762 \
    ; do \
    gpg --batch --keyserver ipv4.pool.sks-keyservers.net --recv-keys "$key" || \
    gpg --batch --keyserver pool.sks-keyservers.net --recv-keys "$key" || \
    gpg --batch --keyserver pgp.mit.edu --recv-keys "$key" || \
    gpg --batch --keyserver keyserver.pgp.com --recv-keys "$key" || \
    gpg --batch --keyserver ha.pool.sks-keyservers.net --recv-keys "$key" ; \
    done

RUN ARCH= && dpkgArch="$(dpkg --print-architecture)" \
    && case "${dpkgArch##*-}" in \
    amd64) ARCH='x64';; \
    ppc64el) ARCH='ppc64le';; \
    s390x) ARCH='s390x';; \
    arm64) ARCH='arm64';; \
    armhf) ARCH='armv7l';; \
    i386) ARCH='x86';; \
    *) echo "unsupported architecture"; exit 1 ;; \
    esac \
    && curl -SLO "https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-linux-$ARCH.tar.xz" \
    && curl -SLO --compressed "https://nodejs.org/dist/v$NODE_VERSION/SHASUMS256.txt.asc" \
    && gpg --batch --decrypt --output SHASUMS256.txt SHASUMS256.txt.asc \
    && grep " node-v$NODE_VERSION-linux-$ARCH.tar.xz\$" SHASUMS256.txt | sha256sum -c - \
    && tar -xJf "node-v$NODE_VERSION-linux-$ARCH.tar.xz" -C /usr/local --strip-components=1 --no-same-owner \
    && rm "node-v$NODE_VERSION-linux-$ARCH.tar.xz" SHASUMS256.txt.asc SHASUMS256.txt \
    && ln -s /usr/local/bin/node /usr/local/bin/nodejs


RUN set -ex \
    && for key in \
    6A010C5166006599AA17F08146C2130DFD2497F5 \
    ; do \
    gpg --batch --keyserver ipv4.pool.sks-keyservers.net --recv-keys "$key" || \
    gpg --batch --keyserver pool.sks-keyservers.net --recv-keys "$key" || \
    gpg --batch --keyserver pgp.mit.edu --recv-keys "$key" || \
    gpg --batch --keyserver keyserver.pgp.com --recv-keys "$key" || \
    gpg --batch --keyserver ha.pool.sks-keyservers.net --recv-keys "$key" ; \
    done \
    && curl -fSLO --compressed "https://yarnpkg.com/downloads/$YARN_VERSION/yarn-v$YARN_VERSION.tar.gz" \
    && curl -fSLO --compressed "https://yarnpkg.com/downloads/$YARN_VERSION/yarn-v$YARN_VERSION.tar.gz.asc" \
    && gpg --batch --verify yarn-v$YARN_VERSION.tar.gz.asc yarn-v$YARN_VERSION.tar.gz \
    && mkdir -p /opt/yarn \
    && tar -xzf yarn-v$YARN_VERSION.tar.gz -C /opt/yarn --strip-components=1 \
    && ln -s /opt/yarn/bin/yarn /usr/local/bin/yarn \
    && ln -s /opt/yarn/bin/yarn /usr/local/bin/yarnpkg \
    && rm yarn-v$YARN_VERSION.tar.gz.asc yarn-v$YARN_VERSION.tar.gz

#C/C++ Developer tools

# install clangd and clang-tidy from the public LLVM PPA (nightly build / development version)
# and also the GDB debugger from the Ubuntu repos
RUN wget -O - https://apt.llvm.org/llvm-snapshot.gpg.key | apt-key add - && \
    echo "deb http://apt.llvm.org/bionic/ llvm-toolchain-bionic main" > /etc/apt/sources.list.d/llvm.list && \
    apt-get update && \
    apt-get install -y \
                       clang-tools-$LLVM \
                       clangd-$LLVM \
                       clang-tidy-$LLVM \
                       clang-format-$LLVM \
					   libc++-$LLVM-dev \
					   libc++abi-$LLVM-dev \
					   lldb-$LLVM \
                       lld-$LLVM \
                       gcc-multilib \
                       g++-multilib \
                       gdb && \
    ln -s /usr/bin/llvm-nm-$LLVM /usr/bin/llvm-nm && \
	ln -s /usr/bin/llvm-ar-$LLVM /usr/bin/llvm-ar && \
    ln -s /usr/bin/lld-$LLVM /usr/bin/lld && \
    ln -s /usr/bin/clang-$LLVM /usr/bin/clang && \
    ln -s /usr/bin/clang++-$LLVM /usr/bin/clang++ && \
    ln -s /usr/bin/clang-cl-$LLVM /usr/bin/clang-cl && \
    ln -s /usr/bin/clang-check-$LLVM /usr/bin/clang-check && \
    ln -s /usr/bin/clang-format-$LLVM /usr/bin/clang-format && \
    ln -s /usr/bin/clang-cpp-$LLVM /usr/bin/clang-cpp && \
    ln -s /usr/bin/clang-tidy-$LLVM /usr/bin/clang-tidy && \
    ln -s /usr/bin/clangd-$LLVM /usr/bin/clangd

# Install latest stable CMake
ARG CMAKE_VERSION=3.18.1


RUN wget "https://github.com/Kitware/CMake/releases/download/v$CMAKE_VERSION/cmake-$CMAKE_VERSION-Linux-x86_64.sh" && \
    chmod a+x cmake-$CMAKE_VERSION-Linux-x86_64.sh && \
    ./cmake-$CMAKE_VERSION-Linux-x86_64.sh --prefix=/usr/ --skip-license && \
    rm cmake-$CMAKE_VERSION-Linux-x86_64.sh

## User account
# https://medium.com/@nielssj/docker-volumes-and-file-system-permissions-772c1aee23ca

# better approach: change to this: https://stackoverflow.com/questions/44683119/dockerfile-replicate-the-host-user-uid-and-gid-to-the-image

RUN addgroup --gid ${env_host_gid} theiaide
RUN adduser --disabled-password --gecos "" --uid ${env_host_uid} --ingroup theiaide theia  
RUN usermod -a -G theiaide theia
# RUN useradd  -a -G theia theia
RUN cat /etc/group | grep theia
RUN cat /etc/passwd | grep theia

RUN chmod g+rw /home && \
    mkdir -p /home/project && \
    chown -R theia:theiaide /home/theia && \
    mkdir -p /home/theia/theia && \
    chown -R theia:theiaide /home/theia/theia && \
    chown -R theia:theiaide /home/project && \
    chmod -R 775 /home/project && \
    chmod g+s /home/project;

COPY .bashrc.append /home/theia/.bashrc.append
RUN cat /home/theia/.bashrc.append >> /home/theia/.bashrc

# Theia application

USER theia
WORKDIR /home/theia
ADD $version.package.json ./package.json

RUN git config --global user.email "" 
RUN git config --global user.name "theia"
RUN git config --global core.filemode false

RUN if [ "$strip" = "true" ]; then \
yarn --pure-lockfile && \
    NODE_OPTIONS="--max_old_space_size=4096" yarn theia build && \
    yarn theia download:plugins && \
    yarn --production && \
    yarn autoclean --init && \
    echo *.ts >> .yarnclean && \
    echo *.ts.map >> .yarnclean && \
    echo *.spec.* >> .yarnclean && \
    yarn autoclean --force && \
    yarn cache clean \
;else \
yarn --cache-folder ./ycache && rm -rf ./ycache && \
     NODE_OPTIONS="--max_old_space_size=4096" yarn theia build && yarn theia download:plugins \
;fi

# install cp2k
USER root
#RUN wget https://github.com/cp2k/cp2k/releases/download/v7.1.0/cp2k-7.1-Linux-x86_64.ssmp
#RUN wget https://github.com/cp2k/cp2k/releases/download/v6.1.0/cp2k-6.1-Linux-x86_64.sopt
#RUN wget https://github.com/cp2k/cp2k/releases/download/v6.1.0/cp2k_shell-6.1-Linux-x86_64.sopt
#COPY cp2k-6.1-Linux-x86_64.sopt /opt/cp2k/cp2k
#COPY cp2k_shell-6.1-Linux-x86_64.sopt /opt/cp2k/cp2k_shell
#RUN chmod +x /opt/cp2k/cp2k
#RUN chmod +x /opt/cp2k/cp2k_shell
#ENV PATH="/opt/cp2k:${PATH}"

# build cp2k
# require recent build due to: https://groups.google.com/forum/?nomobile=true#!topic/cp2k/Ltb1fj8woA0
# require some packages due to locale: https://github.com/aiidateam/aiida-cp2k/issues/58
RUN apt-get update && \
    apt-get -y install libopenblas-dev gfortran \
      python3-dev           \
      python3-setuptools     \
      python3-wheel          \
      python3-pip            \
      git                    \
      locales

ENV LC_ALL=C
RUN locale-gen "en_US.UTF-8"
RUN update-locale LANG=en_US.UTF-8 LC_CTYPE=en_US.UTF-8

ENV DEBIAN_FRONTEND="teletype" \
    LANG="en_US.UTF-8" \
    LANGUAGE="en_US:en" \
    LC_ALL="en_US.UTF-8"

RUN mkdir -p /opt/cp2k
WORKDIR /opt/cp2k
RUN git clone --recursive --branch master --depth 1 https://github.com/cp2k/cp2k.git ./
WORKDIR /opt/cp2k/tools/toolchain
RUN ./install_cp2k_toolchain.sh --mpi-mode=no --with-libxc=install --with-fftw=install --with-cmake=system --with-libint=install --with-acml=no --with-mkl=no --with-openblas=system --with-scalapack=no --with-elpa=no --with-sirius=no --with-gsl=no --with-libvdwxc=no --with-spglib --with-hdf5=no --with-spfft=no
RUN cp /opt/cp2k/tools/toolchain/install/arch/* /opt/cp2k/arch/
WORKDIR /opt/cp2k
RUN /bin/bash /opt/cp2k/tools/toolchain/install/setup \
    && make -j 3 ARCH=local VERSION="ssmp"
ENV PATH="/opt/cp2k/exe/local:${PATH}"    

RUN apt-get update && \
    apt-get -y install build-essential \
                       python3-pip
RUN pip3 install scikit-learn 
RUn pip3 install numpy scipy matplotlib ase pylint

RUN apt-get update \
    && apt-get install -y python3-dev python3-pip \
    && pip3 install --upgrade pip --user \
    && pip3 install python-language-server flake8 autopep8 \
    && apt-get clean \
    && apt-get auto-remove -y \
    && rm -rf /var/cache/apt/* \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /tmp/*

RUN apt-get update \
    && apt-get install -y python3-tk

WORKDIR /opt/vmd
COPY vmd-1.9.3.bin.LINUXAMD64-CUDA8-OptiX4-OSPRay111p1.opengl.tar.gz /opt/vmd/vmd-1.9.3.tar.gz
RUN tar -xvf vmd-1.9.3.tar.gz
WORKDIR /opt/vmd/vmd-1.9.3
ENV VMDINSTALLBINDIR=/opt/vmd/install/bin
ENV VMDINSTALLLIBRARYDIR=/opt/vmd/install/lib
RUN ./configure LINUXAMD64 OPENGL
WORKDIR /opt/vmd/vmd-1.9.3/src
RUN make install
ENV PATH="/opt/vmd/install/bin:${PATH}" 

RUN apt-get update \
    && apt-get install -y libgl-dev freeglut3-dev libxinerama-dev

# install lammps with python
WORKDIR /opt/lammps
RUN git clone --branch stable_3Mar2020 --depth 1 https://github.com/lammps/lammps.git ./
RUN mkdir build 
WORKDIR /opt/lammps/build
RUN cmake -C ../cmake/presets/minimal.cmake -D BUILD_LIB=yes -D BUILD_SHARED_LIBS=yes \
      -D LAMMPS_EXCEPTIONS=yes -D PKG_PYTHON=yes -D CMAKE_INSTALL_PREFIX=/usr -D BUILD_MPI=no -D BUILD_OMP=yes  ../cmake
RUN cmake --build . -j 2
RUN cmake --install .
ENV LAMMPS_POTENTIALS=/usr/share/lammps/potentials

USER theia
WORKDIR /home/theia

EXPOSE 3000
ENV SHELL=/bin/bash \
    THEIA_DEFAULT_PLUGINS=local-dir:/home/theia/plugins

ENTRYPOINT [ "node", "/home/theia/src-gen/backend/main.js", "/home/project", "--hostname=0.0.0.0" ]