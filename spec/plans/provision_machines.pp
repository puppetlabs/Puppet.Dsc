plan puppetdsc::provision_machines(
  Optional[String] $using = 'provision_service',
  Optional[String] $server = 'rhel-8',
  Optional[Array[String]] $agents = ['windows-2016', 'windows-2019']
) {
  # provision server
  run_task("provision::${using}", 'localhost', action => 'provision', platform => $server, vars => 'role: server')

  # provision agents
  $agents.each |$agent|{
    run_task("provision::${using}", 'localhost', action => 'provision', platform => $agent, vars => 'role: agent')
  }
}
