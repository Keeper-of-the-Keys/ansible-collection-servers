Mailserver
=========

This role while running and finishing properly is still a WIP, I hope to add documentation.

The role deploys a mailserver as relevant for my environment.

In the mean time for myself and anyone who may try to use it things that still need to be done:

- Move apache2 and mysql/mariadb setup to external roles
- For apache virtual hosts config
- "Close the loop" on Apache Mellon + IdP, for ipsilon which I use this probably involves some direct DB interaction
- Amavisd
- ?Greylisting
- All kinds of TODO tagged improvements to the role

Issues:
- Start TLS requires importing the CA cert of the IPA server
- lua-ldap as it ships in Debian segfaults, need >=1.3.1, will be opening a bug about this.

Requirements
------------

Any pre-requisites that may not be covered by Ansible itself or the role should be mentioned here. For instance, if the role uses the EC2 module, it may be a good idea to mention in this section that the boto package is required.

Role Variables
--------------

A description of the settable variables for this role should go here, including any variables that are in defaults/main.yml, vars/main.yml, and any variables that can/should be set via parameters to the role. Any variables that are read from other roles and/or the global scope (ie. hostvars, group vars, etc.) should be mentioned here as well.

Dependencies
------------

A list of other roles hosted on Galaxy should go here, plus any details in regards to parameters that may need to be set for other roles, or variables that are used from other roles.

Example Playbook
----------------

Including an example of how to use your role (for instance, with variables passed in as parameters) is always nice for users too:

    - hosts: servers
      roles:
         - { role: username.rolename, x: 42 }

License
-------

BSD

Author Information
------------------

An optional section for the role authors to include contact information, or a website (HTML is not allowed).
