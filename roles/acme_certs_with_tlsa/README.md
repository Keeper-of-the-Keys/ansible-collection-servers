ACME certs with TLSA
====================

This role issues signed certificates using the ACME (letsencrypt) protocol specifically by answering the DNS-01 type challenge and can also generate TLSA records.
DNS entries are creates/updated using nsupdate.

The flow of the role is:
1. ACME negotiation and cleanup
2. Generate TLSA records and rotate them in DNS
3. After TLSA propagation deploy certificates to relevant servers and restart services
4. Remove old TLSA records

TLSA can be skipped in which case deploy and service restart will happen immediately after step 1.

Limitations:
- TLSA records are currently for all ports, I hope to in the future add the ability to do per port TLSA records but this does not have a high priority.
- The current TLSA setup assumes only a single cert/fqdn tupple, thus it is not possible to have a different cert on a reverse proxy than on the actual server.
- The nsupdate related tasks currently only support a single zone/key this should be fairly trivial to expand and I hope to do so in the future.

Note: a large part of the tasks in this role will run from localhost, the certificates will be stored locally and copied.

Requirements
------------

This role needs the `tlsa` program to be available on localhost on Debian based system this is provided by the `hash-slinger` package.

Role Variables
--------------
group_vars or role defaults (can of course also be set at host level but leads to lots of duplicate data):
    # It is highly recommended to use ansible-vault for the various secrets/passphrases.
    # nsupdate
    nsupdate:
      key_name:
      key_algorithm:
      key_secret:
      server: '{{ lookup("dig", "ns.domain.tld") }}'
      zone: "domain.tld"

    # letsencrypt
    acme_defaults:
      path_local: # Where all keys, certs, csrs will be stored on localhost
      path_remote: # Default base path on target servers (eg. /etc/ssl/)
      isp_dns: # This should be the IP of a DNS server not part of the domain to test DNS propagation, Cloudflare/Google DNS are *not* recommended since a query of the same IP may hit different servers.
      common_dns: # Any DNS server further away from self, I use 8.8.8.8
      account_email:
      account_passphrase:
      acme_directory: https://acme-v02.api.letsencrypt.org/directory
      #acme_directory: https://acme-staging-v02.api.letsencrypt.org/directory


host_vars:
    acme_certs:
    - name: # CN
      email_address:
      country_name:
      organization_name:
      # alt_names is optional
      alt_names:
        dns: # list of DNS alt names
      tlsa_all_ports: true # currently only all ports is supported
      hosts:
      - name: # host to deploy to
        services: # list of services on host to restart
        # paths is optional, custom paths on the target server for the cert.
        paths:
          certificate:
          fullchain:
          intermediate:
          key:


Dependencies
------------

- community.crypto.openssl_privatekey
- community.crypto.openssl_csr
- community.crypto.acme_certificate
- community.general.nsupdate

Example Playbook
----------------

Including an example of how to use your role (for instance, with variables passed in as parameters) is always nice for users too:

    - hosts: servers
      collections:
      - keeperofthekeys.servers
      roles:
      - role: acme_certs_with_tlsa
        state: present

License
-------

GPLv2

Author Information
------------------

(c) 5784-2024 E.S.Rosenberg (Keeper of the Keys - https://github.com/Keeper-of-the-Keys/)
