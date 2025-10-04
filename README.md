# N2Y

This is a web app written in [Crystal](https://crystal-lang.org) for
importing bank data into [YNAB](https://www.youneedabudget.com/). It
supports importing from [banks supported by
Nordigen](https://nordigen.com/en/coverage/).

## Build requirements

* [Crystal Language](https://crystal-lang.org/) compiler
* [Task](https://taskfile.dev/) (optional but recommended)

## Compiling

To quickly compile the server for testing/development, run:

``` shell
$ shards build
```

The same can be accomplished with `task build`, or just `task`. The
[taskfile](./Taskfile.dist.yml) contains other useful task:

* `task spec`: Run spec tests. Add `-- <file>` to run specific spec
  file.
* `task dist`: Build release binary into `dist` along with auxiliary
  files needed (CSS, JavaScript, images, etc).

## Installation

Create an `.env` file by copying `.env.example` and filling in the
relevant values.

To create Google OAuth credentials, go to [Google Cloud
Console](https://console.cloud.google.com) and create a project for
the app. Visit "Credentials" and create an OAuth client ID. The
`/auth/callback` URL of your N2Y instance should be added to
"Authorized redirect URIs", and the "People API" should be enabled for
the project.

Create credentials for Nordigen (recently acquired by GoCardless) by going to
https://manage.gocardless.com/sign-in and click on the link next to
"Looking for Bank Account Data (formerly Nordigen)?". Once logged in,
go to Project > User secrets and create a new secret_id/secret pair,
and add them to the `.env` file.

Finally, create OAuth credentials for YNAB by logging into your account, go
to Account Settings > Developer Settings and adding a new OAuth
application. As for Google, `auth/ynab/callback` should be added to
Redirect URI(s), and the client_id/secret should be added to the
`.env` file.

You can also add `HONEYBADGER_API_KEY` to the `.env` file to track errors in
[Honeybadger.io](https://www.honeybadger.io/)

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
