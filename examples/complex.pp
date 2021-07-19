# This example is an adaptation of the MSFT_xWebSite sample code found here:
# https://github.com/dsccommunity/xWebAdministration/blob/main/source/DSCResources/MSFT_xWebSite/MSFT_xWebSite.psm1

# Assumes this project is cloned to C:\code\Puppet.Dsc
$source_path      = "C:\\code\\Puppet.Dsc\\examples\\website"
$destination_path = "C:\\Foo"
$website_name     = 'example_site'
$site_id          = 7

# Install the IIS role
dsc_xwindowsfeature { 'IIS':
  dsc_ensure => 'Present',
  dsc_name   => 'Web-Server',
}

# Install the ASP .NET 4.5 role
dsc_xwindowsfeature { 'AspNet45':
  dsc_ensure => 'Present',
  dsc_name   => 'Web-Asp-Net45',
}

# Stop the default website
dsc_xwebsite { 'DefaultSite':
    dsc_ensure          => 'Present',
    dsc_name            => 'Default Web Site',
    dsc_state           => 'Stopped',
    dsc_serverautostart => false,
    dsc_physicalpath    => "C:\\inetpub\\wwwroot",
    require             => Dsc_xwindowsfeature['IIS'],
}

# Copy the website content
file { 'WebContent':
    ensure  => directory,
    recurse => true,
    replace => true,
    path    => $destination_path,
    source  => $source_path,
    require => Dsc_xwindowsfeature['AspNet45'],
}

# Create the new Website
dsc_xwebsite { 'NewWebsite':
    dsc_ensure          => 'Present',
    dsc_name            => $website_name,
    dsc_siteid          => $site_id,
    dsc_state           => 'Started',
    dsc_serverautostart => true,
    dsc_physicalpath    => $destination_path,
    require             => File['WebContent'],
}
