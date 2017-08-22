Puppet::Type.type(:quagga_access_list).provide :quagga do
  @doc = 'Manages a standard assecc-list using quagga.'

  commands :vtysh => 'vtysh'

  mk_resource_methods

  def self.instances
    providers = []
    hash = {}
    found = false

    config = vtysh('-c', 'show running-config')
    config.split(/\n/).collect do |line|

      next if line =~ /\A!\Z/

      if /\Aaccess-list\s(\S+)\sremark\s(.+)\Z/ =~ line
        name = $1
        remark = $2
        found = true

        hash[name] = {
          ensure:   :present,
          name:     name,
          provider: self.name,
          remark:   remark,
          rules:    [],
        }

      elsif /\Aaccess-list\s(\S+)\s(deny|permit)\s(.+)\Z/ =~ line
        name = $1
        action = $2
        rule = $3

        hash[name] ||= {
          ensure:   :present,
          name:     name,
          provider: self.name,
          rules:    [],
        }

        hash[name][:rules] << "#{action} #{rule}"

      elsif line =~ /\A\w/ and found
        break
      end
    end

    hash.each do |name, property_hash|
      debug 'Instantiated the resource %{hash}' % { hash: property_hash.inspect }
      providers << new(property_hash)
    end

    providers
  end

  def self.prefetch(resources)
    instances.each do |provider|
      if resource = resources[provider.name]
        resource.provider = provider
      end
    end
  end

  def create
    debug 'Creating the the resource %{hash}.' % { hash: @resource.to_hash.inspect }

    cmds = []
    cmds << 'configure terminal'

    unless @resource[:remark].nil?
      cmds << 'access-list %{name} remark %{remark}' % {
        name:   @resource[:name],
        remark: @resource[:remark],
      }
    end

    @resource[:rules].each do |rule|
      cmds << 'access-list %{name} %{rule}' % {
        name: @resource[:name],
        rule: rule
      }
    end

    cmds << 'end'
    cmds << 'write memory'
    vtysh(cmds.reduce([]){ |cmds, cmd| cmds << '-c' << cmd })

    @property_hash = @resource.to_hash
  end

  def destroy
    debug 'Destroying the resource %{hash}.' % { hash: @property_hash.inspect }

    cmds = []
    cmds << 'configure terminal'

    cmds << 'no access-list %{name}' % { name: @property_hash[:name] }

    cmds << 'end'
    cmds << 'write memory'
    vtysh(cmds.reduce([]){ |cmds, cmd| cmds << '-c' << cmd })

    @property_hash.clear
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def rules=(value)
    destroy
    create

    @property_hash[:rules] = value
  end

  def remark=(value)
    cmds = []
    cmds << 'configure terminal'

    unless @resource[:remark].nil?
      cmds << 'access-list %{name} remark %{remark}' % {
        name:   @resource[:name],
        remark: @resource[:remark],
      }
    end

    cmds << 'end'
    cmds << 'write memory'
    vtysh(cmds.reduce([]){ |cmds, cmd| cmds << '-c' << cmd })

    @property_hash[:remark] = value
  end
end
