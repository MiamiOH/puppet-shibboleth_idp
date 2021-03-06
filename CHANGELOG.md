# Changelog

All notable changes to this project will be documented in this file. The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/) and this project adheres to [Semantic Versioning](http://semver.org).

## [v1.4.1](https://github.com/MiamiOH/puppet-shibboleth_idp/tree/1.4.1) (2020-04-16)

[Full Changelog](https://github.com/MiamiOH/puppet-shibboleth_idp/compare/1.4.0...1.4.1)

### Removed

- Removed flows/authn/Shibcas directory
- Removed 'authn/Shibcas' from general-authn.xml


### Fixed

- Replaced shib-cas-authenticator version 3.0.0 with 3.3.0
- Replaced cas-client-core version 3.4.1 with 3.6.0
- Forced External on idp.authn.flows

## [v1.4.0](https://github.com/MiamiOH/puppet-shibboleth_idp/tree/1.4.0) (2020-03-18)

[Full Changelog](https://github.com/MiamiOH/puppet-shibboleth_idp/compare/v1.3.0...v1.4.0)

### Removed

- Removed $slf4j_checksum_type, $slf4j_checksum, $logback_checksum_type, $logback_checksum parameters
- Removed spec/spec.opts

### Added

- PDK convert has been applied to make module PDK compliant
- Increased puppet-archive dependency max version limit
- $casclient_source parameter for cas-client-core-3.4.1.jar retrieval

### Fixed

- Removed absolute paths from class names
- Fixed a variety of linting errors

