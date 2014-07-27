# CacheRecovery

Recover lost web content via google's web cache.

## Installation

Add this line to your application's Gemfile:

    gem 'cache-recovery'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install cache-recovery

## Usage

run following command:

```
cache-recovery <domain-to-recovery>
```


To recovery ``thehousenews.com`` articles, run following command

```
cache-recovery thehousenews.com
```

The app will then begin recovery. A file ``output/recovery.json`` contains the
state of recovery (which is used to resume recovery). Any recovered files is
save as ``output/<md5-url-of-file>``.

## Development

1. Checkout this project.
2. In the project folder, type ``bundle install`` to install dependencies.
3. Run ``./bin/cache-recovery thehousenews.com`` to test run the command.

## Known Issue

It seems after a while google will detect unusual usage and asked for Captcha.

## Contributing

1. Fork it ( https://github.com/[my-github-username]/cache-recovery/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
