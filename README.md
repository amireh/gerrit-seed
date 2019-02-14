# gerrit-seed

Seed Gerrit with some sample data.

## Usage

You need Ruby 2.5+ to use the program:

    gem install gerrit-seed

To apply the changes, pass in the file on STDIN:

    gerrit-seed < path/to/seed.yml

And to undo the changes (what can be undone, anyway):

    gerrit-unseed < path/to/seed.yml

## Seed files

Seed files are written in YAML and have a structure outlined in the following
example:

```yaml
---
# file: some-seed.yml

# Create a project:
- project:
    name: banana

# Create a user:
- user:
    email: admin@example.com
    full_name: Administrator
    group: Administrators
    ssh_key: ~/.ssh/id_rsa.pub
    username: admin

# Create another user:
- user:
    email: emperor@example.com
    full_name: Emperor Tamarin
    group: Non-Interactive Users
    ssh_key: ~/.ssh/id_rsa.pub
    username: emperor

# Create a change:
- change:
    author: emperor
    name: '[01] spell "lunchroom"'
    parent: master
    project: banana

# Create a change rebased on top of another:
- change:
    author: emperor
    name: '[02] spell "shade"'
    parent: '[01] spell "lunchroom"'
    project: banana
```
