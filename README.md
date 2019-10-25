# zsh-shared

zsh-shared is a simple **shared memory** between processes for zsh. It works with subshells and jobs.
Every action on shared memory is syncronized and mutually exclusive so any concurrent access to shared information is prevented.

## Getting started

To use zsh-shared just source it from any path and start the server.

```
source <PATH>/shared.zsh
shared start
```

Once the (offline) server is started, you can run commands that works in a shared memory. All the possible commands are explained below.

To stop the server you should run:

```
shared stop
```

### Commands

#### start

`shared start` starts the server on `pwd` location.

#### stop

`shared stop` stops the server.

#### var

`shared var` lets use shared variables.
* `shared var <name> <value>` set the variable 'name' to 'value'
* `shared var <name>` get the value of the variable 'name'

#### map

`shared map` lets use shared maps.
* `shared map <map>` define the map named 'map'
* `shared map <map> <key>` get the value of the 'key' on 'map'
* `shared map <map> <key> <value>` set the value of the 'key' on 'map' to 'value'

#### exe
`shared exe <any zsh code>` runs custom commands

### Example

```zsh
source <path>/shared.zsh
shared start

function asynchronous_function() {
    shared var myvar second
}

shared var myvar first
shared var myvar
#should print 'first'

asynchronous_function &
sleep 0.5

shared var myvar 
#should print 'second'
```
