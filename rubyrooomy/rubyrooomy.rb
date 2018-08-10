#!/usr/bin/env ruby


# Copyright 2018, NedSense Loft BV
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.




=begin
  The purpose of this module is to offer functions that can
  execute postgresql commands in the command line shell where
  ruby is running, like psql, pg_dump, pg_restore.
=end
module RubyRooomyPgShellCommandsModule


=begin
  Generates a psql command to connect to a database,
  given a psql_db definition, which is an array having
  [db_name, db_user, db_password, db_host]
=end
  def psql_db_command__cli psql_db
    shell_params_psql_db = quoted_shell_params psql_db
    db_name,
      db_user,
      db_password,
      db_host,
      reserved = shell_params_psql_db
      psql_command = "PGPASSWORD=#{db_password} psql  -h #{db_host} -U #{db_user} #{db_name} "
  end


end


=begin
  The purpose of this module is to offer functions that can
  execute commands available in the command line shell where
  ruby is running.
=end
module RubyRooomyShellCommandsModule

   include RubyRooomyPgShellCommandsModule

=begin
  executes a command in a shell, storing
  results, timestamp, command, args, return value,
  and output (stdout joined with stderr) in the
  last entry of the class variable @results
=end
  def batch_command call, *args
    require "open3"
    @results ||= []
    command = "#{call} #{args.join " "}"
    stdin, stdoutanderr, wait_thr =  Open3.popen2e(command)
     @results.push({
        :time => Time.now.inspect,
        :call => call,
        :args => args,
        :command => command,
        :success => wait_thr.value.success?,
        :output => (stdoutanderr.entries.join "\n")
      })
  end


=begin
 like #batch_command, but takes an Array having call, *args
 pairs, called a "batch of commands"
  executes multiple commands in a shell, storing
  timestamp, command, args, return value,
  and output (stdout joined with stderr) in the
  last entries of the class variable @results

  returns only the part of @results that corresponds to the
  commands executed during its execution.
=end
  def batch_commands batch
    results_before = results.dup
    batch.map { |call, *args|
      batch_command call, *args
    }
    results  - results_before
  end


=begin
  resets class variable @results
=end
    def results_reset
      @results = []
    end


=begin
  returns class variable @results
=end
  def results
    @results ||= []
  end


=begin
  returns class variable @results.last[:output]
=end
  def last_result_output
    @results ||= []
    @results.last[:output]
  end


=begin
  calls a function on self object, and store
  a report with timestamp, call, args and return
  value.
  returns class variable @results
=end
  def do call, *args
    @results ||= []
    @results.push({
       :time => Time.now,
       :call => call,
       :args => args,
       :output => (self.send call, *args),
    })
    @results
  end


=begin
  recursively escapes all objects in an Array using
  Shellwords.escape
=end
  def recursive_array__shell_escaped a
    a_is_container = a.respond_to? :each
    a_is_container && a.map{|e|
      recursive_array__shell_escaped e
    } || (Shellwords.escape a)
  end


=begin
  quote a string
=end
  def quoted_shell_param s
    "\"#{s}\""
  end


end


=begin
  functions in this module get always a list of hashes
  as parameter. Each of those hashes represents a row
  from a table.
  These structures are suitable to work with any "table".

  having these columns:
  ID NAME MEMBERS

  that MEMBERS field is supposed to be another array
  of hashes, having (at least) the ID field.
=end
module RubyRooomyArrayOfHashesModule
  # select only "name"  == name, retrieving only the id
  def  id h, name
   h.map  {|h1| (h1["name"]  == name ) && h1["id"] || nil }.compact.first
  end

  # select the ids of members of given id
  def member_ids h, id
    h.map  {|h1| (h1["id"]  == id ) && h1["members"].map{|h2| h2["id"] } || nil }.compact.flatten
  end 

  # select the ids of members of given id, recursively (in a Hash).
  # note that the parent id won't be in the hash
  def member_id_tree h, id, dont_visit = Set.new
      id_member_ids = Set.new [(member_ids h, id)].flatten(1)
      dont_visit << id
      visit = (id_member_ids -  dont_visit)
      result = visit.map { |member_id|
         [member_id,( member_id_tree h, member_id, dont_visit ) ]
     }.to_h
    result
  end


  # retrieve, in the array of hashes h, the ones matching k == v
  # used mostly as helper for  select_column_by_kv
  def filter_by_kv h, k, v
    h.map  {|h1| (h1[k]  == v) && h1 || nil }.compact
  end

  # retrieve, in the array of hashes h, the ones having v in values. k is by now ignored, but it may be used in the future (pass nil) 
  # laternote: used only as helper for  select_column_by_kv
  def filter_by_v_in_values h, k, v
    h.map  {|h1| (h1.values.index v) && h1 || nil }.compact
  end


  def filter_by_v_matching_values h, k, v
    h.map  {|h1| (h1.values.grep v).reduce(:+) && h1 || nil }.compact
  end

  # retrieve, in the array of hashes h, the ones matching k == v, selecting only one column
  def  select_column_by_kv  h, k, v, column = nil, method_name = :filter_by_kv
   filtered =  method(method_name).call h, k, v
   column && filtered.map {|h1| h1[column]} || (!column) && filtered
  end


  # call keys for each element of the array h
  #  example: map_to_keys h, :fetch, ["id", "default_id"] fetches all ids
  def map_to_keys h, method_name = :keys, method_args = nil
    h.map {|h1| h1.method(method_name).call  *method_args }
  end

end


module RubyRooomyGitBaseModule

  require 'git'

  class Git::Base

   include RubyRooomyShellCommandsModule

    # note: this differs of pull("origin", operand_branch) because
    # it pulls the +operand_branch+'s origin into itself.
    def pull_on_operand_branch *args
      self.on_operand_branch :pull, *args
    end

    def on_operand_branch operation, operand_branch=nil, repo="origin"
       pop_branch  = self.current_branch
       operand_branch ||= self.current_branch
       results ||= []
       results.push self.branch(operand_branch).checkout
       results.push  self.send(operation, repo, self.current_branch)
       results.push self.branch(pop_branch).checkout
      results.join "\n"
    end


    def do call, *args
      @results ||= []
       @results.push({
          :time => Time.now,
          :call => call,
          :args => args,
          :output => (self.send call, *args),
        })
       self
    end

    def do_on type, object_id, call=nil, *args
      @results ||= []
       @results.push({
          :time => Time.now.inspect,
          :call => type,
          :args => [object_id],
          :output => (p (self.send type, object_id)),
        })
       object = last_result_output
       call && @results.push({
          :time => Time.now.inspect,
          :call => call,
          :args => args,
          :output => (object.send call, *args),
        })
       self
    end

    def extra_command call, *args
      require "open3"
      batch_command call, *args
       self
    end

  end

end


module RubyRooomyDefineContextsModule


  # define_contexts takes as parameter
  # an Array of Hashes having Arrays as values
  # (which we call "basic definition of
  # a test case") and returns an expanded
  # Array of Hashes (which we call "an Array
  # of test contexts"). Each Hash in the
  # latter has the same keys of its source
  # Hash, but instead of the Array as value, it
  # has only one of those values. All the
  # possible combinations will be generated.
  #
  # Probably it's clearer with an example:
  # suppose in a system you want to test
  # if a user role could create another
  # user role.
  #
  # SAMPLE INPUT:
  # [
  #   {
  #     "role" : [role_3, role_4],
  #     "authenticate_as": [role_1, role_2],
  #     "result": ["allowed"],
  #   },
  #   {
  #     "role" : [role_1, role_2, role_3, role_4] - [role_3, role_4],
  #     "authenticate_as": [role_1, role_2],
  #     "result": ["disallowed"],
  #   },
  # ]
  #
  # SAMPLE_OUTPUT:
  # [
  #   {
  #     "role" : role_3,
  #     "authenticate_as": role_1,
  #     "result": "allowed",
  #   },
  #   {
  #     "role" : role_4,
  #     "authenticate_as": role_1,
  #     "result": "allowed",
  #   },
  #   {
  #     "role" : role_3,
  #     "authenticate_as": role_2,
  #     "result": "allowed",
  #   },
  #   {
  #     "role" : role_4,
  #     "authenticate_as": role_2,
  #     "result": "allowed",
  #   },
  #   {
  #     "role" : role_1,
  #     "authenticate_as": role_1,
  #     "result": "disallowed",
  #   },
  #   {
  #     "role" : role_2,
  #     "authenticate_as": role_1,
  #     "result": "disallowed",
  #   },
  #   {
  #     "role" : role_1,
  #     "authenticate_as": role_2,
  #     "result": "disallowed",
  #   },
  #   {
  #     "role" : role_2,
  #     "authenticate_as": role_2,
  #     "result": "disallowed",
  #   },
  # ]
  #
  # Note that, if a value has a lambda, it
  # will be executed, giving the "test case"
  # as parameter -- so a key-value inside it
  # can be used to further transform the
  # final "test case"
  def define_contexts context_definitions = [
      {
      },
    ]

    key_sets = context_definitions.map(&:keys)
    test_sets = values_product = context_definitions.map(&:values).map { |values|
      values_in_arrays = values.map(&:to_a)
      (["values:"].product *values_in_arrays).each(&:shift)
    }

    rv = test_sets.each_with_index.map { |test_set, context_definition_i|
      test_set.each_with_index.map { |test, test_i|
        test.each_with_index.map { |value, value_i|
          key_i = value_i
          [ key_sets[context_definition_i][key_i], value ]
        }.to_h
      }
    }.flatten.map{ |test_hash| # execute lambdas, and we're done:
      test_hash.map{ |k, v|
        [ k, (v.call test_hash rescue v) ] # better would be rescue only NoMethodError
      }.to_h
    }

    rv
  end

  ## SAMPLE EXAMPLES section: functions here below are provided as sample
  # usage examples for the functions above.

  # example for sample_example__define_contexts
  # experiment with:
  # ./rubyrooomy.rb  invoke_double puts sample_example__define_contexts
  def sample_example__define_contexts
    define_contexts [
      {
        "role" => ["role_3", "role_4"],
        "authenticate_as"=> ["role_1", "role_2"],
        "result"=> [
          Proc.new { |h|
            "#{h["authenticate_as"]} ALLOWED to create #{h["role"]}"
          }
        ],
      },
      {
        "role" => ["role_1", "role_2", "role_3", "role_4"] - ["role_3", "role_4"],
        "authenticate_as"=> ["role_1", "role_2"],
        "result"=> [
          Proc.new { |h|
            "#{h["authenticate_as"]} NOT ALLOWED to create #{h["role"]}"
          }
        ],
      },
    ]
  end


end

module RubyRooomyGemModule


  require "rubyment"
  # to benefit from the RubyGem functions
  #  support and other helper functions:
  include RubymentModule

  # overrides Rubyment::rubyment_gem_defaults
  # in order to enable a gem for RubyRooomy
  # to be built instead.
  def rubyment_gem_defaults args=ARGV
    running_dir   = @memory[:running_dir]
    basic_version = @memory[:basic_version]
    major_version = @memory[:major_version]

    gem_name,
    gem_version,
    gem_dir,
    gem_ext,
    gem_hifen,
    gem_date,
    gem_summary,
    gem_description,
    gem_authors,
    gem_email,
    gem_files,
    gem_homepage,
    gem_license,
    gem_validate_class,
    gem_validate_class_args,
    gem_validate_class_method,
    gem_is_current_file,
    gem_bin_generate,
    gem_bin_contents,
    gem_bin_executables,
    reserved = args


    gem_name ||= "rubyrooomy"
    gem_version ||= (version [])
    gem_dir ||= running_dir
    gem_ext ||= ".gem"
    gem_hifen ||= "-"
    gem_ext ||= "date"
    gem_date ||= "2018-07-13"
    gem_summary     ||= "roOomy open tools for Ruby"
    gem_description ||= "a set of ruby helpers we use mostly in the backend testing environment of roOomy"
    gem_authors     ||= ["roOomy backend development team", "Ribamar Santarosa"]
    gem_email       ||= 'ribamar.santarosa@rooomy.com'
    gem_files       ||= ["lib/#{gem_name}.rb"]
    gem_homepage    ||=
      "http://rubygems.org/gems/#{gem_name}"
    gem_license     ||= 'MIT'
    gem_validate_class ||= self.class.to_s
    gem_validate_class_args ||= {:invoke => ["puts", "rubyrooomy gem installation validated"] }
    gem_validate_class_method ||= "new"
    gem_is_current_file = __FILE__ # this enables the possibility of building
    #  a gem for the calling file itself, but be aware that lib/gem_file.rb
    # is supposed to be overriden later.
    gem_bin_generate = "bin/#{gem_name}" # generate a bin file
    gem_bin_contents =<<-ENDHEREDOC
#!/usr/bin/env ruby
require '#{gem_name}'
#{gem_validate_class}.new({:invoke => ARGV})
    ENDHEREDOC
    gem_executables = [ gem_bin_generate && "#{gem_name}" ]

    [
       gem_name,
       gem_version,
       gem_dir,
       gem_ext,
       gem_hifen,
       gem_date,
       gem_summary,
       gem_description,
       gem_authors,
       gem_email,
       gem_files,
       gem_homepage,
       gem_license,
       gem_validate_class,
       gem_validate_class_args,
       gem_validate_class_method,
       gem_is_current_file,
       gem_bin_generate,
       gem_bin_contents,
       gem_bin_executables,
   ]
  end


end


# Main module, basically a namespace
# for RubyRooomy (not a module for
# making serialization easier if ever
# needed).
module RubyRooomyModule

  include RubyRooomyShellCommandsModule

  include RubyRooomyGemModule

  include RubyRooomyDefineContextsModule

  include RubyRooomyGitBaseModule

  include RubyRooomyArrayOfHashesModule

end


# Main class, basically a namespace
# for RubyRooomy (not a module for
# making serialization easier if ever
# needed).
class RubyRooomy
  include RubyRooomyModule
end


(__FILE__ == $0) && RubyRooomy.new({:invoke => ARGV})


