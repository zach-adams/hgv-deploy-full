Varnish for Ansible
===================

A role for deploying and configuring [Varnish](http://varnish.com/) and extensions on unix hosts using [Ansible](http://www.ansibleworks.com/).

It can additionally be used as a playbook for quickly provisioning hosts.

Vagrant machines are provided to produce a boxed install of Varnish or a VM for integration testing.


Supports
--------
Supported Varnish versions:
- Varnish 3.x

Supported targets:
- Ubuntu 14.04 LTS "Trusty Tahr"
- Ubuntu 12.04 LTS "Precise Pangolin"
- Debian (untested)
- RedHat (untested)

Installation methods:

- Binary packages from the official repositories at [Varnish](https://www.varnish-cache.org/repo)

Callable tasks:

- `vcl`: Creates (or removes) a Varnish VCL configuration


Usage
-----
Clone this repo into your roles directory:

    $ git clone https://github.com/zenoamaro/ansible-varnish.git roles/varnish

And add it to your play's roles:

    - hosts: ...
      roles:
        - varnish
        - ...

This roles comes preloaded with almost every available default. You can override each one in your hosts/group vars, in your inventory, or in your play. See the annotated defaults in `defaults/main.yml` for help in configuration. All provided variables start with `varnish_`.

You can also use the role as a playbook. You will be asked which hosts to provision, and you can further configure the play by using `--extra-vars`.

    $ ansible-playbook -i inventory --extra-vars='{...}' main.yml

To provision a standalone Varnish box, start the `boxed` VM, which is a Ubuntu 12.04 box:

    $ vagrant up boxed

You will find Varnish listening on the VM's `80` port on address `192.168.33.20` in the private network. You should probably, at minimum, point `varnish_backend` to the `address:port` of a webservice you want to cache.

Run the tests by provisioning the appropriate VM:

    $ vagrant up test-ubuntu-trusty

At the moment, the following test boxes are available:

- `test-ubuntu-precise`
- `test-ubuntu-trusty`


Still to do
-----------
- Provide a simple way to route multiple VCL files


Changelog
---------
### 0.1.1
- The package list is not being updated in playbooks anymore.
- Added new test machines.

### 0.1
Initial version.


License
-------
The MIT License (MIT)

Copyright (c) 2015, zenoamaro <zenoamaro@gmail.com>

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.