# Does not work, this is my expected usage/syntax:
#notice(
  #inline_template("<%= scope.function_extlookup('hello world') %>")
#)

# Closer, but requires an additional step:
notice(
  inline_template("<%= scope.function_extlookup('hello world') %>")
)

# Works, we have to pass it as an array:
#notice(
  #inline_template("<%= Puppet::Parser::Functions.autoloader.loadall; scope.function_extlookup(['hello world']) %>")
#)

