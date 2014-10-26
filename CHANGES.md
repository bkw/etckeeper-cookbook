Changelog
=========

1.0.4 (unreleased)
-----
* switched to berkshelf v3
* added chefspec tests
* added rubocop checks
* added foodcritic checks
* added travis-ci
* added serverspec tests
* clean up leftovers from old cookbook versions
* remove bzr directory (for vcs git)
* initialize etckeeper upon installation
* set email in git config via attribute

1.0.3
-----

* new attributes, by Yuya.Nishida (@nishidayuya)
    * daily_auto_commits
    * special_file_warning
    * commit_before_install
* gentoo support, by Florian Eitel (@nougad)
* fixes to cron job, by Florian Eitel (@nougad)
* use etckeeper internal cpmmit push functionality, by Florian Eitel (@nougad)
* tighter permissions for /root/.ssh, by Florian Eitel (@nougad)
* removed old chef handler, by @arr-dev

1.0.2
-----

* Use StrictHostKeyChecking for disable authenticity host checking

1.0.1
-----

* Merge with TYPO3
* Remove unnecessary attributes
* Remove manual adding cron task - only change cron.daily screept if use remote
* Change from post-install push - to commit push
* Remove init from config. Now remote checking on etcekeeper commit hook
* Few renames for simple code view

