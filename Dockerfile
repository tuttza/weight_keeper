FROM ruby:latest

RUN apt-get update -qq && apt-get install -y build-essential sqlite 

WORKDIR /usr/src/app

COPY . /usr/src/app/

ENV DOCKER_VOLUME_PATH "/app/data"

RUN bundle install -j 8

ENTRYPOINT ["ruby", "./bin/wk"]
