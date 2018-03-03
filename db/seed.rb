env = ENV['RACK_ENV'].to_sym

require 'dotenv'
Dotenv.load unless env == :production

require 'sequel'

DB = Sequel.connect(ENV['DATABASE_URL'])

require './lib/transformative/models/site'
require './lib/transformative/models/terminal'

# create test site
first_site = Transformative::Site.find_or_create(
  domain: ENV['SITE_DOMAIN'],
  url: ENV['SITE_URL']
)
first_site.add_terminal(
  type_id: 1, # GitHub
  user: ENV['GITHUB_USER'],
  location: ENV['GITHUB_REPO'],
  key: ENV['GITHUB_ACCESS_TOKEN']
)
