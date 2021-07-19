dsc_ntfsaccessentry {'Test':
  dsc_path              => "C:\\test",
  dsc_accesscontrollist => [
    {
      principal          => 'Everyone',
      forceprincipal     => true,
      accesscontrolentry => [
        {
          accesscontroltype => 'Allow',
          filesystemrights  => ['FullControl'],
          inheritance       => 'This folder and files',
          ensure            => 'Present',
          cim_instance_type => 'NTFSAccessControlEntry',
        }
      ]
    }
  ]
}
