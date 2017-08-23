Puppet::Type.newtype(:quagga_ospf_distribute_list) do
  @doc = %q{
    This type provides the capability to manage OSPF distribute-lists within puppet.

      Examples:

        quagga_ospf_distribaute_list { 'kernel':
            ensure => present,
            access_list => 'word',
        }
  }

  ensurable

  newparam(:name) do
    desc 'Route source the list restricts.'

    newvalues(:babel, :bgp, :connected, :isis, :kernel, :rip, :static, :absent)
    defaultto(:absent)
  end

  newproperty(:access_list) do
    desc 'Set the access-list name for the distribute-list.'

    newvalues(/\A\w+\Z/, :absent)
    defaultto(:absent)
  end

  autorequire(:package) do
    %w{quagga}
  end

  autorequire(:service) do
    %w{zebra bgpd}
  end
end
