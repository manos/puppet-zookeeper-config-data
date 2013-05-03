#
# puppet-zookeeper module, for managing configuration data via puppet (storing
# in zookeeper)
#
# This class installs the pre-requisites.
# See the lib/ directory for the goodies, and README.md for usage.
#
class zk_puppet {

    # gems these parser functions require:
    package { ['zk',]:
        ensure   => installed,
        provider => gem,
    }

}
