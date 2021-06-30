plan puppetdschelper::run_tests() {
  # get pe_server ?
  $server = get_targets('*').filter |$n| { $n.vars['role'] == 'server' }

  # get agents ?
  $agents = get_targets('*').filter |$n| { $n.vars['role'] != 'server' }

  # Upload module to server and install it
  # Module names are hardcoded for now, should be passed through in the future(?)
  # Is this needed, since module generation is covered by an existing test, could we just install from the forge?
  $export_path = 'D:/a/Puppet.Dsc/Puppet.Dsc/import/powershellget/pkg/dsc-powershellget-2.2.5-0-0.tar.gz'
  $upload_path = '/tmp/dsc-powershellget-2.2.5-0-0.tar.gz'
  upload_file($export_path, $upload_path, $agents)
  run_command("puppet module install ${upload_path} --ignore-dependencies", $server)
  # Install module on agents - upload_file command fails
  # $upload_path_windows = 'C:/dsc-powershellget-2.2.5-0-0.tar.gz'
  # upload_file($export_path, $upload_path_windows, $server)
  # run_command("puppet module install ${upload_path_windows} --ignore-dependencies", $agents)

  # Retrieve the agent fqdn's
  $agent_1_fqdn = run_command('facter fqdn', $agents[0]).to_data[0]['value']['stdout'].strip()
  $agent_2_fqdn = run_command('facter fqdn', $agents[1]).to_data[0]['value']['stdout'].strip()

  # Create the test manifest
#   $manifest = "node '${agent_1_fqdn}' {
#   dsc_psrepository { 'Trust PSGallery':
#     dsc_name               => 'PSGallery',
#     dsc_ensure             => 'Present',
#     dsc_installationpolicy => 'Trusted',
#   }
#   dsc_psmodule { 'Install BurntToast for notifications':
#     dsc_name   => 'BurntToast',
#     dsc_ensure => 'Present',
#   }  
# }

# node '${agent_2_fqdn}' {
#   dsc_psrepository { 'Trust PSGallery':
#     dsc_name               => 'PSGallery',
#     dsc_ensure             => 'Present',
#     dsc_installationpolicy => 'Trusted',
#   }
#   dsc_psmodule { 'Install BurntToast for notifications':
#     dsc_name   => 'BurntToast',
#     dsc_ensure => 'Present',
#   }  
# }"
  $site_pp = "node default {}
  
node '${agent_1_fqdn}' {
  dsc_psrepository { 'Trust PSGallery':
    dsc_name               => 'PSGallery',
    dsc_ensure             => 'Present',
    dsc_installationpolicy => 'Trusted',
  }
  dsc_psmodule { 'Install BurntToast for notifications':
    dsc_name   => 'BurntToast',
    dsc_ensure => 'Present',
  }  
}

node '${agent_2_fqdn}' {
  dsc_psrepository { 'Trust PSGallery':
    dsc_name               => 'PSGallery',
    dsc_ensure             => 'Present',
    dsc_installationpolicy => 'Trusted',
  }
  dsc_psmodule { 'Install BurntToast for notifications':
    dsc_name   => 'BurntToast',
    dsc_ensure => 'Present',
  }  
}"
  out::message($manifest)

  # Upload test manifest to server
  # write_file($manifest, '/etc/puppetlabs/code/environments/production/manifests/test.pp', $server)
  write_file($manifest, '/etc/puppetlabs/code/environments/production/manifests/site.pp', $server)

  # Run agent on each machine
  $agents.each |$agent| {
    run_command('puppet agent -t', $agent)
  }
}
