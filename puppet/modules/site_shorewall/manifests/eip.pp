class site_shorewall::eip {

  # be safe for development
  #$shorewall_startup='0'

  include site_shorewall::defaults

  $interface  = hiera('interface')
  $ssh_config = hiera('ssh')
  $ssh_port   = $ssh_config['port']  

  # define macro
  file { '/etc/shorewall/macro.leap_eip':
    content => "PARAM   -       -       tcp     53,80,443,1194,$ssh_port
PARAM   -       -       udp     53,80,443,1194
", }


  # define interfaces
  shorewall::interface { $interface:
    zone      => 'net',
    options   => 'tcpflags,blacklist,nosmurfs';
  }

  shorewall::interface    {'tun0':
    zone    => 'eip',
    options => 'tcpflags,blacklist,nosmurfs'; }
  shorewall::interface    {'tun1':
    zone    => 'eip',
    options => 'tcpflags,blacklist,nosmurfs'; }


  shorewall::zone         {'eip':
    type => 'ipv4'; }

  shorewall::routestopped { $interface:
    interface => $interface; }


  shorewall::masq { "${interface}_tcp":
    interface => $interface,
    source    => "$site_config::eip::openvpn_tcp_network_prefix.0/$site_config::eip::openvpn_tcp_cidr"; }

  shorewall::masq { "${interface}_udp":
    interface => $interface,
    source    => "$site_config::eip::openvpn_udp_network_prefix.0/$site_config::eip::openvpn_udp_cidr"; }

  shorewall::policy {
    'eip-to-all':
      sourcezone      => 'eip',
      destinationzone => 'all',
      policy          => 'ACCEPT',
      order           => 100;
    'all-to-all':
      sourcezone      => 'all',
      destinationzone => 'all',
      policy          => 'DROP',
      order           => 200;
  }

  shorewall::rule {
      'all2all-ping':
        source      => 'all',
        destination => 'all',
        action      => 'Ping(ACCEPT)',
        order       => 200;

      'net2fw-ssh':
        source      => 'net',
        destination => '$FW',
        action      => 'SSH(ACCEPT)',
        order       => 200;
      'net2fw-openvpn':
        source      => 'net',
        destination => '$FW',
        action      => 'leap_eip(ACCEPT)',
        order       => 200;

      # eip gw itself to outside
      'fw2all-http':
        source      => '$FW',
        destination => 'all',
        action      => 'HTTP(ACCEPT)',
        order       => 200;
      'fw2all-DNS':
        source      => '$FW',
        destination => 'all',
        action      => 'DNS(ACCEPT)',
        order       => 200;
      'fw2all-git':
        source      => '$FW',
        destination => 'all',
        action      => 'Git(ACCEPT)',
        order       => 200;

      'eip2fw-https':
        source      => 'eip',
        destination => '$FW',
        action      => 'HTTPS(ACCEPT)',
        order       => 200;
  }
}
