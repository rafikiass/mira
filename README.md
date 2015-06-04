#MIRA - Tufts Hydra administration application

[![Build Status](https://travis-ci.org/curationexperts/mira.svg?branch=master)](https://travis-ci.org/curationexperts/mira)


## Prerequisites & External Services
> **NOTE:** see [Development Environment Setup]
* MySQL
* Redis
* [ImageMagick](http://www.imagemagick.org/)
* [ffmpeg](http://www.ffmpeg.org/)
* [PhantomJS](https://github.com/teampoltergeist/poltergeist#installing-phantomjs)
* Handle.net installation

## Development Environment Setup

### Install External Dependencies
Install MySQL

```bash
$ brew install mysql
$ mysql.server start
```

Install imagemagick
```bash
$ brew install imagemagick --with-libtiff
```

> **Note:**  If you install ImageMagick using homebrew, you may need to add a switch for libtiff; otherwise,
you may get errors like this when you run the specs:
"Magick::ImageMagickError: no decode delegate for this image format (something.tif)"

Install ffmpeg
```bash
$ brew install ffmpeg --with-libvpx --with-libvorbis
```

Install ghostscript
```bash
$ brew install ghostscript
```

### Clone the repo, install gems, and copy configuration files
```bash
$ git clone https://github.com/curationexperts/mira.git
$ cd mira
$ bundle install
$ rake config:copy
```

Load the database, and seed data:
```bash
$ rake db:setup
```

### Install and start background services
Install & configure hydra-jetty to get a running copy of Fedora and Solr on your system:
```bash
$ rails g hydra:jetty
$ rake jetty:config
$ rake jetty:start
```

Install & start redis.
```bash
$ brew install redis
$ redis-server &
```

Start background workers with resque-pool, then start a pool of workers:
```bash
$ bundle exec resque-pool 
```

*Optional:* start resque-web:
```bash
$ resque-web config/resque_conf.rb
```

### Run the application!
```bash
$ rails s
```
You can now connect to the running application at http://localhost:3000

## Loading Data

### Load some fixture data into your dev environment

Make sure jetty is running, then run the rake task:

```bash
$ rake tufts:fixtures
```

## Self Deposit Setup
### Importing deposit types from a CSV file

The CSV file is expected to have the headers:  
` display_name,deposit_agreement `

```bash
$ rake import:deposit_types['/absolute/path/to/import/file.csv']
```

### Exporting deposit types to a CSV file

The exporter will create a CSV file that contains data from the `deposit_types` table.

```bash
$ rake export:deposit_types['/absolute/path/to/export/dir']
```

You can also export the deposit types data through the UI if you log into the app as an admin user.

## Handle.net

Handles should register automatically when first publishing an object that displays in DL. You can manually publish a handle for an object by running:

```bash
$ rake handle:register[tufts:123]
```

Handles register by sequence number which is stored in the database. You can update the number by issuing the following command in the rails console replacing 100 with the starting value you desire.

```ruby
Sequence.where(scope: 'handle').first_or_initialize.update(value: 100)
```


## Production Configuration Notes

### Configure secret keys
In local development environments, we typically just use the key in the sample files.
To ensure your production installation is secure, it's important to generate a unique secret key.
Don't commit your production secret key to github!

At the server console, generate a new secret key
```bash
$ rake secret
```

Copy the ouput from this command and paste it into the production section of `config/secrets.yml`,
then repeat this process for `config/devise.yml`

## Configure Authentication services
The application includes a basic devise implementation for user management and authentication.  Integrating the
application with your local authentication system is beyone the scope of this document; please consult the
relevant devise documentation.

If you wish to supply a specific format for the text used in displaying user names, please modify the display_name
method on the user model:
```text
# app/models/user.rb

class User < ActiveRecord::Base
...
  def display_name   #update this method to return the string you would like used for the user name stored in fedora objects.
    self.user_key
  end
....
end

```

### Configure Resque-pool worker settings
The sample `resque-pool.yml` file is a good starting place for a simple production configuration;
however, you may want to modify the  to set your environment, queue names, and number of workers.
The wild-card "*" indicates workers should listen on any queue; otherwise, specify the queue name
and the number of dedicated workers to start for that queue.
```text
# config/resque-pool.yml
...
production:
    "*": 5             # start 5 workers that listen for jobs on any queue
    "derivatives": 0   # the queue that handles derivative generation
    "handle": 0        # the queue that processes handle generation requests
    "publish": 0       # the queue that handles publication related actions (publish, revert, purge, etc.)
    "templates": 0     # the queue that handles template updates and imports
```

