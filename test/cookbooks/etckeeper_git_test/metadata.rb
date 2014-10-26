name             "etckeeper_git_test"
maintainer       "Bernhard K. Weisshuhn"
maintainer_email "bkw@codingforce.com"
license          "Apache 2.0"
description      "Testing cookbook for etckeeper_git"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "0.0.1"

recipe           "etckeeper_git_test", "Installs deps for proper testing"

depends          "etckeeper_git"

%w{
  redhat centos scientific fedora debian ubuntu arch freebsd amazon gentoo
}.each do |os|
  supports os
end
