# syntax=docker/dockerfile:1.3
FROM python:3.10-slim as base
WORKDIR /app

FROM base as builder
RUN apt-get update  \
    && apt-get install -y git  \
    && rm -rf /var/lib/apt/lists/*

ENV PIP_DISABLE_PIP_VERSION_CHECK=1 \
    POETRY_VERSION=1.3.2

RUN --mount=type=cache,target=/root/.cache/pip \
    pip install poetry==$POETRY_VERSION
RUN python -m venv /venv

COPY pyproject.toml poetry.lock ./
RUN --mount=type=cache,target=/root/.cache/pip \
    poetry export -f requirements.txt | /venv/bin/pip install -r /dev/stdin

COPY . .
RUN sed -i "s/\(COMMIT_HASH *= *\).*/\1'$(git rev-parse HEAD)'/" tgpy/version.py

FROM base as runner
COPY --from=builder /venv /venv
ENV PATH="/venv/bin:$PATH"

COPY --from=builder /app/tgpy tgpy

ENV TGPY_DATA=/data
VOLUME /data

ENTRYPOINT ["/venv/bin/python", "-m", "tgpy"]
