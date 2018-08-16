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
  manipulate json structures.
=end
module RubyRooomyJsonModule


=begin
  returns a hash or a string having json contents
=end
  def json_string__pretty hash_or_json_string
    require 'json'
    json_hash = (!hash_or_json_string.is_a?(Hash)) && (
      JSON.load hash_or_json_string
      ) || hash_or_json_string
    JSON.pretty_generate json_hash
  end


=begin
  prints a hash or a string having json contents
=end
  def puts__json_pretty *args
    puts json_string__pretty *args
  end


end


=begin
  The purpose of this module is to offer functions that can
  execute file system related commands in the command line
  shell where ruby is running, like copying a file from aws,
  or from another remote location.
=end
module RubyRooomyFsShellCommandsModule


=begin
  defines a #aws_s3_batch__ that fetches a file or a directory
  from an aws s3 bucket, given a #aws_s3_path__ definition
=end
  def aws_s3_batch__fetch_file *args
    aws_s3_path,
      local_path,
      reserved = args

    s3_bucket,
      s3_region,
      s3_path,
      s3_path_is_dir,
      s3_exclude_pattern,
      s3_include_pattern,
      reserved = aws_s3_path

    batch = [
      [
        "aws s3",
        s3_region && "--region #{s3_region}" || "",
        "cp",
        "s3://#{s3_bucket}/#{s3_path}",
        "#{local_path}",
        s3_path_is_dir && "--recursive" || "",
        s3_exclude_pattern && "--exclude \"#{s3_exclude_pattern}\"" || "",
        s3_include_pattern && "--include \"#{s3_include_pattern}\"" || "",
      ],
    ]
  end


=begin
   defines a sample #aws_s3_path__ having a file (not dir)
=end
  def aws_s3_path__sample_file
    s3_bucket = "bucket_name"
    s3_region = nil
    s3_path = "path_to_file/file"
    s3_path_is_dir = false
    s3_exclude_pattern = nil
    s3_include_pattern = nil
    [
      s3_bucket,
      s3_region,
      s3_path,
      s3_path_is_dir,
      s3_exclude_pattern,
      s3_include_pattern,
    ]
  end


=begin
   defines a sample #aws_s3_path__ having a dir
=end
  def aws_s3_path__sample_dir
    s3_bucket = "bucket_name"
    s3_region = nil
    s3_path = "path_to_dir/dir"
    s3_path_is_dir = true
    s3_exclude_pattern = nil
    s3_include_pattern = nil
    [
      s3_bucket,
      s3_region,
      s3_path,
      s3_path_is_dir,
      s3_exclude_pattern,
      s3_include_pattern,
    ]
  end


=begin
 batch to fetch a file from an #aws_s3_path definition to
 a local path. lists the path before and to validate the success
=end
  def fs_batch__fetch_from_aws_s3_to_local *args
    aws_s3_path,
      local_path,
      local_path_is_dir,
      reserved = args

    aws_s3_batch = aws_s3_batch__fetch_file aws_s3_path, local_path

    batch = [
      (local_path_is_dir && ["mkdir", "-p", "#{local_path}" ] || nil),
      ["ls", "-lh", "#{local_path}" ]
    ] +
    aws_s3_batch + [
      ["ls", "-lh", "#{local_path}" ]
    ]

    batch.compact
  end


end


=begin 
  The purpose of this module is to offer functions that generates
  or are used to generate sql queries.

=end
module RubyRooomySqlQueriesModule


=begin
 Standard SQL way of listing all tables in a database
=end
  def db_query__show_tables *args

    db_query = " SELECT
        table_schema || '.' || table_name
    FROM
        information_schema.tables
    WHERE
        table_type = 'BASE TABLE'
    AND
        table_schema NOT IN ('pg_catalog', 'information_schema')"
  end


=begin
  transforms a given query, in a way that the whole query will
  be transformed into a new temporary table called "resultset_table" by
  default (configurable via tmp_table).
=end
  def db_query_transform__subquery query, tmp_table="resultset_table"
    "(#{query}) as #{tmp_table}"
  end


=begin
  transforms a query into a query that shows the count of that query.
  check #db_query__show_tables__count for an example on how a
  table listing is transformed into a count of tables listed.
=end
  def db_query_transform__count query
    tmp_table = "resultset_table"
    make_tmp_table = db_query_transform__subquery query, tmp_table
    "SELECT COUNT(*) FROM #{make_tmp_table}"
  end


=begin
  a query for listing tables is transformed into a count of tables listed,
  and then returned.
=end
  def db_query__show_tables__count
    db_query_transform__count db_query__show_tables
  end


=begin
  returns a query that drops all the tables owned by the
  current user.
=end
  def db_query__drop_owned_current_user *args
      db_query = "DROP OWNED BY CURRENT_USER CASCADE "
  end


=begin
  returns a query list that counts the tables in a database,
  drops all the tables owned by the current user,
  and then counts those tables again, for validation.
=end
  def db_queries__drop_owned_current_user *args
    db_queries = [
      db_query__show_tables__count,
      db_query__drop_owned_current_user,
      db_query__show_tables__count,
    ]
  end


=begin
  returns for a given #psql_db definition, a batch having a
  query list that counts the tables
  in a database, drops all the tables owned by the current user,
  and then counts those tables again, for validation.
=end
  def psql_db_batch__db_queries_method psql_db, db_queries_method
    db_queries = (send db_queries_method) rescue db_queries_method
    batch = psql_db_batch__cli_or_queries psql_db, db_queries
  end


=begin
  just a sample example for psql_db_batch__db_queries_method
=end
  def psql_db_batch__drop_owned_current_user psql_db
    batch = psql_db_batch__db_queries_method psql_db, :db_queries__drop_owned_current_user
  end


end


=begin
  The purpose of this module is to offer functions that can
  execute postgresql commands in the command line shell where
  ruby is running, like psql, pg_dump, pg_restore.
=end
module RubyRooomyPgShellCommandsModule

  include RubyRooomySqlQueriesModule

=begin
  Generates a psql command to connect to a database,
  given a psql_db definition, which is an array having
  [db_name, db_user, db_password, db_host]
=end
  def psql_db_command__cli psql_db
   psql_db_command__program "psql", psql_db
  end


=begin
 generates a batch of psql commads, for each given db_query.
 if a db_query is nil, will generate a command to enter the
 cli of psql.
=end
  def psql_db_batch__cli_or_queries psql_db, db_queries=[nil]
    batch = db_queries.map { |db_query|
      cli = psql_db_command__cli psql_db
      [cli, db_query && "-c #{quoted_shell_param db_query}"]
    }
  end


=begin
 executes a batch of psql commads, for each given db_query.
 if a db_query is nil, will generate a command to enter the
 cli of psql.
=end
  def exec__psql_cli_or_db_queries psql_db, db_queries=[nil]
    batch = psql_db_batch__cli_or_queries psql_db, db_queries
    batch_commands batch
  end


=begin
  just a sample example of a psql_db, as required by
  :psql_db_command__cli
=end
  def psql_db__sample_example *args
    db_name="any_db"
    db_user="any_user"
    db_host="localhost"
    db_password="onlyNSAknows"
    [db_name, db_user, db_password, db_host]
  end


=begin
  just a sample example that executes the batch generated by
  #psql_db_batch__drop_owned_current_user, against the
  database defined by #psql_db__sample_example
=end
  def exec__psql_db_batch__drop_owned_current_user *args
    psql_db = psql_db__sample_example
    drop_all_batch = psql_db_batch__db_queries_method psql_db, :db_queries__drop_owned_current_user
    batch = drop_all_batch
    batch_commands batch
  end


=begin
 generates a batch of psql commads with "-f" option, for
 each given db_dump_path.
 if a db_dump_path is nil, will generate a command to enter the
 cli of psql.
=end
  def psql_db_batch__cli_or_apply_dumps psql_db, db_dump_paths=[nil], options=""
    batch = db_dump_paths.map { |db_dump_path|
      cli = psql_db_command__cli psql_db
      [cli, db_dump_path && " #{options} -f #{quoted_shell_param db_dump_path}"]
    }
  end


=begin
  just a sample example of a #db_dumps__ definition, as required by
  #psql_db_batch__cli_or_apply_dumps
=end
  def db_dumps__sample_example *args
    [
      "install/10.0_to_10.1.sql",
      "/root/hack_10.0_to_10.1.sql",
    ]

  end


=begin
  just a sample example that executes the batch generated by
  #psql_db_batch__cli_or_apply_dumps, against the
  database defined by #psql_db__sample_example
  does not stop for errors.
=end
  def exec__psql_db_batch__cli_or_apply_dumps *args
    psql_db = psql_db__sample_example
    db_dumps = db_dumps__sample_example
    batch = psql_db_batch__cli_or_apply_dumps psql_db, db_dumps, "ON_ERROR_STOP=off"
    batch_commands batch
  end


=begin
  a sample example of #psql_db_batch_generator__, that can be used
  to create a #psql_db_batch__ definition equivalent of the one
  executed by #exec__psql_db_batch__cli_or_apply_dumps
=end
  def psql_db_batch_generator__sample_example
    [
      :psql_db_batch__cli_or_apply_dumps,
      psql_db__sample_example,
      db_dumps__sample_example,
      "ON_ERROR_STOP=off"
    ]
  end


=begin
  Generates a psql command to connect to a database,
  given a psql_command (psql or pg_dump, ... ) and
  a #psql_db__ definition, which is an array having
  [db_name, db_user, db_password, db_host]
=end
  def psql_db_command__program psql_program, psql_db
    shell_params_psql_db = quoted_shell_params psql_db
    db_name,
      db_user,
      db_password,
      db_host,
      reserved = shell_params_psql_db

    psql_command = "PGPASSWORD=#{db_password} #{psql_program} -h #{db_host} -U #{db_user} #{db_name} "
  end


=begin
  Generates a pg_dump command to connect to a database,
  given a psql_db definition, which is an array having
  [db_name, db_user, db_password, db_host]
=end
  def psql_db_command__dump psql_db
   psql_db_command__program "pg_dump", psql_db
  end


=begin
 generates a batch of pg_dump commads with "-f" option, for
 each given db_dump_path.
 if a db_dump_path is nil, will generate a command to enter the
 cli of psql.
=end
  def psql_db_batch__cli_or_generate_dumps psql_db, db_dump_paths=[nil], options=""
    batch = db_dump_paths.map { |db_dump_path|
      cli = psql_db_command__cli psql_db
      pg_dump = psql_db_command__dump psql_db
      program = db_dump_path && pg_dump || cli
      [program, db_dump_path && " #{options} -f #{quoted_shell_param db_dump_path}"]
    }
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


=begin
  quote a list of strings
=end
  def quoted_shell_params args
    args.map(&method(:quoted_shell_param))
  end


=begin
  escapes all arguments, recursively with Shellwords.escape,
  before executing a function
=end
  def shell_escaped__send method_name, *args_to_method
    escaped_args_to_method = recursive_array__shell_escaped a
    send method_name, *escaped_args_to_method
  end


=begin
  escapes all arguments, recursively with Shellwords.escape,
  before executing #batch_command
=end
  def shell_escaped__batch_command method_name, *args_to_method
    method_name = :batch_command
    shell_escaped__send method_name, args_to_method
  end


=begin
  escapes all arguments, recursively with Shellwords.escape,
  before executing #batch_command
=end
  def shell_escaped__batch_commands method_name, *args_to_method
    method_name = :batch_commands
    shell_escaped__send method_name, args_to_method
  end


=begin
   execs a #batch_generator__ definition
=end
  def exec__batch_generator batch_generator
    send_args = (send batch_generator) rescue  batch_generator
    batch = send *send_args
    batch_commands batch
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


