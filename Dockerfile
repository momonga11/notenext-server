FROM ruby:2.7.2
RUN apt-get update -qq \
  && apt-get install -y --no-install-recommends default-mysql-client \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY Gemfile /app/Gemfile
COPY Gemfile.lock /app/Gemfile.lock
ARG env
RUN if [ "${env}" = "production" ]; then \
  bundle install --without test development; \
  else \
  bundle install; \
  fi
COPY . /app

COPY entrypoint.sh /usr/bin/
RUN chmod +x /usr/bin/entrypoint.sh
ENTRYPOINT ["entrypoint.sh"]

CMD ["rails", "server", "-b", "0.0.0.0"]
