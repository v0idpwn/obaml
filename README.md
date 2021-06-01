# Obaml
Unnoficial [Oban](https://github.com/sorentwo/oban) client library for Ocaml.

Work in progress. Not ready for production.

## Intentions
This library aims to be **100% runtime free**. This means that it just provides
the functions you need to interact with Oban from your application but doesn't
do anything for you. For some examples on how you can use it, see the examples
directory.

It also doesn't aim to be feature complete with Oban, but to provide the
required structure to run Oban Jobs from Ocaml programs.

## Roadmap

[X] Fetch jobs
[X] Execute and ack jobs
[ ] Insert jobs (basic)
[ ] Stage jobs
[ ] Prune

## Credits
All credits to the Oban team. This is a partial port of the OSS API of Oban to
Ocaml.
