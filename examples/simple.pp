dsc_psrepository { 'Trust PSGallery':
  dsc_name               => 'PSGallery',
  dsc_ensure             => 'Present',
  dsc_installationpolicy => 'Trusted',
}

dsc_psmodule { 'Install BurntToast for notifications':
  dsc_name   => 'BurntToast',
  dsc_ensure => 'Present',
}
