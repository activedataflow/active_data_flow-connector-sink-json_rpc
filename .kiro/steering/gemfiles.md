# Submoduler parent gem
The active_data_flow gem includes in its Gemfile:

```
gem 'submoduler-core-submoduler_parent', git: 'https://github.com/
magenticmarketactualskill/submoduler-core-submoduler_child.git'
```

Each subgem or submodule with a name that starts with 'active_data_flow-' includes in its Gemfile:

```
gem 'submoduler-core-submoduler_parent', git: 'https://github.com/
magenticmarketactualskill/submoduler-core-submoduler_child.git'
```

