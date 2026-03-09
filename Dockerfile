# stage1
FROM --platform=$BUILDPLATFORM python:3.13-slim AS pyenv

ARG POETRY_HOME=/opt/poetry
ARG TARGETARCH

RUN python3 -m venv $POETRY_HOME \
    && $POETRY_HOME/bin/pip install poetry==2.2 poetry-plugin-export

COPY . /root/server/

RUN cd /root/server \
    && if [ "$TARGETARCH" = "amd64" ]; then PIP_PLATFORM="manylinux_2_28_x86_64"; \
       elif [ "$TARGETARCH" = "arm64" ]; then PIP_PLATFORM="manylinux_2_28_aarch64"; \
       else echo "Unsupported target architecture: $TARGETARCH" && exit 1; fi \
    && $POETRY_HOME/bin/poetry export -f requirements.txt --output requirements.txt --without-hashes \
    && $POETRY_HOME/bin/poetry run python -m pip wheel pyaes --wheel-dir /tmp/wheels \
    && $POETRY_HOME/bin/poetry run python -m pip install \
       --platform $PIP_PLATFORM \
       --target /root/site-packages \
       --only-binary=:all: \
       --find-links /tmp/wheels \
       -r requirements.txt

# stage 2
FROM gcr.io/distroless/python3-debian13:nonroot

COPY --from=pyenv /root/site-packages /home/nonroot/.local/lib/python3.13/site-packages
