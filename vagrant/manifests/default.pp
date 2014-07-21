import '/vagrant/modules/camping/manifests/init.pp'
import '/vagrant/modules/sqlite/manifests/init.pp'
import '/vagrant/modules/apache/manifests/init.pp'

include camping
include sqlite
include apache
