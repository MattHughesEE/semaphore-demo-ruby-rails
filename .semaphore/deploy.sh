#!/bin/bash

S3_PUBLISH_BUCKET="semaphore-test-app"

file_version=$1
stack_name=$2

filename="ecom-$file_version.zip"

cache restore gems-$SEMAPHORE_GIT_BRANCH-$(checksum Gemfile.lock),gems-develop,gems-master
bundle install --local --deployment --jobs=2 --path=vendor/bundle
sem-service start postgres 10.6
RAILS_ENV=production bundle exec rake db:create db:structure:load
SECRET_KEY_BASE=`bin/rake secret` bin/rake assets:precompile
RAILS_ENV=production bundle exec rake assets:precompile
