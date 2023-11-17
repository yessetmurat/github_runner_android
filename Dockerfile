FROM gradle:7-jdk11
LABEL org.opencontainers.image.source=https://github.com/yessetmurat/github_runner_android

# Arguments with defaults if not provided
ARG RUNNER_VERSION
ARG RUNNER_ARCH
ARG ANDROID_SDK_VERSION=9477386

# Setting environment variables
ENV ANDROID_SDK_ROOT=/opt/android-sdk \
    PATH=${PATH}:${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin:${ANDROID_SDK_ROOT}/cmdline-tools/tools/bin:${ANDROID_SDK_ROOT}/platform-tools:${ANDROID_SDK_ROOT}/emulator \
    DEBIAN_FRONTEND=noninteractive

# Installing necessary packages and cleaning up in one layer
RUN apt-get update -y && apt-get install -y --no-install-recommends \
    curl unzip git build-essential libssl-dev libffi-dev python3 python3-venv python3-dev python3-pip jq gh && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Setting permissions
RUN chown -R gradle:gradle /opt

# Switching to user 'gradle'
USER gradle

# Installing Android SDK
RUN mkdir -p ${ANDROID_SDK_ROOT}/cmdline-tools && \
    curl -O -L https://dl.google.com/android/repository/commandlinetools-linux-${ANDROID_SDK_VERSION}_latest.zip && \
    unzip commandlinetools*linux*.zip -d ${ANDROID_SDK_ROOT}/cmdline-tools && \
    mv ${ANDROID_SDK_ROOT}/cmdline-tools/cmdline-tools ${ANDROID_SDK_ROOT}/cmdline-tools/tools && \
    rm commandlinetools*linux*.zip

# Accepting licenses and installing specific SDK build tools
RUN yes | sdkmanager --licenses && \
    sdkmanager "build-tools;30.0.2"

# Installing GitHub Actions Runner
RUN mkdir -p /home/gradle/actions-runner && \
    curl -O -L https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-${RUNNER_ARCH}-${RUNNER_VERSION}.tar.gz && \
    tar -xzf actions-runner-linux-${RUNNER_ARCH}-${RUNNER_VERSION}.tar.gz -C /home/gradle/actions-runner && \
    rm actions-runner*.tar.gz

# Switching back to root to install runner dependencies
USER root
RUN /home/gradle/actions-runner/bin/installdependencies.sh

# Switching back to gradle user
USER gradle

# Copying start script and setting entrypoint
COPY start.sh start.sh
RUN chmod +x start.sh
ENTRYPOINT ["./start.sh"]
