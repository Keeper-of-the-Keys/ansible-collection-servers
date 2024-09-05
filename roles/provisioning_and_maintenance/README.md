Provisioning and Maintenance
============================

This role has most of the initial steps that I run on servers as well as ongoing maintenance tasks.

Requirements
------------

Since the goal of the role is initial provisioning it does not have prior requirements other than that the host be reachable 
by SSH.

Role Variables
--------------

Defaults:
    become_group:
      Debian: sudo
      RedHat: wheel

    ssh_service:
      Debian: ssh
      RedHat: sshd

    baseline_packages:
      Debian:
      - sudo
      RedHat:
      - sudo

`baseline_packages` is overridden in vars with my set and can/should be adjusted by the user according to their needs, it can 
of course also be overridden at the group/host level.

Group/host vars that are also expected/used:

    # It is highly recommended to use ansible-vault for the various secrets/passphrases.
    # Default local users
    default_users:
    - username: 
      fullname: 
      uid: 
      shell: 
      password:
      groups: '{{ become_group[ansible_facts.os_family] }}'
      state: present
      key: 

    # SSH settings, if SSH keys were deployed successfully SSHd will be configured to disallow password authentication.
    ssh_keys_only: yes

If a host is a proxmox guest (vm/ct) then it can be snapshotted automatically before the update with the following vars set:

    # Stricly host settings (one or both of these is needed):
    pve_vmid:
    pve_vm_name:

    # These can be per host or group either is logical
    # The API token needs the following permissions: VM.Audit VM.Snapshot

    pve_api_host:
    pve_api_token_id:
    pve_api_token_secret:

    # Only mandatory if different from default:
    pve_api_user: 'root@pam'
    pve_snapshot_retention: 2

Dependencies
------------

The only non `ansible.builtin` task is `ansible.posix.authorized_key`.

Example Playbook
----------------

Playbook to run the whole role:

    ---
    - name: Playbook to run initial setup of user and baseline software
      hosts: servers
      become: yes
      serial: 1

      collections:
      - keeperofthekeys.servers

      roles:
      - role: provisioning_and_maintenance
        state: present

Playbook to run just the system update, one could argue that the initial playbook should always be run since it also updates 
and if a host baseline is different from the default baseline that should be set in host/group vars, thus you would always 
ensure that the host has the correct users and baseline installed, either way this option is also available:

    ---
    - name: Playbook to update systems
      hosts: servers
      #become: true # note that all the tasks in this playbook have become: true on the task so not needed at playbook level.
      serial: 1

      collections:
      - keeperofthekeys.servers

      tasks:
      - name: System update
        ansible.builtin.include_role:
          name: provisioning_and_maintenance
          tasks_from: system_update

License
-------

GPLv2

Author Information
------------------

(c) 5784-2024 E.S.Rosenberg (Keeper of the Keys - https://github.com/Keeper-of-the-Keys/)
