#!/bin/bash

S3_PUBLISH_BUCKET="semaphore-test-app"

file_version=$1
stack_name=$2

filename="ecom-$file_version.zip"

cache restore gems-$SEMAPHORE_GIT_BRANCH-$(checksum Gemfile.lock),gems-develop,gems-master
sem-version ruby 2.6.7
bundle install --local --deployment --jobs=2 --path=vendor/bundle
sem-service start postgres 10.6
RAILS_ENV=production bundle exec rake db:create db:structure:load
RAILS_ENV=production bundle exec rake assets:precompile

zip $file_name -9 -y -r . -x "spec/*" "tmp/*" "vendor/bundle/*" ".git/*"

aws s3 --profile sem-ci-service cp $file_name s3://$S3_PUBLISH_BUCKET/testing/$file_name

parameters=`aws cloudformation describe-stacks --profile sem-ci-service --stack-name $stack_name | jq -r '.Stacks[].Parameters[].ParameterKey | select( . != "BundleKey")'`

echo "[" > params.json
for parameter in $parameters; do
  echo "{\"ParameterKey\": \"$parameter\", \"UsePreviousValue\": true}," >> params.json
done
echo "{\"ParameterKey\": \"BundleKey\", \"ParameterValue\": \"testing/$file_name\"}" >> params.json
echo "]" >> params.json

aws cloudformation update-stack --profile sem-ci-service --stack-name $stack_name --use-previous-template --parameters file://params.json
