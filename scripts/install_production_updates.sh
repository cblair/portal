#!/bin/bash

bundle install 
rake assets:precompile RAILS_ENV="production" 
rake db:migrate RAILS_ENV="production" 
RAILS_ENV=production script/delayed_job restart
