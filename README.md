# README

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


# CharitiCo（リポジトリ/プロジェクト/OSSなどの名前）

「学習すること」が「社会貢献」に直接結びつくアプリ

# DEMO

# Features

学習量に応じて、自動的に慈善団体に寄付される

## usersテーブル

| Column | Type       | Options                        |
| ------ | ---------- | ------------------------------ |
| email   | string | null: false |
| encrypted_password | string | null: false |
| name 　　　　　　　　　　　　　　　　　　　　　　　　　　　　| string | null: false |
| icon               | string | null: false |

### Association
- has_many :prototypes
- has_many :comments

## prototypesテーブル

| Column     | Type       | Options                        |
| ---------- | ---------- | ------------------------------ |
| title      | string     | null: false |
| catch_copy | text       | null: false |
| concept    | text       | null: false |
| user       | references | null: false |

### Association - belongs_to :user
- has_many :comments

## commentsテーブル

| Column    | Type       | Options                        |
| ------    | ---------- | ------------------------------ |
| content   | text       | null: false |
| prototype | references | null: false |
| user      | references | null: false |

### Association
- belongs_to :user
- belongs_to :prototype

