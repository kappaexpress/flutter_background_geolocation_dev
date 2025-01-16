FROM cimg/android:2025.01.1

RUN wget https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.27.1-stable.tar.xz && \
    tar xf flutter_linux_3.27.1-stable.tar.xz -C ~/

ENV PATH="$PATH:/home/circleci/flutter/bin"
