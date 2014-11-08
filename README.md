# elastics
[![Gem Version](https://badge.fury.io/rb/elastics.svg)](http://badge.fury.io/rb/elastics)
[![Code Climate](https://codeclimate.com/github/printercu/elastics-rb/badges/gpa.svg)](https://codeclimate.com/github/printercu/elastics-rb)
[![Build Status](https://travis-ci.org/printercu/elastics-rb.svg)](https://travis-ci.org/printercu/elastics-rb)

Simple ElasticSearch client.
- basic API only
- transparent aliases management & zero-downtime migrations
- capistrano integration
- auto refresh in tests

Fast and thread-safe [httpclient](https://github.com/nahi/httpclient) is under the hood.

## Install

```ruby
# Gemfile
gem 'elastics', '~> 0.2' # use version from the badge above
# or
gem 'elastics', github: 'printercu/elastics-rb'
```

## Usage

### Plain

```ruby
# initialize client with
client = Elastics::Client.new(options)
# options is hash with
#   :host   - hostname with port or array with hosts (default 127.0.0.1:9200)
#   :index  - (default index)
#   :type   - (default type)
#   :connect_timeout    - timeout to mark the host as dead in cluster-mode (default 10)
#   :resurrect_timeout  - timeout to mark dead host as alive in cluster-mode (default 10)

# basic request
client.request(options)
# options is hash with
#   :method - default :get
#   :data   - post body
#   :query  - query string params
#   :index, :type, :id - query path params to override defaults

# method shortcuts for #put, #post #delete
client.delete(params)

# getter/setter shortcuts
client.set(id, data)
client.get(id)
client.get(params) # as usual

# other shortcuts (set method & id)
client.put_mapping(index: index, type: type, data: mapping)
client.search(params)
client.index(params) # PUT if :id is set, otherwise POST

# utils
client.index_exists?(name)
```

When using cluster-mode you should also install `gem 'thread_safe'`.

### ActiveRecord

```ruby
class User < ActiveRecord::Base
  indexed_with_elastics
  # optionally pass :index, :type

  # optionally override to export only selected fields
  def to_elastics
    serializable_hash(only: [:id, :first_name, :last_name])
  end
end

User.search_elastics(data)
# Returns Elastics::ActiveRecord::SearchResult object with some useful methods
```

#### Configure
```yml
# database.yml
development:
  elastics:
    # use single index (app_dev/users, app_dev/documents)
    index: app_dev

    # use index per type (app_dev_users/users, app_dev_documents/documents)
    index_prefix: app_dev_

production:
  elastics:
    host: 10.0.0.1:1234
    # or
    host:
      - 10.0.0.1:1234
      - 10.0.0.2:1234

    index: app
    # or
    index_prefix: app_
```

#### Create mappings & import data
```
$ rake elastics:migrate elastics:reindex
```

#### Mappings & index settings
Mappings & index settings `.yml` files are placed in
`db/elastics/mappings` & `db/elastics/indices`.
For now this files are not related to models and only used by rake tasks.

### Index management
When index is created elastics transparently manages aliases for it.
Instead of creating `index1` it creates `index1-v0` and create `index1` alias for it.
When you perform normal migration, mappings are applied to the current version.
Later when you perform full migration `index1-v1` is created, after reindexing
aliases are changed and `index-v0` is droped.

Versions of indices are stored in ElasticSearch in `.elastics` index.

### Rake tasks
All rake tasks except `purge` accepts list of indices to process
(`rake elastics:create[index1,index2]`).
Also you can specify index version like this `rake elastics:migrate version=next`.
Version can be set to `next` or `current` (default).

Rake tasks are just frontend for `Elastics::Tasks`'s methods.
For complex migrations, when you need partially reindex data,
you may want to write custom scripts using this methods.

- `rake elastics:create` (`.create_indices`)
creates index with settings for each file from `indices` folder.

- `rake elastics:migrate` (`.migrate`)
puts mappings from `mappings` folder.

- `rake elastics:migrate full=true` (`.migrate!`)
performs full migration.

- `rake elastics:reindex` (`.reindex`)
reindexes data.

#### Using without Rails
You need to setup `Elastics::Tasks` yourself. This can be done in `environment` or
`db:load_config` rake tasks.

```ruby
task :environment do
  Elastics::Tasks.base_paths = '/path/to/your/elastics/folder'
  Elastics::Tasks.config = your_configuration
end
```

Also you need to install `active_support` & require
`active_support/core_ext/object` to be able to run tasks.

### Auto refresh index
Add `Elastics::AutoRefresh.enable!` to your test helper,
this will run `POST /:index/_refresh` request after each modifying request.
You can also use it for a block or skip auto refresh after it was enabled:

```ruby
# enable test mode in rspec's around filter
around { |ex| Elastics::AutoRefresh.enable! { ex.run } }

# disable auto refresh for block & perform single refresh
# assume test mode is enabled here
Elastics::AutoRefresh.disable! { Model.reindex_elastics }
Model.refresh_elastics
```

### Use with capistrano
Add following lines to your `deploy.rb` and all rake tasks will be available in cap.

```ruby
role :elastics, '%HOSTNAME%', primary: true

require 'elastics/capistrano'
```

Indices & rake options can be passed like this:
```
cap --dry-run elastics:migrate INDICES=index1,index2 ES_OPTIONS='full=true no_drop=true'
```

## Other versions
[elastics for node.js](https://github.com/printercu/elastics)

## License
MIT
