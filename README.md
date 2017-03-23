# Rails template demo

Use rails application template generate rails project.

## How to use:

```
$host: git clone rails_template_demo.git
$host: rails new your_app_name -m app_template.rb
```

## What's generate in this template: 

<pre>
├── .gitignore
├── Gemfile
├── README.md
├── config
│   ├── application.rb [timezone]
│   ├── database.yml
│   ├── initializers
│   │   ├── redis.rb
│   ├── routes.rb[health_check]
│   ├── settings
│   │   ├── development.yml[TODO]
│   │   ├── production.yml[TODO]
│   │   └── test.yml[TODO]
│   ├── settings.local.yml
│   ├── settings.yml
│   ├── newrelic.yml
├── db
│   ├── migrate
│   │   ├── xxxxxxxxxxxxxx_create_users.rb
├── spec
│   ├── models
│   │   └── user_spec.rb
│   ├── rails_helper.rb
│   └── spec_helper.rb
</pre>

