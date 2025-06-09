# Stage 1: Use Astral UV image to manage Python dependencies efficiently
FROM ghcr.io/astral-sh/uv:0.7.10 AS uv

# Stage 2: Builder stage on AWS Lambda Python 3.13 base image
FROM public.ecr.aws/lambda/python:3.12 AS builder

ENV UV_COMPILE_BYTECODE=1
ENV UV_NO_INSTALLER_METADATA=1
ENV UV_LINK_MODE=copy

# Install dependencies with uv, mounting necessary files and cache
RUN --mount=from=uv,source=/uv,target=/bin/uv \
    --mount=type=cache,target=/root/.cache/uv \
    --mount=type=bind,source=uv.lock,target=uv.lock \
    --mount=type=bind,source=pyproject.toml,target=pyproject.toml \
    uv export --frozen --no-emit-workspace --no-dev --no-editable -o requirements.txt && \
    uv pip install -r requirements.txt --target "${LAMBDA_TASK_ROOT}"

# Stage 3: Final runtime image based on Lambda Python 3.13
FROM public.ecr.aws/lambda/python:3.13

# Copy installed dependencies from builder stage
COPY --from=builder ${LAMBDA_TASK_ROOT} ${LAMBDA_TASK_ROOT}

# Copy lambda logic
COPY ../../etl ${LAMBDA_TASK_ROOT}/etl

CMD ["etl.lambda.ingestion.lambda_handler"]
