Shibboleth IdP
=============

#### Table of Contents

1. [Overview](#overview)
2. [Module Description - What the module does and why it is useful](#module-description)
3. [Setup - The basics of getting started with Shibboleth IdP](#setup)
    * [What the IdP affects](#what-the-idp-affects)
    * [Setup requirements](#setup-requirements)
    * [Beginning with the IdP](#beginning-with-the-idp)
4. [Usage - Configuration options and additional functionality](#usage)
    * [Customize the IdP options](#customize-the-the-idp-options)
    * [Configure with hiera yaml](#configure-with-hiera-yaml)
5. [Reference - An under-the-hood peek at what the module is doing and how](#reference)
    * [Classes](#classes)
6. [Limitations - OS compatibility, etc.](#limitations)
7. [Development - Guide for contributing to the module](#development)
8. [Contributors](#contributors)

## Overview

Puppet Module to manage a Shibboleth IdP

## Module Description

The ...

## Setup

### What the IdP affects

* ...

### Setup Requirements

only need to install the module

### Beginning with the IdP

Minimal setup:

```puppet
class { 'shibidp': }
```

## Usage

### Customize the IdP options

```puppet
class { 'shibidp':
  option1   => 'value',
}
```

### Configure with hiera yaml

```puppet
include shibidp
```
```yaml
---
shibidp::option1: 'value'
```

## Reference

### Classes

* shibidp

## Limitations

This module has been built on and tested against Puppet 3.8.x and higher.  
If using puppet 3.8, you must enable the future parser.  
While I am sure other versions work, I have not tested them.

This module supports modern RedHat only systems.  
This module has been tested on CentOS 7.x only.

No plans to support other versions (unless you add it :)..

## Development

Pull Requests welcome

## Contributors

Dirk Tepe (tepeds)
