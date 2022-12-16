FROM python:3.10 AS translations

RUN pip install babel==2.11.0 pytz==2022.6  # Keep in sync with poetry.lock

WORKDIR /usr/src/app
COPY po po
RUN mkdir scripts
COPY scripts/update_translations.sh scripts/

RUN scripts/update_translations.sh


FROM python:3.10

# Install Calibre from Ubuntu distro
RUN apt-get update && \
    apt-get install -y --no-install-recommends calibre wv && \
    rm -rf /var/lib/apt/lists/*

# Install Poetry
RUN curl -sSL https://install.python-poetry.org | python3 - && /root/.local/bin/poetry config virtualenvs.create false

# Set up app
RUN mkdir -p /usr/src/app
WORKDIR /usr/src/app
COPY taguette taguette
COPY pyproject.toml poetry.lock README.rst tests.py ./
RUN /root/.local/bin/poetry install --no-interaction --no-dev -E postgres && rm -rf /root/.cache

# Copy translation from other stage
COPY --from=translations /usr/src/app/taguette/l10n taguette/l10n

VOLUME /data
ENV HOME=/data
EXPOSE 7465
ENTRYPOINT ["taguette", "--no-browser", "--bind=0.0.0.0"]
CMD []
