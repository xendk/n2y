# N2Y

This is a web app written in [Crystal](https://crystal-lang.org) for
importing bank data into [YNAB](https://www.youneedabudget.com/). It
supports importing from [banks supported by
Nordigen](https://nordigen.com/en/coverage/).

## Installation

Compile the server and database migration tool:

``` shell
$ shards build
```

Run migrations to create a database:

``` shell
$ ./bin/micrate up
```

Create an `.env` file with Google credentials:

``` 
GOOGLE_CLIENT_ID=something-something.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=GOCSPX--something-xx
```

To create the credentials, go to [Google Cloud
Console](https://console.cloud.google.com) and create a project for
the app. Visit "Credentials" and create an OAuth client ID. The
`/auth/callback` URL of your N2Y instance should be added to
"Authorized redirect URIs", and the "People API" should be enabled for
the project.

You can also add a `SENTRY_DSN` to the `.env` file to track errors in
[Sentry.io](https://sentry.io)

Finally, run the server:

``` shell
$ ./bin/server
```

## Usage

Visit the app (default http://localhost:3000), authenticate using
Google and go from there.

## Development

## Contributing

1. Fork it (<https://github.com/xendk/n2y/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Thomas Fini Hansen](https://github.com/xendk) - creator and maintainer
