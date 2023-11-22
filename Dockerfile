FROM --platform=amd64 ubuntu:20.04 AS codeql_base
LABEL maintainer="CodeQL Agent Community" 
# Please note that we are a non-profit organization and are not the official team of CodeQL. Please follow the license of CodeQL CLI.

# tzdata install needs to be non-interactive
ENV DEBIAN_FRONTEND=noninteractive

# Set up the enviroment
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
    	software-properties-common \
    	vim \
    	curl \
    	wget \
    	git \
    	jq \
    	build-essential \
    	unzip \
    	apt-transport-https \
        python3.8 \
    	python3-venv \
    	python3-pip \
    	python3-setuptools \
        python3-dev \
    	gnupg \
    	g++ \
    	make \
    	gcc \
		nodejs \
    	apt-utils \
        rsync \
    	file \
        dos2unix \
        default-jdk \
		openjdk-8-jdk \
		maven \
    	gettext && \
        apt-get clean && \
        ln -sf /usr/bin/python3.8 /usr/bin/python && \
        ln -sf /usr/bin/pip3 /usr/bin/pip 

# Install Gradle
ENV GRADLE_VERSION=7.4.2
RUN wget https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip -P /tmp
RUN unzip -d /opt/gradle /tmp/gradle-${GRADLE_VERSION}-bin.zip
RUN ln -s /opt/gradle/gradle-${GRADLE_VERSION} /opt/gradle/latest

# Install Linguist
RUN apt-get install -y cmake pkg-config libicu-dev zlib1g-dev libcurl4-openssl-dev libssl-dev ruby-dev
RUN gem install github-linguist


# Install Golang
RUN wget -q -O - https://raw.githubusercontent.com/canha/golang-tools-install-script/master/goinstall.sh | bash

# Install latest codeQL
ENV CODEQL_HOME /root/codeql-home

# Get CodeQL verion
RUN curl --silent "https://api.github.com/repos/github/codeql-cli-binaries/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/' > /tmp/codeql_version

# Get CodeQL Bundle version
RUN curl --silent "https://api.github.com/repos/github/codeql-action/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/' > /tmp/codeql_bundle_version

# Make the codeql folder
RUN mkdir -p ${CODEQL_HOME} \
    /opt/codeql

# Downdload and extract CodeQL Bundle
RUN CODEQL_BUNDLE_VERSION=$(cat /tmp/codeql_bundle_version) && \
    wget -q https://github.com/github/codeql-action/releases/download/${CODEQL_BUNDLE_VERSION}/codeql-bundle-linux64.tar.gz -O /tmp/codeql_linux.tar.gz && \
    tar -xf /tmp/codeql_linux.tar.gz -C ${CODEQL_HOME} && \
    rm /tmp/codeql_linux.tar.gz

ENV PATH="$PATH:${CODEQL_HOME}/codeql:/opt/gradle/gradle-${GRADLE_VERSION}/bin:/root/go/bin:/root/.go/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
COPY scripts /root/scripts

# Execute analyze script
WORKDIR /root/
ENTRYPOINT ["/root/scripts/analyze.sh"]
