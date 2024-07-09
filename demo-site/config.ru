Encoding.default_internal = Encoding.default_external = 'UTF-8'
$: << File.expand_path(File.join(__FILE__, '../../lib'))
require ::File.expand_path('../autoforme_demo',  __FILE__)
run AutoFormeDemo::App.app
