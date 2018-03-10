# Sitewriter

This is a small Sinatra service that provides publishing endpoints for sites that cannot provide their own.

The first use case is Micropub posting of notes to [my personal site](https://hans.gerwitz.com/) via GitHub.

Essentially, a configured domain has some _endpoints_, which receive content and apply _templates_ which are then sent to a _store_.

Authentication for configuration is provided via IndieAuth.com

## Roadmap

Micropub note entry endpoint

Middleman template for notes

GitHub store for notes

Micropub media endpoint

GitHub store for binaries

Flow configuration: (type + origin + ?) -> entry store + params + template, binary store + params

Logging

*Deploy!*

Parse `syndication` for origin domain

Micropub bookmark-of

Micropub cite

Draft queues

Micropub post

S3 store for binaries

Multipart handling

Template library

Refactor away deprecations (includng backfeed webactions?)

*Share!*

Documentation

Websub hub pinging

Webmentions for POSSE discovery

Webmentions for mentions

Webmentions for person-tag

File implementation report for webmentions

JS referrer sniffer for mentions

Webmention generation (in-flight)

Draft notifications

Micropub location - to wire OwnYourSwarm to start slurping to somewhere. (Maybe pilogs? How?)

Micropub event

Micropub card

mp-query - to discover what a given domain is ready to accept

Micropub query, edit - reversing the terminal flow will be complicated!

Webactions (like/fave, repost, reply) - I care to own my content but am comfortable allowing conversation to take place in the silos. But other IndieWeb boosters want it all

MetaWebLogAPI - I don't need it but it might enable a lot of clients

Self-hosted indieauth for config

## Credits

This was inspired by and initiated as a fork of Barry Frost's [Transformative](https://github.com/barryf/transformative).
