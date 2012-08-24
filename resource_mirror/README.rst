resource_mirror
===============

Script to mirror any `git`_ repo.

Useful for mirroring the `openbel-framework-resources`_ repository.

For example to mirror to a directory:
::

    usage: git_mirror.sh <branch> <repo> <dir>
    ./git_mirror.sh master git://github.com/OpenBEL/openbel-framework-resources.git /var/www/mirror

.. _git: http://git-scm.com/
.. _openbel-framework-resources: https://github.com/OpenBEL/openbel-framework-resources
