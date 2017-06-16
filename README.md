# loopback-fixtures-loader

Expressive fixtures generator for Loopback

[![build status](https://secure.travis-ci.org/sghribi/loopback-fixtures.svg)](http://travis-ci.org/sghribi/loopback-fixtures)
[![dependency status](https://david-dm.org/sghribi/loopback-fixtures.svg)](https://david-dm.org/sghribi/loopback-fixtures)

## Installation

### Basic usage

```
npm install --save loopback-fixtures-loader
```

Then, in your `server/component-config.json`, add :

``` json
{
  "loopback-fixtures": {
    "fixturePath": "/fixtures/data/",
    "append": false,
    "autoLoad": false
  }
}
```

Write your YML fixture file `/fixture/data/data.yml` (adapt according your model) :


``` yaml
Group:
  group{1..10}:
    name: "Groupe {@} depuis les fixtures"

User:
  user{1..10}:
    name: "User {@} : {{name.lastName}}"
    groupId: @group{@}
    email: "{{internet.email}}"
    birthDate: "2016-01-01"
    favoriteNumber: "(function() { return Math.round(Math.random()*1000);})()"
```

### How to load fixtures ?

 - If `autoLoad` is set to `true`, fixtures will be loaded when you start your application

 - With the server:

    `app.loadFixtures()` (return a promise)

    e.g:

    ``` js
    app.loadFixtures()
    .then(function() {
      console.log('Done!');
    })
    .catch(function(err) {
      console.log('Errors:', err);
    });
    ```

 - With a node command:

    ```
    ./node_modules/loopback-fixtures-loader/lib/load-fixtures.js
    ```

### Configuration options

 - `fixturePath` (default value `'/fixtures/data'`)

    The directory to load data fixtures from

 - `append` (default value `false`)

    If set to `true`, data fixtures will be append instead of deleting all data from the database first.
    **WARNING** `false` will erase your database

 - `autoLoad` (default value `false`)


### Features

 - Load data according your model

 - Multiple generators :

    ``` yaml
    User:
      user{1..45}:
        name: "User number {@}"
    ```

    `{@}` represents the current identifier for the generator

 - References :

     ``` yaml
     Group:
       group{1..3}:
         name: "Groupe number {@}"

     User:
       user{1..9}:
         name: "User number {@}"
         group: @group1  # Reference to group1

       user{10..19}:
         name: "User number {@}"
         group: @group.* # Reference to any matching group
     ```

     `@group1` represents the reference for the group1 and can be used in other fixtures
     `@group.*` represents the reference for a **random** matching group

 - Fakers :

    ``` yaml
    User:
      user{1..10}:
        name: "User n°{@} : {{name.lastName}} {{name.firstName}}"
        email: "{{internet.email}}"
    ```

    You can use [Faker.js](https://github.com/marak/faker.js) API to provide fake data

 - Custom function :

    ``` yaml
    User:
      user{1..10}:
        favoriteNumber: "(function() { return Math.round(Math.random()*1000);})()"
    ```

    You can use custom functions too



## Credits
[Samy Ghribi](https://github.com/sghribi)

## License

ISC
