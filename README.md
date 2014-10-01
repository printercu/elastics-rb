# elastics
[![Gem Version](https://badge.fury.io/rb/elastics.svg)](http://badge.fury.io/rb/elastics)
[![Code Climate](https://codeclimate.com/github/printercu/elastics-rb/badges/gpa.svg)](https://codeclimate.com/github/printercu/elastics-rb)

Simple ElasticSearch client.

Fast and thread-safe [httpclient](https://github.com/nahi/httpclient) under the hood.

## Install

```ruby
# Gemfile
gem 'elastics', github: 'printercu/elastics-rb'
```

## Usage

### Plain

```ruby
# initialize client with
client = Elastics::Client.new(options)
# options is hash with
#   :host
#   :port
#   :index  - (default index)
#   :type   - (default type)

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
    host: 10.0.0.1
    port: 1234

    index: app
    # or
    index_prefix: app_
```

#### Mappings & index settings
Mappings & index settings `.yml` files are placed in
`db/elastics/mappings` & `db/elastics/indices`.
For now this files are not related to models and only used by rake tasks.

- `rake elastics:create` (or `Elastics::Tasks.create_indices`)
creates index with settings for each file from `indices` folder.
For single index it only processes file with index name.
For multiple indices each index name is `#{index_prefix}#{file.basename}`

- `rake elastics:migrate` (or `Elastics::Tasks.migrate`)
puts mappings from `mappings` folder.

## License
MIT
