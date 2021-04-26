# README

[![CircleCI](https://circleci.com/gh/momonga11/notenext-server.svg?style=svg)](https://circleci.com/gh/momonga11/notenext-server)

This README would normally document whatever steps are necessary to get the
application up and running.

Things you may want to cover:

* Ruby version

* System dependencies

* Configuration

* Database creation

* Database initialization

* How to run the test suite

* Services (job queues, cache servers, search engines, etc.)

* Deployment instructions

* ...

## オンプレ本番環境作成方法
config/credentials.yml.enc をいったん削除して、
```
EDITOR=vim rails credentials:edit
```
