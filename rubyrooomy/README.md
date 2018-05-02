# rubyrooomy

Is a gem with multiple functions we use in our backend testing framework.

Many functions can be invocated from the command-line, as follows:

````
./rubyrooomy.rb  puts "Hello World"
Hello World
````

The best documentation for the functions is in the code itself. As much as
possible, examples are being provided, starting with `sample_example__`.
So, for understanding `define_contexts`, just check
`sample_example__define_contexts` code (one function call only) and run it:
````
./rubyrooomy.rb  invoke_double puts sample_example__define_contexts
{"role"=>"role_3", "authenticate_as"=>"role_1", "result"=>"role_1 ALLOWED to create role_3"}
{"role"=>"role_3", "authenticate_as"=>"role_2", "result"=>"role_2 ALLOWED to create role_3"}
{"role"=>"role_4", "authenticate_as"=>"role_1", "result"=>"role_1 ALLOWED to create role_4"}
{"role"=>"role_4", "authenticate_as"=>"role_2", "result"=>"role_2 ALLOWED to create role_4"}
{"role"=>"role_1", "authenticate_as"=>"role_1", "result"=>"role_1 NOT ALLOWED to create role_1"}
{"role"=>"role_1", "authenticate_as"=>"role_2", "result"=>"role_2 NOT ALLOWED to create role_1"}
{"role"=>"role_2", "authenticate_as"=>"role_1", "result"=>"role_1 NOT ALLOWED to create role_2"}
{"role"=>"role_2", "authenticate_as"=>"role_2", "result"=>"role_2 NOT ALLOWED to create role_2"}
````

