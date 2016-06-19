# loopback-fixtures

Expressive fixtures generator for Loopback

[![build status](https://secure.travis-ci.org/sghribi/loopback-fixtures.svg)](http://travis-ci.org/sghribi/loopback-fixtures)
[![dependency status](https://david-dm.org/sghribi/loopback-fixtures.svg)](https://david-dm.org/sghribi/loopback-fixtures)

## Installation

### Basic usage

```
npm install --save loopback-fixtures
```

Then, in your `server/component-config.json`, add :

``` json
{
  // Some other stuff...
  "loopback-fixtures": {
    fixturePath: '/fixtures/data/'  // Folder that contains YAML fixtures files
    append: false,                  // Append the data fixtures
    autoLoad: false                 // Load on startup
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
    name: "User {@}"
    groupId: @group{@}
    email: "yolo{@}@gmail.com"
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
      console.log('Done!);
    })
    .catch(function(err) {
      console.log('Errors:', err);
    });
    ```

  - With a node command : **@TODO**

    ```
    node ./node_modules/loopback-fixtures/load-fixtures.js [--fixturePath=/fixtures/data] [--append=false]
    ```

### Configuration options

 - `fixturePath` (default value `'/fixtures/data'`)

    The directory to load data fixtures from

 - `append` (default value `false`)

    If set to `true`, data fixtures will be append instead of deleting all data from the database first.
    **WARNING** `false` will erase your database

 - `autoLoad` (default value `false`) **@TODO**


## Credits
[Samy Ghribi](https://github.com/sghribi/)

## License

ISC
