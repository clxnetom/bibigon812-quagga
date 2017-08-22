Puppet::Type.newtype(:quagga_access_list) do
  @doc = %q{
    This type provides the capability to manage access-lists within puppet.

      Example:

        quagga_access_list {'1':
          ensure => present,
          remark => 'IP standard access list',
          rules  => [
            'deny 10.0.0.128 0.0.0.127',
            'deny host 10.0.101.193',
            'permit 10.0.0.0 0.0.255.255',
            'permit host 192.168.10.1'.
            'deny any'
          ]
        }

        quagga_access_list {'100':
          ensure   => present,
          remark   => 'IP extended access-list',
          rules    => [
            'deny ip host 10.0.1.100 any',
            'permit ip 10.0.1.0 0.0.0.255 any',
            'deny ip any any'
          ]
        }

        quagga_access_list {'a_word':
          ensure => present,
          remark => 'IP zebra access-list',
          rules  => [
            'deny 192.168.0.0/23',,
            'permit 192.168.0.0/16',
            'deny any',
          ]
        }
  }

  ensurable do
    defaultvalues
    defaultto :present
  end

  newparam(:name, namevar: true) do
    desc 'IP access-list name or number.'

    validate do |value|
      begin
        value = Integer(value)
        unless (value > 0 and value < 200) or (value > 2000 and value < 2700)
          fail "Not a valid ID for access-list '#{value}'"
        end
      rescue
        unless value.split(' ').length == 1
          fail "Not a valid name for access-list '#{value}', must be a WORD"
        end
      end
      value
    end
  end

  newproperty(:remark) do
    desc 'Remark for the access-list (only one per access-list).'

    defaultto(:absent)

    validate do |value|
      unless value == :absent
        fail "Invalid value '#{value}'. It is not a String" unless value.is_a?(String)
      end
    end
  end

  newproperty(:rules, :array_matching => :all) do
    desc 'Permits and denies for the access-list.'

    defaultto([])
    validate do |value|
      case value
      when /\A(deny|permit)\s(?:(\d{1,3}\.){3}\d{1,3})\s?(?:(\d{1,3}\.){3}\d{1,3})?\Z/
      when /\A(deny|permit)\s(any|host\s(?:(\d{1,3}\.){3}\d{1,3}))\Z/
      when /\A(deny|permit)\sip\s(?:(\d{1,3}\.){3}\d{1,3})\s(?:(\d{1,3}\.){3}\d{1,3})\s(?:(\d{1,3}\.){3}\d{1,3})\s(?:(\d{1,3}\.){3}\d{1,3})\Z/
      when /\A(deny|permit)\sip\s(?:(\d{1,3}\.){3}\d{1,3})\s(?:(\d{1,3}\.){3}\d{1,3})\s(any|host)\s?(?:(\d{1,3}\.){3}\d{1,3})?\Z/
      when /\A(deny|permit)\sip\sany\s(any|host|(?:(\d{1,3}\.){3}\d{1,3}))\s?(?:(\d{1,3}\.){3}\d{1,3})?\s?(?:(\d{1,3}\.){3}\d{1,3})?\Z/
      when /\A(deny|permit)\sip\shost\s(?:(\d{1,3}\.){3}\d{1,3})\s((?:(\d{1,3}\.){3}\d{1,3})|any|host)\s?(?:(\d{1,3}\.){3}\d{1,3})?\Z/
      else
        fail "Not a valid access-list rule '#{value}'"
      end
    end
  end

  autorequire(:package) do
    %w{quagga}
  end

  autorequire(:service) do
    %w{zebra}
  end
end
