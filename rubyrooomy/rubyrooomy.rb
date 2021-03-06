#!/usr/bin/env ruby


# Copyright 2018, NedSense Loft BV
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.




=begin
  The purpose of this module is to offer
  functions that serves mostly to implement
  common designs/code style of this project.
=end
module RubyRooomyMetaModule


=begin
  transforms a definition into an Array.
  tests if a definition is defined
  by a method, and call it (if not a method from
  Kernel). otherwise, just
  returns whatever definition inside an Array
  (since the only two ways of
  creating a definition is implementing
  an array or a method), but this can
  be extended.
  If definition was already an Array, ensure
  that dimensions aren't changed.
=end
  def array__from definition
    kernel_method = (Kernel.respond_to? definition) rescue nil
    kernel_method && (
      a = definition
    )  || (!kernel_method)  && (
      a = (send definition rescue definition)
    )
    [ a ].flatten 1
  end


=begin
  Merge two given definitions into one, ie,
  given two arrays, preserves the first one,
  filling the indexes having nil values with
  the corresponding index from the second one.

  This merge is not recursive.

  Example:

  # defining a port for psql_db__sample_example:
  definition__merge_simple "psql_db__sample_example", [nil, nil, nil, nil, "5433"]
  # => ["any_db", "any_user", "onlyNSAknows", "localhost", "5433", nil]

  definition__merge_simple  [ nil, "another_user" ],  "psql_db__sample_example"
  # => ["any_db", "another_user", "onlyNSAknows", "localhost", nil, nil]


=end
  def definition__merge_simple definition1, definition2
    definition1 = array__from definition1
    definition2 = array__from definition2
    arrays__zip(definition1, definition2).map { |a|
        a.reduce "nne"
    }

  end


end # of RubyRooomyMetaModule


=begin 
  The purpose of this module is to offer functions that can
  generate or help generating SQL queries
=end
module RubyRooomySQLModule


=begin
  generates a #db_query_select__ (a String having a SQL select
  query) out of a #db_query_select_generator, a definitions
  that allows some elements of the select query to be given;
  check examples.

  examples:

    db_query_select__from [ "table" ]
    db_query_select__from [ "table", "c1" ]
    db_query_select__from [ "table", ["c1", "c2"] ]
    db_query_select__from [ "table", ["c1,c2"] ]
    db_query_select__from [ "table", ["c1,c2"], db_queries_where__samples[0] ]
    db_query_select__from [ "table", ["c1,c2"], [[["field", "'value'"], "<"]]  ]
=end
   def db_query_select__from db_query_select_generator
     db_query_generator = array__from(
       db_query_select_generator
     )
    table,
      columns,
      where_generator = db_query_generator
    table = (array__from table).first
    columns ||= "*"
    columns = array__from columns
    columns = columns.join(",")
    where_clause = db_query_where__from where_generator
    "SELECT #{columns} FROM #{table} #{where_clause}"
  end


=begin
 sample #db_queries_table__ (ie, samples of
 #db_query_table__ definition)
=end
  def db_queries_table__samples
   [
     "table1",
     "table2"
   ]
  end


=begin
 sample #db_queries_operate__ (ie, samples of
 #db_query_operate___ definition)
=end
  def db_queries_operate__samples_non_recursive
    [
      [ ["A", "B"],  nil ],
      [ ["A", "B"],  "<" ],
      [ ["A", "B"], "OR" ],
    ]

  end


=begin
 sample #db_queries_operate definition (ie, samples of
 ##db_query_operate___ definition). Here, rescursive
 versions were defined.
=end
  def db_queries_operate__samples_recursive
    non_rec = db_queries_operate__samples_non_recursive
    sample_1 = [ non_rec, "AND", :recursive ]
    sample_2 = [ ["E", sample_1], "OR", :recursive ]
    r = [
      sample_1,
      sample_2,
    ]

  end


=begin
 sample #db_queries_operate definition (ie, samples of
 #db_query_operate___ definition). Here, both
 rescursive and non rescursive versions were defined.
=end
  def db_queries_operate__samples
    db_queries_operate__samples_non_recursive +
    db_queries_operate__samples_recursive
  end


=begin
 generates a #db_query_operate__ definition, which is
 a SQL clause (not a full query). This clause can be used
 as part of the WHERE clause, eg, to define the condition
 of the query. Check examples.

 examples:
   db_query_operate__from [["A", "B"]]
   db_query_operate__from [["A", "B"], "="]
   db_query_operate__from [["A", "B"], "<"]
   db_query_operate__from [["A", "B"], "AND", :recursive]
   db_query_operate__from [[ [["C", "D"], ">"]   , "B"], "AND", :recursive]
   db_query_operate__from db_queries_operate__samples[0]
   db_query_operate__from db_queries_operate__samples_recursive[0]
   db_query_operate__from db_queries_operate__samples_non_recursive[0]
   db_queries_operate__samples.map {|g| db_query_operate__from g}
=end
  def db_query_operate__from db_query_operate_generator
    db_query_operate_generator = array__from(
      db_query_operate_generator
    )
    operands,
      operation,
      recursive = db_query_operate_generator
    operands = array__from(operands).map { |o|
      recursive && (
        [
          "(",
          db_query_operate__from(o),
          ")"
        ].join
      ) || (
          array__from(o).first
      )
    }.flatten(1)
    operation = array__from(operation).first
    operation ||= "="
    operations = operands.join(" #{operation} ")
    "#{operations}"
  end


=begin
 sample #db_queries_where definition (ie, samples of
 #db_query_where__ definition). Any array having
 a #db_query_operate___ definition as first and unique
 element is a #db_query_where__ definition.
=end
  def db_queries_where__samples
    db_queries_operate__samples.map { |e| [e] }
  end


=begin
 generates a #db_query_where__ definition, which is
 a SQL clause (not a full query). This clause can be used
 as  the WHERE clause, eg, to define the condition
 of the query. Check examples.

 examples:
   db_query_where__from [[["A", "B"]]]
   db_query_where__from [[["A", "B"], "="]]
   db_query_where__from [[["A", "B"], "<"]]
   db_query_where__from [[["A", "B"], "AND", :recursive]]
   db_query_where__from [[[ [["C", "D"], ">"]   , "B"], "AND", :recursive]]
   db_query_where__from db_queries_where__samples[0]
   db_queries_where__samples.map {|g| db_query_where__from g }
=end
  def db_query_where__from db_query_where_generator
    db_query_where_generator = array__from(
      db_query_where_generator
    )
    condition = array__from(db_query_where_generator).first
    condition = db_query_operate__from condition
    condition.nne && "WHERE #{condition} " || ""
  end


=begin
 sample #db_queries_update_generator__ definition
 (ie, samples of #db_query_update_generator__ definition).
=end
  def db_queries_update_generator__samples
    sample_1 = [
      "table_sample",
      [
        ["A", "B"], nil  # set A = B
      ],
      [
        [["C", "D"], "<"] # where C < D
      ]
    ]
    other_samples = db_queries_table__samples.product(
      [db_queries_operate__samples[0]], # only A = B operation makes sense
      db_queries_where__samples,
    )
    [sample_1] + other_samples
  end


=begin
  generates a #db_query_update__ (a String having a SQL select
  query) out of a #db_query_update_generator, a definitions
  that allows some elements of the select query to be given;
  check examples.

 examples:
  db_query_update__from ["table_sample", [["A", "B"], nil]]
  db_query_update__from ["table_sample", [["A", "B"], nil], [[["C", "D"], "<"]]]
  db_query_update__from db_queries_update_generator__samples[0]
  db_queries_update_generator__samples.map{|g| db_query_update__from g}
=end
  def db_query_update__from db_query_update_generator
    db_query_update_generator = array__from(
      db_query_update_generator
    )
    table,
      field_operation,
      where_clause = db_query_update_generator
    table = (array__from table).first
    field_operation = db_query_operate__from field_operation
    where_clause = db_query_where__from where_clause
    "UPDATE #{table} SET #{field_operation} #{where_clause} "
  end


end


=begin 
  This module is defined below, but referred
  by the next module -- so it must be already defined.
=end
module RubyRooomyArrayOfHashesModule
end


=begin
  The purpose of this module is to offer functions that can
  simplify the use of the gem 'pg'
=end
module RubyRooomyPgGemModule


  require 'pg'
  include RubyRooomyArrayOfHashesModule

=begin
 defines a #pg_gem_conn__ definition from a
 #psql_db__ definition.
 A #pg_gem_conn__ is a #psql_db__ but having
 the 5th element set as the object returned
 by PG::Connection.open() (if still not set)
=end
  def pg_gem_conn__from psql_db
    db_name,
      db_user,
      db_password,
      db_host,
      db_port,
      db_connection = array__from psql_db

    db_port ||= 5432

    require 'socket'
    db_connection ||= PG::Connection.open(
      :hostaddr => (IPSocket.getaddress db_host),
      :port=> db_port,
      :dbname=> db_name,
      :user=> db_user,
      :password => db_password,
    ) rescue nil
    [
      db_name,
      db_user,
      db_password,
      db_host,
      db_port,
      db_connection,
    ]
  end


=begin
  executes a command by sending the command via
  a function of a object ("exec" by default, since
  the expected object is a PG::Connection), storing
  results, timestamp, command, args, return value,
  and output (stdout joined with stderr) in the
  last entry of the class variable @results
=end
  def batch_command__pg_gem call, *args
    @results ||= []
    call = array__from call
    call = call.first
    exec_method ||= "exec"
    command = args.join " "
    exec_rv, exception = begin
      e = !(call.respond_to? exec_method) && NoMethodError.new("undefined method `#{exec_method}' for #{call.class}")
      (e && [nil, e] || [(call.send exec_method, command), nil])
      rescue => e2
      [nil, e2]
      end
    exec_rv_entries = exec_rv.entries rescue exec_rv
    exception_info = (exception_info_base [exception]) rescue []
    @results.push({
        :time => Time.now.inspect,
        :call => call,
        :args => args,
        :command => command,
        :success => exception_info[2].negate_me,
        :output => exec_rv_entries,
        :batch_command_method => "batch_command__pg_gem",
        :exception_info => exception_info,
      })
    @results
  end


=begin
 Generates a #pg_gem_batch__ definition, out of a #psql_db__ and
 a #db_queries (or #db_query_) definition.

 Can be given to #exec__batch, provided that the #batch_controller__
 argument has  batch_command__pg_gem set as second argument (which
 is not the default case); for example:
 exec__batch pg_gem_batch, batch_controller__pg_gem_stop_default

 Alternatively can be given as the first element of the array given
 to #pg_gem_exec__from

 examples:
   pg_gem_batch__from(psql_db__sample_example,  (db_query_select__from ["table"]))
   pg_gem_batch__from(psql_db__sample_example,  db_queries__drop_owned_current_user)
   pg_gem_exec__from [ pg_gem_batch__from(psql_db__sample_example,  (db_query_select__from ["table"]))]
   results__select_key_output pg_gem_exec__from [ pg_gem_batch__from(psql_db__sample_example,  (db_query_select__from ["table"]))]

=end
  def pg_gem_batch__from  psql_db, db_queries
    psql_db = array__from psql_db
    db_queries = array__from db_queries
    pg_gem_conn = pg_gem_conn__from psql_db
    pg_connection = pg_gem_conn[5]
    batch = [pg_connection].product db_queries
  end


=begin
 generates a #exec__ definition (ie, an array of hashes
 containing information about how went the execution of
 commands) out of a #exec_plan, which has a #pg_gem_batch
 definition as a first element and a #batch_controller
 as second).

 example:
   pg_gem_exec__from [ pg_gem_batch__from(psql_db__sample_example,  (db_query_select__from ["table"])) ]
=end
  def pg_gem_exec__from pg_gem_exec_plan
    batch,
      batch_controller = array__from(pg_gem_exec_plan)
    batch_controller = array__from(batch_controller)
    batch_controller[1] =  batch_controller__pg_gem_default[1]
    exec__from [
      batch,
      batch_controller
    ]
  end


=begin
  generates a #pg_gem_result_sets__ , ie, an array of array representing
  the result sets after executing  #db_queries against #psql_db (the
  same results can be obtained by giving a #pg_gem_exec__ definition
  to #results__select_key_output).

  examples
    pg_gem_result_sets__from psql_db__sample_example, [db_query__show_tables]
=end
  def pg_gem_result_sets__from psql_db, db_queries, batch_controller=nil
    results__select_key_output pg_gem_exec__from [
      pg_gem_batch__from(
        psql_db,
        db_queries,
      ),
      batch_controller
    ]
  end


end


=begin
  The purpose of this module is to offer functions that can
  provide functions to manipulate the file system
=end
module RubyRooomyFilesModule


=begin
 Generates a #file_modifications definition out of a
 #file_modifications_plan one. Actually execs the
 planned modifications.

 A #file_modifications_plan is an array of
 #file_modification_plan. A #file_modification_plan
 has at least two elements: the first, being the file
 path to the file, and the second, the string to
 be appended to that file.
 A #file_modifications is an array of #file_modification.
 A #file_modification is an array with at least 4 elements,
 being the 3 initials one just like a #file_modification_plan,
 and the 4th, the number of files written after the
 modification.


 examples:
   file_modifications__from [[ "/tmp/my_file", "add this text" ]]
   file_modifications__from file_modifications_plan__sample
=end
  def file_modifications__from file_modifications_plan
    require 'fileutils'
    file_modifications_plan.map{|file_modification_plan|
      file,
        file_addition = array__from(file_modification_plan)
      FileUtils.mkdir_p File.dirname file
      bytes_written = File.write(
        file,
        file_addition,
        mode: "a"
      )
      [
        file,
        file_addition,
        nil,
        bytes_written,
      ]
    }
  end


=begin
 give it to #file_modifications__from
=end
  def file_modifications_plan__sample
    timestamp = time__now_strftime_default
    [
      [  # first modification:
        "/tmp/file_modifications_plan__sample.#{timestamp}",
        "Adding timestamp=#{timestamp}\n"
      ],
    ]
  end


end


=begin 
  The purpose of this module is to offer functions that can
  provide common regexes and other common string manipulation
  functions
=end
module RubyRooomyStringsModule


=begin
  regex that can be used to scan for UUID (v4) in strings
=end
  def regex__uuid_v4
    /[a-f0-9]{8}-[a-f0-9]{4}-4[a-f0-9]{3}-[89aAbB][a-f0-9]{3}-[a-f0-9]{12}/
  end


=begin
  Returns a string having the number of seconds after
  some time in the beginning of 2019.

  Good for generating non critical sequencial IDs,
  for operations that do not occur so often, like
  the dumping of a database.

  Surely, as the time passes, this won't be small
  again, but it's going to take more than 10 years
  for it to have more than 10 digits.
=end
  def string__small_sn_2019 *args
    (1548260387 - Time.now.to_i).abs.to_s
  end


end # of RubyRooomyStringsModule


=begin
  The purpose of this module is to offer functions that can
  manipulate json structures.
=end
module RubyRooomyJsonModule


=begin
  returns a string having json contents, from a string having json
  contents or a structure known to be convertible to JSON.
=end
  def json_string__pretty hash_or_json_string
    require 'json'
    try_to_generate = begin
      [(JSON.pretty_generate hash_or_json_string), nil]
    rescue => e
      [nil, e]
    end

    return try_to_generate.first unless try_to_generate.last

    try_to_generate_2 = begin
      [(JSON.pretty_generate JSON.load hash_or_json_string), nil]
    rescue => e
      # raise the first exception instead
      raise try_to_generate.last
      [nil, e]
    end
    try_to_generate_2.first
  end


=begin
  prints a hash or a string having json contents
=end
  def puts__json_pretty args
    args = containerize args
    puts json_string__pretty *args
  end


end # of RubyRooomyJsonModule


=begin
  The purpose of this module is to offer functions
  that are simply shortcuts to commonly called calls.
=end
module RubyRooomyShortcutsModule


=begin
  Instead of
  invoke_double puts definition

  Just:
  shortcut_print_definition definition


  Examples:

  # it's good mostly to definitions returning formatted data, like JSON:
  shortcut_print_definition ["json_string__pretty", '{"1" : "2"}']
  {
    "1": "2"
  }


  # but it may not be the best to use with Arrays:
  shortcut_print_definition ["psql_db__sample_example"]
  any_db
  any_user
  onlyNSAknows
  localhost


  # in the command line, the same results are achieved with:
  rubyrooomy shortcut_print_definition  json_string__pretty '{"1" : "2"}'
  rubyrooomy shortcut_print_definition psql_db__sample_example


=end
  def shortcut_print_definition args
    result = invoke__basic_sender_array [ self, *args ]
    stdout_puts(result)
  end # of shortcut_print_definition


=begin
  Instead of
  invoke_double p definition

  Just:
  shortcut_show_definition definition


  Examples:

  # it may be not so good to definitions returning formatted data, like JSON:
  shortcut_show_definition [ "json_string__pretty", '{"1" : "2"}' ]
  "{\n  \"1\": \"2\"\n}"


  # but it works well with definitions returning Arrays:
  shortcut_show_definition [ "psql_db__sample_example" ]
  ["any_db", "any_user", "onlyNSAknows", "localhost", nil, nil]

  # in the command line, the same results can be achieved with:
  rubyrooomy shortcut_show_definition  json_string__pretty '{"1" : "2"}'
  rubyrooomy shortcut_show_definition  psql_db__sample_example

=end
  def shortcut_show_definition args
    result = invoke__basic_sender_array [ self, *args ]
    stdout_puts(result.inspect)
  end # of shortcut_show_definition


end # of RubyRooomyShortcutsModule


=begin 
  The purpose of this module is to offer functions that can
  execute git related commands and batches in the command line
  shell where ruby is running, like forking a branch
=end
module RubyRooomyGitShellCommandsModule


=begin
  generates a string out of a timestamp that can
  be used as a git branch name
=end
  def git_branch_name__from_timestamp
    Time.now.strftime "%Y.%m.%d_%H.%M.%S"
  end


=begin
  sample #git_comand__ definition, that can be used to
  generate and execute the command git show --raw

  example:

  git_batch__from [ :git_command__show_raw, :git_object_ids__HEAD ]
  git_batch__from [ :git_command__show_raw ]

=end
  def git_command__show_raw
    [
      "show",     # command
      ["--raw"],  # options
    ]
  end


=begin
  sample #git_comand__ definition, that can be used to
  generate and execute the command git show

  example:

  git_batch__from [ :git_command__show, :git_object_ids__HEAD ]
  git_batch__from [ :git_command__show ]

=end
  def git_command__show
    [
      "show",     # command
      [],         # options
    ]
  end


=begin
  sample #git_comand__ definition, that can be used to
  generate and execute the command git cherry-pick

  example:

  git_batch__from [ :git_command__cherry_pick , "sha" ]
  git_batch__from [ :git_command__cherry_pick, :git_object_ids__HEAD ]

=end
  def git_command__cherry_pick
    [
      "cherry-pick",     # command
      [],                # options
    ]
  end


=begin
  sample #git_comand__ definition, that can be used to
  generate and execute the command git merge branch_name

  example:

  git_batch__from [ :git_command__merge, ["master"] ]
  git_batch__from [ :git_command__merge, "master" ]

=end
  def git_command__merge
    [
      "merge",           # command
      [],                # options
    ]
  end


=begin
  sample #git_comand__ definition
=end
  def git_object_ids__HEAD
    [
      "HEAD~0",     # first object id ...
    ]
  end


=begin
  sample #git_comand__ definition, that can be used to
  generate and execute the command git merge branch_name -X theirs
  (which, in case of conflict, preserve the changes on
  branch_name)

  example:

  git_batch__from [ :git_command__merge_theirs, ["master"] ]
  git_batch__from [ :git_command__merge_theirs, "master" ]

=end
  def git_command__merge_theirs
    [
      "merge",           # command
      ["-X theirs"],     # options
    ]
  end


=begin
  sample #git_comand__ definition, that can be used to
  generate and execute the command git checkout branch_name_or_file

  example:

  git_batch__from [ :git_command__checkout, ["master"] ]
  git_batch__from [ :git_command__checkout, "master" ]

=end
  def git_command__checkout
    [
      "checkout",        # command
      [],                # options
    ]
  end


=begin
  sample #git_comand__ definition, that can be used to
  generate and execute the command git checkout -b branch_name_or_file

  example:

  git_batch__from [ :git_command__checkout_b, ["new_branch"] ]
  git_batch__from [ :git_command__checkout_b, "new_branch" ]

=end
  def git_command__checkout_b
    [
      "checkout",        # command
      ["-b"],            # options
    ]
  end


=begin
  sample #git_comand__ definition, that can be used to
  generate and execute the command git reset --hard sha

  example:

  git_batch__from [ :git_command__reset_hard, ["sha"] ]
  git_batch__from [ :git_command__reset_hard, "sha" ]

=end
  def git_command__reset_hard
    [
      "reset",           # command
      ["--hard"],        # options
    ]
  end


=begin
  sample #git_comand__ definition, that can be used to
  generate and execute the command git reset file_or_sha

  example:

  git_batch__from [ :git_command__reset, ["file"] ]
  git_batch__from [ :git_command__reset, "file" ]
  git_batch__from [ :git_command__reset ]

=end
  def git_command__reset
    [
      "reset",           # command
      [],                # options
    ]
  end


=begin
  sample #git_comand__ definition, that can be used to
  generate and execute the command git branch -d

  example:

  git_batch__from [ :git_command__branch_delete_local, "undesired_branch" ]

=end
  def git_command__branch_delete_local
    [
      "branch",    # command
      ["-d"],      # options
    ]
  end


=begin
  sample #git_comand__ definition, that can be used to
  generate and execute the command git branch -D

  example:

  git_batch__from [ :git_command__branch_delete_force, "undesired_branch" ]

=end
  def git_command__branch_delete_force
    [
      "branch",    # command
      ["-D"],      # options
    ]
  end


=begin
   sample #git_operation__ definition, composed of a
   #git_command__ definition (#git_command__show_raw)
   and a #git_object_ids__ definition (#git_object_ids__HEAD)
   give to #git_batch__ and the result to
   #exec__batch in order  to execute it.

   example:

   git_batch__from git_operation__show_raw_HEAD
   # same as:
   git_batch__from [:git_command__show_raw, :git_object_ids__HEAD ]
=end
  def git_operation__show_raw_HEAD
    [
      git_command__show_raw,
      git_object_ids__HEAD,
    ]
  end


=begin
  generates a #git_batch_generator__ definition
  out of a #git_operation.

  give to #exec__batch_generator in order to execute it,
  or to #batch__from_batch_generator to analyse it.

  example:

  git_batch_generator__from git_operation__show_raw_HEAD
  exec__batch_generator git_batch_generator__from git_operation__show_raw_HEAD
  # only batch:
  batch__from_batch_generator git_batch_generator__from git_operation__show_raw_HEAD
  # same as:
  git_batch__from git_operation__show_raw_HEAD
=end
  def git_batch_generator__from git_operation
    [
      :git_batch__from,
      git_operation,
    ]
  end


=begin
   generates a #git_batch__ definition from
   a #git_operation__ definition, that will
   derive, from its #git_command__ definition,
   a git command (e.g: show, or reset),
   and its options, to be run for a list of object ids
   (like sha, or branch names) defined by its
   #git_object_ids__ definition

   give to #exec__batch to execute it.

   example:

   git_batch__from [["show", ["--raw"] ], ["HEAD~1"]]
   git_batch__from [["show", ["--raw"] ], ]
   git_batch__from :git_operation__show_raw_HEAD
   git_batch__from [ :git_command__show_raw ]
   git_batch__from [ :git_command__show_raw, :git_object_ids__HEAD ]
   git_batch__from [ :git_command__branch_delete_force, "undesired_branch" ]

=end
  def git_batch__from git_operation
    git_operation = array__from git_operation
    git_command, git_object_ids  = git_operation
    git_command = array__from git_command
    git_object_ids = array__from git_object_ids
    git_object_ids = [ git_object_ids ].flatten 1
    git_command_name,
    git_options,
      reserved = git_command
    git_options = [ git_options ].flatten 1
    [
      [ "git", git_command_name, git_options, git_object_ids ].flatten(1),
    ]
  end


=begin
   generates a #git_batch__ definition from
   an array of #git_operation__ definitions.
   check #git_batch__from_

   give to #exec__batch to execute it.

   example:
   git_batch__from_operations [[:git_command__show_raw, :git_object_ids__HEAD ]]

=end
  def git_batch__from_operations git_operations
    git_operations = array__from git_operations

    git_operations.map{ |git_operation|
      git_batch__from git_operation
    }.flatten(1)
  end


=begin
 #git_branch_backup_name_generator__ default definition:
 bk-output_from_git_branch_name__from_timestamp method

 give it to #git_branch_backup_name__from

 example:
 git_branch_backup_name__from git_branch_backup_name_generator__default

=end
  def git_branch_backup_name_generator__default
    [
      "bk",                               # backup prefix
      "-",                                # default infix
      :git_branch_name__from_timestamp,   # default postfixing method
    ]
  end


=begin
 takes a #git_branch_backup_name_generator__ definition and
 generates a #git_branch_backup_name (string which must be a
 valid name for a branch).

 example:
 git_branch_backup_name__from "git_branch_backup_name_generator__default"
 # => "bk-2018.12.27_14.11.39"

 git_branch_backup_name__from ["backup", "-", "git_branch_name__from_timestamp" ]
 # => "backup-2018.12.27_14.11.47"


=end
  def git_branch_backup_name__from git_branch_backup_name_generator
    git_branch_backup_name_generator = array__from git_branch_backup_name_generator
    parts = git_branch_backup_name_generator.map { |part|
      (array__from part).first
    }
    parts.join
  end


=begin
  generates a #git_operations__ definition, a list of
  #git_operation__, by combining the each of the
  #git_command__ (in the #git_commads_ ) given
  with each of the #git_object_id__ (in the
  #git_object_ids) given.

  Examples:

  git_operations__from [:git_command__show ], ["HEAD~1", "HEAD~2"]
  # => [[:git_command__show, "HEAD~1"], [:git_command__show, "HEAD~2"]]

  git_operations__from [:git_command__show, :git_command__cherry_pick], ["HEAD~1", "HEAD~2"]
  # => [[:git_command__show, "HEAD~1"],
  #  [:git_command__cherry_pick, "HEAD~1"],
  #   [:git_command__show, "HEAD~2"],
  #    [:git_command__cherry_pick, "HEAD~2"]]

=end
  def git_operations__from git_comands, git_object_ids
    git_comands = array__from git_comands
    git_object_ids = array__from git_object_ids
    git_object_ids.map { |git_object_id|
      git_object_id = array__from git_object_id
      git_comands.product  git_object_id
    }.flatten(1)
  end


=begin
  gets a #git_base__ definition, which is
  an array having a Git::Base
  for the given dir (pwd by default).
  It's better than Git.open because Git.open requires
  the base directory, while this function will look
  in all directories upwards until .git can be found.

  Examples:

  # if we are in a git repository:
  git_base__from
  # => [#<Git::Base:0x007ff6c2a08a28
  #   @index=
  #    #<Git::Index:0x007ff6c25ce250

  git_base__from (Dir.pwd + "/any/sub/dir")
  # => [#<Git::Base:0x007f6f8b722e58
  #   @index=
  #    #<Git::Index:0x007ff6c25ce254

  # if we are not in a git repository:
  git_base__from "/"
  # => [#<Git::Base:0x007ff6c25fa120
  #   @index=nil,


=end
  def git_base__from dir=nil
    dir ||= Dir.pwd
    paths = (parent_dirs__from dir).reverse
    git_base_object = Git.open paths.find {|p|
      (Git.open "#{p}") rescue nil
    }
    [
      git_base_object,
      dir
    ]
  end


=begin
  generates a #git_branch__ definition from a
  #git_base definition (#git_base__from by default)

  planned improvements:
  currently this function detects only the branch
  name, leaving #git_branch__ incomplete

  examples:

  git_branch__current_from :git_base__from
  # => ["master"]

  git_branch__current_from # assumed :git_base__from
  # => ["master"]

=end
  def git_branch__current_from  git_base=:git_base__from
    git_base = array__from git_base
    [ git_base.first.current_branch ]
  end


=begin
  generates a #git_base_partition__ definition, having these items:
  - git_base, a #git_base__ definition given in the
  #git_base_partition_plan__
  - reserved,
  - splitter_msg, the splitter commit's message
  - git_sha_msg_map_partitions, the actual partitions generated by
  this function

  examples:

  git_base_partition__from git_base_partition__sample
  git_base_partition__from [:git_base__from, nil, "commit msg"]
  git_base_partition__from [:git_base__from ] # assumed [ :git_base__from,  nil, "" ]
  git_base_partition__from # assumed [ :git_base__from,  nil, "" ]

=end
  def git_base_partition__from git_base_partition_plan = nil
    git_base_partition_plan = array__from git_base_partition_plan
    git_base,
      reserved_for_dir,
      splitter_msg = git_base_partition_plan

    git_base ||= :git_base__from
    git_base = array__from git_base
    git_base_object = git_base.first
    splitter_msg ||= ""
    git_sha_msg_map_partitions = git_base_object.partition_log_entries(splitter_msg, nil, [:sha, :message])

    [
      git_base,
      reserved_for_dir,
      splitter_msg,
      git_sha_msg_map_partitions,
    ]

  end


=begin
  generates a #git_base_partition__ definition,
  that can be use to partition a branch (the
  current dir's one in its first element, the
  #git_base__ definition), given its third element
  (string that will be used to match commits' message).

  give it to #git_base_partition__sample

  example:
    git_base_partition__from git_base_partition__sample

=end
  def git_base_partition__sample
    [
      :git_base__from,
      nil,   # reserved for dir
      "commit msg",
    ]
  end


=begin
  same as #git_base_partition__from, but returns only the
  map (the fourth element)

  examples:

  git_sha_msg_map_partitions__from [:git_base__from, nil, "commit msg"]
  git_sha_msg_map_partitions__from [:git_base__from ] # assumed [ :git_base__from,  nil, "" ]
  git_sha_msg_map_partitions__from # assumed [ :git_base__from,  nil, "" ]

=end
  def git_sha_msg_map_partitions__from git_base_partition_plan=nil
    git_base_partition__from(git_base_partition_plan)[3]
  end


=begin
  just like #git_sha_msg_map_partitions__from, but returns only
  the commits newer than the commit's having the message in
  the given #git_base_partition_plan

  examples:

  git_sha_msg_map__newer_than [:git_base__from, nil, "commit msg"]
  git_sha_msg_map__newer_than [:git_base__from ] # assumed [ :git_base__from,  nil, "" ]
  git_sha_msg_map__newer_than # assumed [ :git_base__from,  nil, "" ]


=end
  def git_sha_msg_map__newer_than git_base_partition_plan=nil
    git_sha_msg_map_partitions__from(git_base_partition_plan)[0]
  end


=begin
  just like #git_sha_msg_map_partitions__from, but takes a #git_base__
  definition as parameter instead.

  examples:

  git_sha_msg_map__from
  git_sha_msg_map__from [:git_base__from ]
=end
  def git_sha_msg_map__from git_base=nil
    git_sha_msg_map_partitions__from(git_base).flatten(1)
  end


=begin
   extracts the sha object id (ie, the actual sha strings) from a
   given #git_sha_msg_map__

  examples:
  git_sha_object_ids__from git_sha_msg_map__newer_than [:git_base__from, nil, "commit msg"]
  ["cherry-pick"].product   git_sha_object_ids__from git_sha_msg_map__newer_than [:git_base__from, nil, "commit msg"]

=end
  def git_sha_object_ids__from git_sha_msg_map
    git_sha_msg_map = array__from git_sha_msg_map
    git_sha_msg_map.transpose[0].to_a
  end


=begin
   extracts the commits messages from a given #git_sha_msg_map__

  examples: 
  git_commit_msgs__from git_sha_msg_map__newer_than [:git_base__from, nil, "commit msg"]
  ["cherry-pick"].product   git_commit_msgs__from git_sha_msg_map__newer_than [:git_base__from, nil, "commit msg"]

=end
  def git_commit_msgs__from git_sha_msg_map
    git_sha_msg_map = array__from git_sha_msg_map
    git_sha_msg_map.transpose[1].to_a
  end


=begin
  reduces the given #git_sha_msg_map__ definition to contain
  only the ones having messages matching #msgs

  examples:

  git_sha_msg_map__select_with_msg_match ["document"], :git_sha_msg_map__from
  git_sha_msg_map__select_with_msg_match ["module", "class"], :git_sha_msg_map__from
  git_sha_msg_map__select_with_msg_match ["module", "class"] # :git_sha_msg_map__from assumed
=end
  def git_sha_msg_map__select_with_msg_match msgs, git_sha_msg_map=:git_sha_msg_map__from
    git_sha_msg_map = array__from git_sha_msg_map
    msgs = array__from msgs
    msgs.product(git_sha_msg_map).select { |msg_git_sha_msg|
      msg, git_sha_msg = msg_git_sha_msg
      git_sha_msg[1].match(msg)
    }.transpose[1]
  end


end # of RubyRooomyGitShellCommandsModule


=begin 
  The purpose of this module is to offer functions that can
  generalize the way other ShellCommandsModule are created.
  Normally most shell comands will take the basic form:

  command subcommand options args


  like:

  git show --raw HEAD~0


=end
module RubyRooomySubShellCommandsModule


=begin
  Generates a sample #bash_subshell definition
  that can be used to create batches to run
  a script called "my_script.sh", installed under
  a location set in an environment var PREFIX.

  Give it to #bash_subshell_batch__generate, and give
  some imaginary commands to it, like [ "build", "run"]

  Note: an echo was prepended to the "my_script.sh"
  script to make it succeed if the batch is given
  to #exec__batch

=end
  def bash_subshell__my_script_sample
    [
      [
        nil,                                   # command for program (reserved)
        "echo my_script.sh",                        # program
        nil,                                   # options for program (reserved)
        nil,                                   # token separator
        nil,                                   # prepended variables
        " | tee  output.txt",                       # appended redirects
      ],                                       # program
      [
        [ "${HOME}/my_script/"    , "PREFIX"          , ],
        [ "$PATH:${PREFIX}/bin/"  , "PATH"            , ],
        [ "${PREFIX}/lib/"        , "LD_LIBRARY_PATH" , ],
      ],                                       # exports
      [
        [ "${PREFIX}/my_script.conf" , "--conf-file"  , ],
        [ "-v"                       ,                  ],
        [ "8081"                     , "-port"  , ":" , ],
      ],                                       # options
    ]
  end


=begin
  Defines a sample #bash_subshell_program__
  definition which can be used to generate
  export commands

  Examples:

  string__from_definition definition__merge_simple [ "${HOME}/my_script/" , "PREFIX" , ], bash_subshell_program__export_deps
  # => "export PREFIX=${HOME}/my_script/;"

=end
  def bash_subshell_program__export_deps
    [
      nil,              # reserved for value
      nil,              # reserved for variable
      "=",              # default assignment operator
      "",               # default separator
      ["", "export"],   # default begin ("export ")
      ";",              # default end
    ]
  end


=begin
  Given a #batch_subshell definition, generates a batch for it.

  Examples:

  bash_subshell_batch__generate "bash_subshell__my_script_sample", ["build", "run"]
  # => [[" ",
    "export PREFIX=${HOME}/my_script/; export PATH=$PATH:${PREFIX}/bin/; export LD_LIBRARY_PATH=${PREFIX}/lib/; echo my_script.sh --conf-file=${PREFIX}/my_script.conf -v -port:8081 build  | tee  output.txt"],
  #    [" ",
       "export PREFIX=${HOME}/my_script/; export PATH=$PATH:${PREFIX}/bin/; export LD_LIBRARY_PATH=${PREFIX}/lib/; echo my_script.sh --conf-file=${PREFIX}/my_script.conf -v -port:8081 run  | tee  output.txt"]]

=end
  def bash_subshell_batch__generate subshell, commands
    program,
     definitions,
     program_options,
     reserved = array__from(subshell)

   variables = array__from(definitions).map {|d|
     d = array__from d
     d = definition__merge_simple d, bash_subshell_program__export_deps
     string__from_definition d
   }

   program_options = array__from(program_options).map { |o|
     o = array__from o
     o[2] ||= o[1] && "=" # default assignment operator, if two operands
     string__from_definition o
   }

   commands = array__from(commands).map { |c|
     string__from_definition c
   }
   call_complement = [
     nil,  # command
     nil,  # program
     string__recursive_join(
       [" "] +  program_options,
     ),   # options
     " ",  # token separator
     string__recursive_join(
       [" "] +  variables, # varibles
     ),
     nil,   # redirections

   ]

   batch = commands.map { |command|
     call_complement[0] = command
     definition  = definition__merge_simple program, call_complement
     [ " ",  string__from_definition(definition) ]
   }

  end # of bash_subshell_batch__generate


end # of RubyRooomySubShellCommandsModule


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
    psql_db = array__from(psql_db)
    db_queries = array__from(db_queries_method)
    batch = psql_db_batch__cli_or_queries psql_db, db_queries
  end


=begin
  just a sample example for psql_db_batch__db_queries_method
=end
  def psql_db_batch__drop_owned_current_user psql_db
    batch = psql_db_batch__db_queries_method psql_db, :db_queries__drop_owned_current_user
  end


=begin
  returns a query to give super user powers to a user
  (the current user, by default, although it may not
  be so effective, since only super users can can perform
  such operation).
=end
  def db_query__alter_user_with_superuser username="CURRENT_USER"
      db_query = "ALTER USER #{username} WITH SUPERUSER"
  end


=begin
  returns a query to revoke super user powers to a user
  (the current user, by default, although it may not
  be so effective, since only super users can can perform
  such operation).
=end
  def db_query__alter_user_with_nosuperuser username="CURRENT_USER"
      db_query = "ALTER USER #{username} WITH NOSUPERUSER"
  end


=begin
  returns a query to reassign the ownership (of the currently
  connected database) from current_owner ("CURRENT_USER") if
  none given to new_owner

  Examples:

  db_query__reassign_to("new_owner")
  => "REASSIGN OWNED BY CURRENT_USER TO new_owner"

  psql_db_batch__cli_or_queries "psql_db__sample_example", db_query__reassign_to("new_owner", "old_owner")
  => [["PGPASSWORD=\"onlyNSAknows\" psql -h \"localhost\" -U \"any_user\" \"any_db\" ",
    "-c \"REASSIGN OWNED BY old_owner TO new_owner\""]]


=end
  def db_query__reassign_to new_owner, current_owner="CURRENT_USER"
    db_query = "REASSIGN OWNED BY #{current_owner} TO #{new_owner}"
  end


=begin
  returns a query to create a database.
  takes the database name as parameter
  (or a #psql_db__ definition).

  Examples:

  db_query__database_create "new_db"
  => "CREATE DATABASE new_db"


  psql_db_batch__cli_or_queries "psql_db__sample_example", db_query__database_create("new_db")
  => [["PGPASSWORD=\"onlyNSAknows\" psql -h \"localhost\" -U \"any_user\" \"any_db\" ",
    "-c \"CREATE DATABASE new_db\""]]

  db_query__database_create psql_db__sample_example
  => "CREATE DATABASE any_db"

=end
  def db_query__database_create db_name
    db_name = array__from(db_name).first
    db_query = "CREATE DATABASE #{db_name}"
  end


=begin
  returns a query to drop a database.
  takes the database name as parameter
  (or a #psql_db__ definition).

  Examples:

  db_query__database_drop "new_db"
  => "DROP DATABASE new_db"

  psql_db_batch__cli_or_queries "psql_db__sample_example", db_query__database_drop("new_db")
  => [["PGPASSWORD=\"onlyNSAknows\" psql -h \"localhost\" -U \"any_user\" \"any_db\" ",
    "-c \"DROP DATABASE new_db\""]]


  db_query__database_drop psql_db__sample_example
  => "DROP DATABASE any_db"


=end
  def db_query__database_drop db_name
    db_name = array__from(db_name).first
    db_query = "DROP DATABASE #{db_name}"
  end


end # of RubyRooomySqlQueriesModule


=begin 
  The purpose of this module is to offer functions to
  help batching the functions of RubyRooomyPgShellCommandsModule
  and creating higher level operations on databases,
  like "reset" (droping and recreating), backup,
  apply the contents of another database, and so on.
=end
module RubyRooomyPgShellDerivativesModule


=begin
  Sample #psql_db_derivative__ to generate a
  batch to dump a backup the database described
  by the #psql_db__, at its second element,
  in the filepath at the first position.

  Give it to #psql_db_derivative_batch__from

  Example:
  script__from psql_db_derivative_batch__from "psql_db_derivative__sample_db_backup_dump"
  PGPASSWORD="onlyNSAknows" pg_dump -h "localhost" -U "any_user" "any_db"    -f "/tmp/backup_dump"

=end
  def psql_db_derivative__sample_db_backup_dump *args
    [
      "/tmp/backup_dump",            # file to dump a backup of psql_db
      psql_db__sample_example,       # psql_db, having database access info
      nil,
      nil,
      nil,
      nil,
    ]
  end # of psql_db_derivative__sample_db_backup_dump


=begin
  Sample #psql_db_derivative__ to generate a
  batch to reset the database defined
  by the #psql_db__, at its second element;
  a reset means basically a dropdb and a
  createdb command.

  Give it to #psql_db_derivative_batch__from

  Example:
  script__from psql_db_derivative_batch__from "psql_db_derivative__sample_db_reset"
  PGPASSWORD="onlyNSAknows" dropdb -h "localhost" -U "any_user" "any_db"   ;
  PGPASSWORD="onlyNSAknows" createdb -h "localhost" -U "any_user" "any_db"

=end
  def psql_db_derivative__sample_db_reset *args
    [
      nil,
      psql_db__sample_example, # psql_db, having database access info
      nil,
      nil,
      nil,
      "reset",                 # set reset to true
    ]
  end


=begin
  Sample #psql_db_derivative__ to generate a
  batch to apply to the database defined
  by the #psql_db__, at its second element,
  a list of dumps/migrations/file containing
  sql queries.

  Give it to #psql_db_derivative_batch__from

  Example:
  script__from psql_db_derivative_batch__from "psql_db_derivative__sample_db_apply_dumps"
  PGPASSWORD="onlyNSAknows" psql -h "localhost" -U "any_user" "any_db"    -f "migrations/file_1.sql" ;
  PGPASSWORD="onlyNSAknows" psql -h "localhost" -U "any_user" "any_db"    -f "migrations/file_2.sql"

=end
  def psql_db_derivative__sample_db_apply_dumps *args
    [
      nil,
      psql_db__sample_example, # psql_db, having database access info
      [
        [
          "migrations/file_1.sql",
          "migrations/file_2.sql",
        ],                     # list of dumps to apply
      ],
      nil,
      nil,
      nil,
    ]
  end # of psql_db_derivative__sample_db_apply_dumps


=begin
  Sample #psql_db_derivative__ to generate a
  batch to apply to the database defined
  by the #psql_db__, at its second element,
  a list of dumps/migrations/file containing
  sql queries.

  This example differs from #psql_db_derivative__sample_db_apply_dumps
  in which it generates, recursively, a batch
  to generate the backup dumps of another database,
  and apply it to the current one.


  Give it to #psql_db_derivative_batch__from

  Example:
  script__from psql_db_derivative_batch__from "psql_db_derivative__sample_db_apply_dumps_from_backup"
  PGPASSWORD="onlyNSAknows" pg_dump -h "localhost" -U "any_user" "any_db"    -f "/tmp/backup_dump" ;
  PGPASSWORD="onlyNSAknows2" psql -h "localhost" -U "any_user_2" "any_db_2"    -f "/tmp/backup_dump"

=end
  def psql_db_derivative__sample_db_apply_dumps_from_backup *args
    [
      nil,
      psql_db__sample_example_2, # psql_db, having database access info
      psql_db_derivative__sample_db_backup_dump,
                                 # list of dumps to apply is the
                                 # backup list of another derivative
      nil,
      nil,
      nil,
    ]
  end # of psql_db_derivative__sample_db_apply_dumps_from_backup


=begin
  Sample #psql_db_derivative__ to generate a
  batch to transfer the database ownershipf of
  the database defined
  by the #psql_db__, at its second element,
  to the (user of the) #psql_db defined at
  its 5th element.

  Give it to #psql_db_derivative_batch__from

  Example:
  script__from psql_db_derivative_batch__from "psql_db_derivative__sample_db_reassign"
  PGPASSWORD="NSAowns" psql -h "localhost" -U "any_superuser" "any_db"  -c "REASSIGN OWNED BY "\"any_superuser\"" TO any_user"

=end
  def psql_db_derivative__sample_db_reassign *args
    [
      nil,
      psql_db__sample_superuser_example, # psql_db, having database access info
      nil,
      nil,
      psql_db__sample_example,           # psql_db, having the user to assing the db
      nil,
    ]
  end # of psql_db_derivative__sample_db_reassign


=begin
  Sample #psql_db_derivative__ to help generating
  a batch to ignore errors on dumps to be applied.

  Give it to #psql_db_derivative_batch__from

  Example:
  script__from psql_db_derivative_batch__from definition__merge_simple(
      psql_db_derivative__sample_db_apply_dumps,
      psql_db_derivative__with_options
    )
  PGPASSWORD="onlyNSAknows" psql -h "localhost" -U "any_user" "any_db"   ON_ERROR_STOP=off -f "migrations/file_1.sql" ;
  PGPASSWORD="onlyNSAknows" psql -h "localhost" -U "any_user" "any_db"   ON_ERROR_STOP=off -f "migrations/file_2.sql"

=end
  def psql_db_derivative__with_options *args
    [
      nil,
      nil,
      nil,
      "ON_ERROR_STOP=off",
      nil,
      nil,
    ]
  end # of psql_db_derivative__with_options


=begin
  Sample #psql_db_derivative__ to generate a
  batch to apply to the database defined
  by the #psql_db__, at its second element,
  a list of dumps/migrations/file containing
  sql queries.

  It differs from #psql_db_derivative__sample_db_apply_dumps
  in which this one has option set to ignore
  errors when restoring those dumps.

  Give it to #psql_db_derivative_batch__from

  Example:
  script__from psql_db_derivative_batch__from "psql_db_derivative__sample_db_apply_dumps_with_options"
  PGPASSWORD="onlyNSAknows" psql -h "localhost" -U "any_user" "any_db"   ON_ERROR_STOP=off -f "migrations/file_1.sql" ;
  PGPASSWORD="onlyNSAknows" psql -h "localhost" -U "any_user" "any_db"   ON_ERROR_STOP=off -f "migrations/file_2.sql"

=end
  def psql_db_derivative__sample_db_apply_dumps_with_options *args
    definition__merge_simple(
      psql_db_derivative__sample_db_apply_dumps,
      psql_db_derivative__with_options
    )
  end # of psql_db_derivative__sample_db_apply_dumps_with_options


=begin
  Sample #psql_db_derivative__ to generate a
  batch to apply to apply all supported operations
  on the database defined by the #psql_db__,
  at its second element.

  It will first backup the dump of the database
  defined by psql_db__sample_example (due to a recursive
  call to psql_db_derivative__sample_db_backup_dump),
  at "/tmp/backup_dump".

  Since the database defined by
  psql_db__sample_superuser_example is about to
  be operated, its backup will be dumped into
  "/tmp/superuser_backup_dump".

  Since "reset" is set, "dropdb" and "createdb"
  commands are generated.

  It will then use the backup dump generated at the
  first step to restore the database defined by
  psql_db__sample_superuser_example.

  Since the option "ON_ERROR_STOP=off" is defined,
  it will ignore errors during the restoration.

  Since another #psql_db__ is given, it will reassign
  the ownership of the database to the user defined
  by psql_db__sample_example


  Give it to #psql_db_derivative_batch__from

  Example:

  script__from psql_db_derivative_batch__from "psql_db_derivative__sample_full_example"
  PGPASSWORD="onlyNSAknows" pg_dump -h "localhost" -U "any_user" "any_db"    -f "/tmp/backup_dump" ;
  PGPASSWORD="NSAowns" pg_dump -h "localhost" -U "any_superuser" "any_db"   ON_ERROR_STOP=off -f "/tmp/superuser_backup_dump" ;
  PGPASSWORD="NSAowns" dropdb -h "localhost" -U "any_superuser" "any_db"   ;
  PGPASSWORD="NSAowns" createdb -h "localhost" -U "any_superuser" "any_db"   ;
  PGPASSWORD="NSAowns" psql -h "localhost" -U "any_superuser" "any_db"   ON_ERROR_STOP=off -f "/tmp/backup_dump" ;
  PGPASSWORD="NSAowns" psql -h "localhost" -U "any_superuser" "any_db"  -c "REASSIGN OWNED BY "\"any_superuser\"" TO any_user"

=end
  def psql_db_derivative__sample_full_example *args
    [
      "/tmp/superuser_backup_dump",
      psql_db__sample_superuser_example, # psql_db, having database access info
      psql_db_derivative__sample_db_backup_dump,
                                 # list of dumps to apply is the
                                 # backup list of another derivative
      "ON_ERROR_STOP=off",
      psql_db__sample_example,   # psql_db, having the user to assign the db
      "reset",                   # set reset to true
    ]
  end # of psql_db_derivative__sample_full_example


=begin
  Takes as input a #psql_db_derivative__ definition,
  a definition that offers a robust way to describe
  dumping and restoration of a database (described
  by a #psql_db__ definition). A #psql_db_derivative__
  definitions has the following elements:

  * backup_paths: a dump of the database will be
  generated to each element in this array.

  * psql_db: describes the database (an array having
  name, username, password, host). The only mandatory
  field.

  * db_dumps_to_apply_paths: consider the first element
  of this array: it is also an array, having the paths
  of dumps, or migrations (any file having sql queries).
  So, now consider the second element of this array. If
  given, will make this array to be considered another
  ##psql_db_derivative__, and this function will be called
  recursively. It's used to describe another #psql_db__
  to dump and apply to the current psql_db.

  * options: to the psql command line. Normally
  "ON_ERROR_STOP=off" to ignore sql that raises errors.

  * reassignee_psql_db: if the database ownership needs
  to be, at the end of the process, reassigned to another
  user, it can be given as the user of this #psql_db__
  (second element of the array). Normally needed if a
  reset (next paramenter) is required (so, psqldb has
  the supseruser and this one the reassignee).

  * reset: by default, all db_dumps_to_apply_paths will
  be applied on top of the current state of psql_db. If reset
  is set, a command to drop the database and another one
  to recreate it.

  Create a #psql_db_derivative__ and give to this function.
  There are many sample and their usage in the examples
  section. Take the one that fits your use case, search for
  its definition; there will be more information on their
  comments; specially #psql_db_derivative__sample_full_example

  Examples:

  # dump the database:
  script__from psql_db_derivative_batch__from "psql_db_derivative__sample_db_backup_dump"
  PGPASSWORD="onlyNSAknows" pg_dump -h "localhost" -U "any_user" "any_db"    -f "/tmp/backup_dump"


  # reset the database:
  script__from psql_db_derivative_batch__from "psql_db_derivative__sample_db_reset"
  PGPASSWORD="onlyNSAknows" dropdb -h "localhost" -U "any_user" "any_db"   ;
  PGPASSWORD="onlyNSAknows" createdb -h "localhost" -U "any_user" "any_db"


  # reset and dump the database:
  script__from psql_db_derivative_batch__from definition__merge_simple(psql_db_derivative__sample_db_backup_dump, psql_db_derivative__sample_db_reset)
  PGPASSWORD="onlyNSAknows" pg_dump -h "localhost" -U "any_user" "any_db"    -f "/tmp/backup_dump" ;
  PGPASSWORD="onlyNSAknows" dropdb -h "localhost" -U "any_user" "any_db"   ;
  PGPASSWORD="onlyNSAknows" createdb -h "localhost" -U "any_user" "any_db"


  # apply dumps or migrations to the database:
  script__from psql_db_derivative_batch__from "psql_db_derivative__sample_db_apply_dumps"
  PGPASSWORD="onlyNSAknows" psql -h "localhost" -U "any_user" "any_db"    -f "migrations/file_1.sql" ;
  PGPASSWORD="onlyNSAknows" psql -h "localhost" -U "any_user" "any_db"    -f "migrations/file_2.sql"

  # dump a database and restore it into another one:
  script__from psql_db_derivative_batch__from "psql_db_derivative__sample_db_apply_dumps_from_backup"
  PGPASSWORD="onlyNSAknows" pg_dump -h "localhost" -U "any_user" "any_db"    -f "/tmp/backup_dump" ;
  PGPASSWORD="onlyNSAknows2" psql -h "localhost" -U "any_user_2" "any_db_2"    -f "/tmp/backup_dump"

  # reassign ownership of a database:
  script__from psql_db_derivative_batch__from "psql_db_derivative__sample_db_reassign"
  PGPASSWORD="NSAowns" psql -h "localhost" -U "any_superuser" "any_db"  -c "REASSIGN OWNED BY "\"any_superuser\"" TO any_user"

  script__from psql_db_derivative_batch__from definition__merge_simple(
      psql_db_derivative__sample_db_apply_dumps,
      psql_db_derivative__with_options
    )
  PGPASSWORD="onlyNSAknows" psql -h "localhost" -U "any_user" "any_db"   ON_ERROR_STOP=off -f "migrations/file_1.sql" ;
  PGPASSWORD="onlyNSAknows" psql -h "localhost" -U "any_user" "any_db"   ON_ERROR_STOP=off -f "migrations/file_2.sql"

  # dump database, set option to ignore errors.
  script__from psql_db_derivative_batch__from "psql_db_derivative__sample_db_apply_dumps_with_options"
  PGPASSWORD="onlyNSAknows" psql -h "localhost" -U "any_user" "any_db"   ON_ERROR_STOP=off -f "migrations/file_1.sql" ;
  PGPASSWORD="onlyNSAknows" psql -h "localhost" -U "any_user" "any_db"   ON_ERROR_STOP=off -f "migrations/file_2.sql"

=end
  def psql_db_derivative_batch__from psql_db_derivative

    # interpreting input:
    backup_paths,
      psql_db,
      psql_db_derivative_or_db_dumps_to_apply_paths,
      options,
      reassignee_psql_db,
      reset,
      reserved = array__from(psql_db_derivative)

    db_name,
      db_user,
      db_password,
      reserved = array__from(psql_db)

    reassignee_db_name,
      reassignee_db_user,
      reassignee_db_password,
      reserved = array__from(reassignee_psql_db)

    db_dumps_to_apply_paths,
      next_psql_db,
      reserved = array__from(
        psql_db_derivative_or_db_dumps_to_apply_paths.nne
      )

    db_dumps_to_apply_paths = array__from(
      db_dumps_to_apply_paths.nne
    ).compact
    backup_paths = array__from(
      backup_paths.nne
    ).compact
    options = options.nne ""
    quoted_db_user = db_user.nne && db_user.inspect.inspect || nil

    # generate (recursion) dependent batches, if defined.
    dependency_batch = next_psql_db.nne && (
      send(
        __method__, # recursion
        psql_db_derivative_or_db_dumps_to_apply_paths.nne
      )
    ) || []

    # generate backup/dumping batches
    backup_batch = psql_db_batch__cli_or_generate_dumps(
      psql_db,
      backup_paths,
    )

    # generate database reset batch, if needed
    reset_batch = reset.nne && [
      [ psql_db_command__dropdb(psql_db) ],
      [ psql_db_command__createdb(psql_db) ],
    ] || []

    # generate dump restoration / application batch
    apply_dumps_batch = psql_db_batch__cli_or_apply_dumps(
      psql_db,
      db_dumps_to_apply_paths,
      options
    )

    # generate dump database reassignment batch
    reassign_batch = reassignee_db_user.nne &&
      psql_db_batch__cli_or_queries(
        psql_db,
        db_query__reassign_to(
          reassignee_db_user,
          quoted_db_user,
        )
      ) || [] # no reassignee = no command generated

    batch =
      dependency_batch +
      backup_batch +
      reset_batch +
      apply_dumps_batch +
      reassign_batch +
      []

  end # of psql_db_derivative_batch__from


=begin
  generates a #psql_db_derivative out of
  psql_db, superuser_psql_db, source_psql_db,
  to backup, drop, and repopulate psql_db, using
  the psql installation of superuser_psql_db, with
  the contents of source_psql_db. At the end,
  the original user is restored.

  It's very similar to the #psql_db_derivative__sample_full_example
  (which is well documented), but takes the #psql_db__ definitions
  as parameter. It modifies the psql_db making it a super user
  psql_db, with the help of superuser_psql_db (calling
  #psql_db__name_from).
 
  Also generates nicer dump file names, more
  suitable for a concrete use case.

  Examples:

  script__from psql_db_derivative_batch__from psql_db_derivative__sample_full_from_3("psql_db__sample_example", "psql_db__sample_superuser_example", "psql_db__sample_example_2")
  PGPASSWORD="onlyNSAknows2" pg_dump -h "localhost" -U "any_user_2" "any_db_2"    -f "/tmp/dump__source_any_db_2_171552.sql" ;
  PGPASSWORD="NSAowns" pg_dump -h "localhost" -U "any_superuser" "any_db"   ON_ERROR_STOP=off -f "/tmp/dump__backup_any_db_171552.sql" ;
  PGPASSWORD="NSAowns" dropdb -h "localhost" -U "any_superuser" "any_db"   ;
  PGPASSWORD="NSAowns" createdb -h "localhost" -U "any_superuser" "any_db"   ;
  PGPASSWORD="NSAowns" psql -h "localhost" -U "any_superuser" "any_db"   ON_ERROR_STOP=off -f "/tmp/dump__source_any_db_2_171552.sql" ;
  PGPASSWORD="NSAowns" psql -h "localhost" -U "any_superuser" "any_db"  -c "REASSIGN OWNED BY "\"any_superuser\"" TO any_user"


=end
  def psql_db_derivative__sample_full_from_3 psql_db, superuser_psql_db, source_psql_db

    superuser_psql_db = array__from(superuser_psql_db)
    source_psql_db = array__from(source_psql_db)
    psql_db = array__from psql_db
    superuser_psql_db = array__from superuser_psql_db

    psql_db__superuser = psql_db__name_from(
      superuser_psql_db,
      psql_db
    )

    dump_serial_number = string__small_sn_2019
    source_psql_db = array__from(source_psql_db)
    backup_db_dump = "/tmp/dump__backup_#{psql_db__superuser[0]}_#{dump_serial_number}.sql"
    source_db_dump = "/tmp/dump__source_#{source_psql_db[0]}_#{dump_serial_number}.sql"
    [
      backup_db_dump,
      psql_db__superuser,  # psql_db, having database access info
      [
        source_db_dump,
        source_psql_db,
      ],
                                 # list of dumps to apply is the
                                 # backup list of another derivative
      "ON_ERROR_STOP=off",
      psql_db,                   # psql_db, having the user to assign the db
      "reset",                   # set reset to true
    ]
  end # of  psql_db_derivative__sample_full_from_3


end # of RubyRooomyPgShellDerivativesModule


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

  Examples:

  psql_db_batch__cli_or_queries psql_db__sample_example
  => [["PGPASSWORD=\"onlyNSAknows\" psql -h \"localhost\" -U \"any_user\" \"any_db\" ",
  nil]]

  psql_db_batch__cli_or_queries psql_db__sample_example, "select * from table"
  => [["PGPASSWORD=\"onlyNSAknows\" psql -h \"localhost\" -U \"any_user\" \"any_db\" ",
  "-c \"select * from table\""]]


  psql_db_batch__cli_or_queries psql_db__sample_example, ["select  c1 from table", "select c2 from table"]
  => [["PGPASSWORD=\"onlyNSAknows\" psql -h \"localhost\" -U \"any_user\" \"any_db\" ",
  "-c \"select  c1 from table\""],
   ["PGPASSWORD=\"onlyNSAknows\" psql -h \"localhost\" -U \"any_user\" \"any_db\" ",
   "-c \"select c2 from table\""]]
=end
  def psql_db_batch__cli_or_queries psql_db, db_queries=[nil]
    psql_db = array__from(psql_db)
    db_queries = array__from(db_queries)
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
    db_port = nil
    db_connection = nil

    [
      db_name,
      db_user,
      db_password,
      db_host,
      db_port,
      db_connection,
    ]
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
    shell_params_psql_db = quoted_shell_params array__from(psql_db)
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
    psql_db = array__from(psql_db)
    db_dump_paths = array__from(db_dump_paths)
    batch = db_dump_paths.map { |db_dump_path|
      cli = psql_db_command__cli psql_db
      pg_dump = psql_db_command__dump psql_db
      program = db_dump_path && pg_dump || cli
      [program, db_dump_path && " #{options} -f #{quoted_shell_param db_dump_path}"]
    }
  end


=begin
  Generates a createdb command for the given
  #psql_db__ definition , which can be used
  to drop a database

  Examples:

  psql_db_command__dropdb "psql_db__sample_example"
  => "PGPASSWORD=\"onlyNSAknows\" dropdb -h \"localhost\" -U \"any_user\" \"any_db\" "

=end
  def psql_db_command__dropdb psql_db
   psql_db_command__program "dropdb", psql_db
  end


=begin
  Generates a createdb command for the given
  #psql_db__ definition , which can be used
  to create a database

  Examples:

  psql_db_command__createdb "psql_db__sample_example"
  => "PGPASSWORD=\"onlyNSAknows\" createdb -h \"localhost\" -U \"any_user\" \"any_db\" "

=end
  def psql_db_command__createdb psql_db
   psql_db_command__program "createdb", psql_db
  end


=begin
  A sample #psql_db__ which is supposed to
  be a super user on the dbms as of
  #psql_db__sample_example .
  It is intended mostly for use in examples
  in psql_db related functions.

  Examples:

  psql_db_command__dump psql_db__sample_superuser_example
  => "PGPASSWORD=\"NSAowns\" pg_dump -h \"localhost\" -U \"any_superuser\" \"any_db\" "

  psql_db_batch__cli_or_generate_dumps "psql_db__sample_superuser_example", "db_dump"
  => [["PGPASSWORD=\"NSAowns\" pg_dump -h \"localhost\" -U \"any_superuser\" \"any_db\" ", "  -f \"db_dump\""]]

  script__from(psql_db_batch__cli_or_generate_dumps "psql_db__sample_superuser_example")
  => "PGPASSWORD=\"NSAowns\" psql -h \"localhost\" -U \"any_superuser\" \"any_db\"  "

=end
  def psql_db__sample_superuser_example *args
    db_name="any_db"
    db_user="any_superuser"
    db_host="localhost"
    db_password="NSAowns"
    db_port = nil
    db_connection = nil

    [
      db_name,
      db_user,
      db_password,
      db_host,
      db_port,
      db_connection,
    ]
  end # of psql_db__sample_superuser_example


=begin
  Just another sample #psql_db__ definition,
  used in examples which operates more than
  one database.

  Examples:

  psql_db_command__dump psql_db__sample_example_2
  PGPASSWORD="onlyNSAknows2" pg_dump -h "localhost" -U "any_user_2" "any_db_2" 

  psql_db_batch__cli_or_generate_dumps "psql_db__sample_example_2", "db_dump"
  => [["PGPASSWORD=\"onlyNSAknows2\" pg_dump -h \"localhost\" -U \"any_user_2\" \"any_db_2\" ", "  -f \"db_dump\""]]

  script__from(psql_db_batch__cli_or_generate_dumps "psql_db__sample_example_2")
  PGPASSWORD="onlyNSAknows2" psql -h "localhost" -U "any_user_2" "any_db_2"  


=end
  def psql_db__sample_example_2 *args
    db_name="any_db_2"
    db_user="any_user_2"
    db_host="localhost"
    db_password="onlyNSAknows2"
    db_port = nil
    db_connection = nil

    [
      db_name,
      db_user,
      db_password,
      db_host,
      db_port,
      db_connection,
    ]
  end # of psql_db__sample_example_2


  include RubyRooomyPgShellDerivativesModule


=begin
  #psql_db__ definition to update a a given
  psql_db with the information regarding only
  the dbms from another psql_db.

  Basically, that means copying the host and
  the port from psql_db_having_host, and cleaning
  the connection, if any.

  It is useful when the same structures are
  installed in multiple instances of the dbms,
  postgresql.
=end
  def psql_db__dbms_from psql_db, psql_db_having_dbms

    psql_db = array__from(psql_db)
    psql_db_having = array__from(psql_db_having_dbms)
    psql_db[3] = psql_db_having[3] # host
    psql_db[4] = psql_db_having[4] # port
    psql_db[5] = nil # resets the connection, if any
    psql_db
  end # of psql_db__dbms_from


=begin
  #psql_db__ definition to update a a given
  psql_db with the information regarding only
  the user from another psql_db.

  Basically, that means copying the username and
  the password from psql_db_having_user, and cleaning
  the connection, if any.

  It is useful when the same structures are
  installed in multiple instances of the dbms,
  postgresql.
=end
  def psql_db__user_from psql_db, psql_db_having_user

    psql_db = array__from(psql_db)
    psql_db_having = array__from(psql_db_having_user)
    psql_db[1] = psql_db_having[1] # user
    psql_db[2] = psql_db_having[2] # pw
    psql_db[5] = nil # resets the connection, if any
    psql_db
  end # of psql_db__user_from


=begin
  generates a string out of a psql_db.
  good to generate file names, and so on.
=end
  def string__psql_db psql_db, joinner = "_"
    db_name,
      db_user,
      db_password,
      db_host,
      db_port,
      reserved = array__from psql_db
    [ db_host, db_port, db_name, ].compact.join joinner
  end # of string__psql_db


=begin
  #psql_db__ definition to update a a given
  psql_db with the information regarding only
  the database name from another psql_db.

  Basically, that means copying the database name
  from psql_db_having_name, and cleaning
  the connection, if any.

  It is useful to derive a super user psql_db for the
  same dbms as another super user psql_db, but for
  a different database (ie it "sums" a super user
  psql_db and a normal psql_db, resulting in a super
  user psql_db for the normal psql_db)

=end
  def psql_db__name_from psql_db, psql_db_having_name

    psql_db = array__from(psql_db)
    psql_db_having = array__from(psql_db_having_name)
    psql_db[0] = psql_db_having[0] # db name
    psql_db[5] = nil # resets the connection, if any
    psql_db
  end # of psql_db__name_from


end # of RubyRooomyPgShellCommandsModule


=begin
  The purpose of this module is to offer functions that can
  execute commands available in the command line shell where
  ruby is running.
=end
module RubyRooomyShellCommandsModule

   include RubyRooomyGitShellCommandsModule
   include RubyRooomyFsShellCommandsModule
   include RubyRooomyPgShellCommandsModule
   include RubyRooomyArrayOfHashesModule

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
        :output => (stdoutanderr.entries.join "\n"),
        :batch_command_method => "batch_command",
      })
    @results
  end


=begin
 like #batch_command, but takes an Array having call, *args
 pairs, called a "batch of commands"
  executes multiple commands in a shell, storing
  timestamp, command, args, return value,
  and output (stdout joined with stderr) in the
  last entries of the class variable @results

  accepts as parameter #admitted_errors, a number
  stating how many errors can be ignored (infinite
  by default).

  alternatively, accepts #batch_controller instead
  of #admitted_errors (the former may contain the
  latter), which allows a function other than
  #batch_command to be used instead for each of
  the commands in the batch.

  sets a variable @working_batch, having the commands
  not executed in a premature stop caused by more
  errors happening than allowed by #admitted_errors.

  returns only the part of @results that corresponds to the
  commands executed during its execution.

=end
  def batch_commands batch, batch_controller=nil
    batch_controller ||= batch_controller__default
    admitted_errors,
      batch_command_method = array__from(batch_controller)
    admitted_errors ||= Float::INFINITY
    batch_command_method ||= :batch_command
    amount_of_errors=0
    results_before = results.dup
    @working_batch = batch
    non_executed_batch_part = batch.drop_while{ |call, *args|
      to_method(batch_command_method).call call, *args
      !(results.last[:success]) && (amount_of_errors += 1)
      amount_of_errors <= admitted_errors
    }
    @working_batch = non_executed_batch_part
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
    batch_commands batch__from_batch_generator batch_generator
  end


=begin
   generates a #batch__ definition out of a #batch_generator__ definition
=end
  def batch__from_batch_generator batch_generator
    send_args = (send batch_generator) rescue  batch_generator
    batch = send *send_args
  end


=begin
  Just an alias with a more modern name for  #batch_commands
=end
  def exec__batch *args
    batch_commands *args
  end


=begin
  returns a command string exactly at is expected to
  be run in the shell.
=end
  def command_shell_string__from call, *args
    "#{call} #{args.join " "}"
  end


=begin
  returns a command string exactly at is expected to
  be run in the shell.
=end
  def script__from batch
    batch.map { |call, *args|
      command_shell_string__from call, *args
    }.join(" ;\n")
  end


=begin
 returns the @results variable, and filtering it
 down for the hashes to have only the specified
 keys (or all, if keys = nil).
=end
  def results__select_keys keys=nil, results=nil
    @results ||=  []
    results ||= @results
    select_columns_by_kv_as_arrays(results, nil, nil, keys)
  end


=begin
  default behaviour for batches:
  . infinity number of errors admitted (won't stop);
  . runs on the operating system underlying shell.
=end
  def batch_controller__default
    [
      Float::INFINITY,
      :batch_command,
    ]
  end


=begin
  default behaviour for pg_gem batches:
  . infinity number of errors admitted (won't stop);
  . runs on a PG::Connection object, calling its
  method "exec"
=end
  def batch_controller__pg_gem_default
  # batch_command__pg_gem
    [
      Float::INFINITY,
      :batch_command__pg_gem,
    ]
  end


=begin
  default behaviour for batches:
  . no errors admitted
  . runs on the operating system underlying shell.
=end
  def batch_controller__stop_default
    [
      0,
      :batch_command,
    ]
  end


=begin
  default behaviour for pg_gem batches:
  . no errors admitted
  . runs on a PG::Connection object, calling its
  method "exec"
=end
  def batch_controller__pg_gem_stop_default
  # batch_command__pg_gem
    [
      0,
      :batch_command__pg_gem,
    ]
  end


=begin
 keeps the state of the current running batch submitted
 to #batch_commands or #exec__batch, for being able
 to resume in case of failures.
=end
  def working_batch
    @working_batch
  end


=begin
 resumes execution of the last batch submitted
 to #batch_commands or #exec__batch.
 Only effective if they have stopped due to
 unsucessful commands (commands that in bash
 returned false).

 Note that the parameter #admitted_errors and
 any future parameter added to #batch_comands or
 #exec__batch, are not stored, falling off to the
 defaults, unless they're given in the same order
 (clarifying  that the batch argument is no longer
 given).
=end
  def exec__working_batch *args
    send :exec__batch, @working_batch, *args
  end


=begin
 resumes execution of the last batch submitted
 to #batch_commands or #exec__batch, skipping
 the first command on it, supposedly a failure.
 Only effective if they have stopped due to
 unsucessful commands (commands that in bash
 returned false).

 basically the same as #exec__working_batch,
 without the first command.

 Note that the parameter #admitted_errors and
 any future parameter added to #batch_comands or
 #exec__batch, are not stored, falling off to the
 defaults, unless they're given in the same order
 (clarifying  that the batch argument is no longer
 given).
=end
  def exec__working_batch_failure_skipped *args
    @working_batch.shift
    send :exec__batch, @working_batch, *args
  end


=begin
 returns the @results variable, and filtering it
 down for the hashes to have only the specified
 key :output
=end
  def results__select_key_output results=nil
    keys =  [:output]
    (results__select_keys keys, results).flatten 1
  end


=begin
 generates a #exec__ definition (ie, an array of hashes
 containing information about how went the execution of
 commands) out of a #exec_plan, which has a #batch
 definition as a first element and a #batch_controller
 as second).

 example:
   exec__from [  [ ["date"], ["pwd"], ["ls /nofile"], ["pwd"]] ]
   exec__from [  [ ["date"], ["pwd"], ["ls /nofile"], ["pwd"]], "batch_controller__stop_default" ]
=end
  def exec__from exec_plan
    batch,
      batch_controller = array__from(exec_plan)
    exec__batch batch, batch_controller
  end


end # of RubyRooomyShellCommandsModule


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

=begin
  Just like filter_by_kv, but test if the values for the k matches
  (and not equals) v
=end
  def filter_by_kv_match h, k, v
    h.map  {|h1| (h1[k].match v rescue nil) && h1 || nil }.compact
  end

  # retrieve, in the array of hashes h, the ones having v in values. k is by now ignored, but it may be used in the future (pass nil) 
  # laternote: used only as helper for  select_column_by_kv
  def filter_by_v_in_values h, k, v
    h.map  {|h1| (h1.values.index v) && h1 || nil }.compact
  end


  def filter_by_k_matching_keys h, k, v
    h.map  {|h1| (h1.keys.grep k).reduce(:+) && h1 || nil }.compact
  end


  def filter_by_v_matching_values h, k, v
    h.map  {|h1| (h1.values.grep v).reduce(:+) && h1 || nil }.compact
  end

  # retrieve, in the array of hashes h, the ones matching k == v, selecting only one column
  def  select_column_by_kv  h, k, v, column = nil, method_name = :filter_by_kv
   filtered =  method(method_name).call h, k, v
   column && filtered.map {|h1| h1[column]} || (!column) && filtered
  end


  # retrieve, in the array of hashes h, the ones matching k == v, selecting only one column
  def  select_columns_by_kv  h, k, v, columns = nil, method_name = :filter_by_kv
   filtered =  method(method_name).call h, k, v
   columns && filtered.map {|h1| columns.map {|c| [c, h1[c]] }.to_h} || (!columns) && filtered
  end


  # call keys for each element of the array h
  #  example: map_to_keys h, :fetch, ["id", "default_id"] fetches all ids
  def map_to_keys h, method_name = :keys, method_args = nil
    h.map {|h1| h1.method(method_name).call  *method_args }
  end


=begin
  does the same as #select_columns_by_kv, but returning the result as arrays of arrays, having only the values (and not the columns/keys of the hashes).
=end
  def select_columns_by_kv_as_arrays *args
    map_to_keys(
      map_to_keys(
        map_to_keys(
          (select_columns_by_kv(*args)),
          :to_a
        ),
        :transpose
      ),
      :last
    )
  end


end


=begin
  the purpose of this module is to extend the
  class Git::Base of the gem 'git'
=end
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


=begin
  GitBase::log will fetch only the last 30 commits.
  A parameter can be given to it.
  Internal functions
  want to work with an infinite number.

  This function sets the big enough value, 1_000_000_000_000
  by default.
=end
    def log_size_limit set_to=nil
      set_to && (@log_size_limit = set_to)
      # @log_size_limit ||= Float::INFINITY
      # unfortunatelly, Float::INFINITY is printed as "Infinity"
      # in bash script batches. So, we really have to give it
      # a numerical size:
      @log_size_limit ||= 1_000_000_000_000
    end


=begin
  like #log, but fetches the commit objects instead (of
  the enumeration).
  Will fetch the amount of commits set by #log_size_limit
=end
    def branch_commits
      commits = log(log_size_limit).entries
      commits
    end


=begin
  Takes a list of commit objects (like the one returned by
  #self.log.entries ) and maps them into the attributes
  given as parameter. To check candidate options, check
  self.log.entries[0].methods

  If fields is nil, return the commits without mapping them.
=end
     def commits_map  log_entries=nil, fields=[:sha, :message, :itself,]
       log_entries ||= self.branch_commits
       commits = log_entries
       (fields && commits.map{ |c|
         fields.map {|f|
           c.send f
         }
       } || commits)
     end


=begin
     select commits whose menssage match str
     the result will be an array, having one
     element per commit matched. Each of those
     elements will be an array, having by
     default 3  elements (sha, message and the
     commit object itself).
     each
=end
     def select_commits_matching  str, log_entries=nil, fields=[:sha, :itself, :message]
       log_entries ||= self.branch_commits
       commits = log_entries.select {|c|
         c.message.match str
       }
       commits_map commits, fields
     end


=begin
    separates a given set of commits (like the default #self.log.entries)
    in an array having 3 arrays: the last having the elements *before*
    the occurrence of a commit matching str in its message; the middle having
    the commit which has the match, and the first commits after it.

    If multiple matches are found, then the last one (ie, probably the
    newest commit) is used. This behaviour can be controlled by changing
    the argument multiple_occurence_index

    If no matches are found, all the commits are considered to be "older"
    than the queried, and they will all be placed in the last commit.

    examples:

    # commit messages of commits "newer"/on top of the last/"newest" commit having "commit msg" in its commit message:
    partition_log_entries("commit msg")[0].transpose[2]
    # commit SHAs of commits "older"/on botton of the last/"newest" commit having "commit msg" in its commit message:
    partition_log_entries("commit msg")[2].transpose[0]
    # must be true:
    partition_log_entries("commit msg").size == 3
    partition_log_entries("commit msg").map(&:size).reduce(:+) == branch_commits.size
=end
     def partition_log_entries str, log_entries=nil, fields=[:sha, :itself, :message ], multiple_occurence_index=0
       log_entries ||= self.branch_commits
       i = multiple_occurence_index.to_i
       separator = [(select_commits_matching str, log_entries, fields.to_nil)[i]]
       before  =  log_entries.take_while { |c|
         !(separator.index c)
       }
       after   = (log_entries - before) - separator
       partitions = [
         commits_map(before, fields),
         commits_map(separator.compact, fields),
         commits_map(after, fields),
       ]
       separator.first.nil? && partitions.reverse || partitions
     end


  end # of Git::Base


end # of RubyRooomyGitBaseModule


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
      gem_dependencies,
      gem_non_ruby_executables,
      reserved = args


    gem_name ||= "rubyrooomy"
    gem_version ||= (version [])
    gem_dir ||= running_dir
    gem_ext ||= ".gem"
    gem_hifen ||= "-"
    gem_ext ||= "date"
    gem_date ||=  Time.now.strftime("%Y-%m-%d")
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
    gem_is_current_file ||= __FILE__ # this enables the possibility of building
    #  a gem for the calling file itself, but be aware that lib/gem_file.rb
    # is supposed to be overriden later.
    gem_bin_generate ||= "bin/#{gem_name}" # generate a bin file
    gem_bin_contents ||=<<-ENDHEREDOC
#!/usr/bin/env ruby
require '#{gem_name}'
#{gem_validate_class}.new({:invoke => ARGV})
    ENDHEREDOC
    gem_bin_executables ||= [ gem_bin_generate && "#{gem_name}" ]
    gem_dependencies ||= [
      ["rubyment", "~> 0.7.25761146"],
      ["git", "~> 1.4"],
      ["pg",  "~> 1.1"],
    ]

    gem_non_ruby_executables = [
      # gem normally can only deploy non_ruby execs.
      # each file in this array will be escapsulated
      # as a ruby script that calls that file instead.
      # that ruby script will be placed in the
      # bin/ dir, and added to gem_executables

    ]


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
       gem_dependencies,
       gem_non_ruby_executables,

   ]
  end


end # of RubyRooomyGemModule


=begin
  The purpose of this module is to offer functions
  that were removed from other modules, but may be
  still under usage.
=end
module RubyRooomyUnderDeprecationModule


=begin
  defines #psql_db_dump_replacer__, that can be used
  to create a #psql_db_batch__ which backups the
  current contents of #psql_db__ , defined by
  #psql_db__sample_example , into each of the
  files in the array ["/tmp/psql_db_original_dump"],
  drops all of its tables (by current user), and then
  reads each of the database dumps from
  ["/tmp/database_dump"] into the same #psql_db__.

  Just give this method name (or returned array) to
  #psql_db_dump_replacer_batch_generator__from

=end
  def psql_db_dump_replacer__for_psql_db__sample_example
    [
      psql_db__sample_example,
      [
         "/tmp/psql_db_original_dump"
      ],
      [
        "/tmp/database_dump"
      ],
      "ON_ERROR_STOP=off",
    ]
  end


=begin
  This function had a bad name, it was coded as
  it was #psql_db_dump_replacer_batch__from. After
  #psql_db_dump_replacer_batch__from was implemented,
  this function could have been removed, but it is
  left deprecated for API backwards compatibility
  respect.

  defines #psql_db_dump_replacer_batch_generator__,
  out of a #psql_db_dump_replacer__ definition,
  that can be used
  to create a #psql_db_batch__ which backups the
  current contents of #psql_db__ , into each of the
  files in db_dumps__backup_desired_path,
  drops all of its tables (by current user), and then
  reads each of the database dumps from
  db_dumps__to_be_applied, into the same #psql_db__.

  if the #psql_db_dump_replacer__ definition has
  a second #psql_db__ definition at its 5th position
  (index 4), db_dumps__to_be_applied will be filled
  with the contents of that database. Otherwise,
  it is supposed that db_dumps__to_be_applied already
  exist in the filesystem.

  Just give this method name (or returned array) to
  #exec__batch_generator , with the #psql_db_- definition, e.g:
  exec__batch_generator [ :psql_db_dump_replacer_batch_generator__from, :psql_db_dump_replacer__for_psql_db__sample_example]
  or to
  #batch__from_batch_generator psql_db_dump_replacer_batch_generator__from(psql_db_dump_replacer__for_psql_db__sample_example)

  examples:
  # this version supposes "/tmp/database_dump" exists, and will apply it to :psql_db__sample_example, after backup-ing it to "/tmp/database_dump"
  psql_db_dump_replacer_batch_generator__from    [   :psql_db__sample_example,    [ "/tmp/psql_db_original_dump" ]   ,    [       "/tmp/database_dump"     ], "ON_ERROR_STOP=off"   ]
  # this one does the same thing, because #psql_db_dump_replacer__for_psql_db__sample_example defines the same array:
  psql_db_dump_replacer_batch_generator__from :psql_db_dump_replacer__for_psql_db__sample_example
  # this version will get "/tmp/database_dump" from "src_db" instead:
  psql_db_dump_replacer_batch_generator__from    [   :psql_db__sample_example,     [ "/tmp/psql_db_original_dump" ]  ,    [       "/tmp/database_dump"     ], "ON_ERROR_STOP=off" , ["src_db", "src_db_user", "src_db_pw", "localhost"],  ]

=end
  def psql_db_dump_replacer_batch_generator__from psql_db_dump_replacer
    [ "psql_db_dump_replacer_batch__from",  psql_db_dump_replacer ]
  end


=begin
  defines #psql_db_dump_replacer_batch__,
  out of a #psql_db_dump_replacer__ definition,
  that can be used
  to create a #psql_db_batch__ which backups the
  current contents of #psql_db__ , into each of the
  files in db_dumps__backup_desired_path,
  drops all of its tables (by current user), and then
  reads each of the database dumps from
  db_dumps__to_be_applied, into the same #psql_db__.

  if the #psql_db_dump_replacer__ definition has
  a second #psql_db__ definition at its 5th position
  (index 4), db_dumps__to_be_applied will be filled
  with the contents of that database. Otherwise,
  it is supposed that db_dumps__to_be_applied already
  exist in the filesystem.

  Just give this method name to
  #exec__batch_generator , with the #psql_db_- definition, e.g:
  exec__batch_generator [ :psql_db_dump_replacer_batch__from, :psql_db_dump_replacer__for_psql_db__sample_example]
  or give the returned values to #exec__batch

  examples:
  # this version supposes "/tmp/database_dump" exists, and will apply it to :psql_db__sample_example, after backup-ing it to "/tmp/database_dump"
  psql_db_dump_replacer_batch__from    [   "psql_db__sample_example",    [ "/tmp/psql_db_original_dump" ]   ,    [       "/tmp/database_dump"     ], "ON_ERROR_STOP=off"   ]

  # this one does the same thing, because #psql_db_dump_replacer__for_psql_db__sample_example defines the same array:
  psql_db_dump_replacer_batch__from :psql_db_dump_replacer__for_psql_db__sample_example

  # this version will get "/tmp/database_dump" from "src_db" instead:
  psql_db_dump_replacer_batch__from    [   "psql_db__sample_example",     [ "/tmp/psql_db_original_dump" ]  ,    [       "/tmp/database_dump"     ], "ON_ERROR_STOP=off" , ["src_db", "src_db_user", "src_db_pw", "localhost"],  ]

  # this version will get "/tmp/database_dump" from "src_db" too, but won't drop the current database.
  psql_db_dump_replacer_batch__from    [   "psql_db__sample_example",     [ "/tmp/psql_db_original_dump" ]  ,    [       "/tmp/sample_2_database_dump"     ], "ON_ERROR_STOP=off" , "psql_db__sample_example_2", "dont_drop" ]

  # this version will just dump the database:
  psql_db_dump_replacer_batch__from    [   "psql_db__sample_example",     [ "/tmp/psql_db_original_dump" ]  ,   nil, "ON_ERROR_STOP=off" , nil, "dont_drop" ]

  # this version will dump the database and drop it:
  psql_db_dump_replacer_batch__from    [   "psql_db__sample_example",     [ "/tmp/psql_db_original_dump" ]  ,   nil, "ON_ERROR_STOP=off" , nil ]

  # this version will just apply a migration file having some queries to the database:
  psql_db_dump_replacer_batch__from    [   "psql_db__sample_example",  nil,   [ "/tmp/migration.sql" ]  , "ON_ERROR_STOP=off" , nil, "dont_drop" ]


=end
  def psql_db_dump_replacer_batch__from psql_db_dump_replacer

   psql_db_dump_replacer = array__from psql_db_dump_replacer

    psql_db,
      db_dumps__backup_desired_path,
      db_dumps__to_be_applied,
      psql_dump_apply_options,
      psql_db__get_dumps_to_be_applied,
      dont_drop,
      reserved = psql_db_dump_replacer

   psql_db = array__from psql_db
   db_dumps__backup_desired_path = array__from db_dumps__backup_desired_path
   db_dumps__to_be_applied = array__from db_dumps__to_be_applied
   psql_db__src_dumps_to_be_applied = array__from psql_db__get_dumps_to_be_applied
   dont_drop = dont_drop.nne

    batch_generators = [
      psql_db__get_dumps_to_be_applied.nne && [
        :psql_db_batch__cli_or_generate_dumps,
        psql_db__src_dumps_to_be_applied,
        db_dumps__to_be_applied,
        "",
      ],
      db_dumps__backup_desired_path.compact.nne && [
        :psql_db_batch__cli_or_generate_dumps,
        psql_db,
        db_dumps__backup_desired_path,
        "",
      ],
      (!dont_drop) && [
        :psql_db_batch__db_queries_method,
        psql_db,
        :db_queries__drop_owned_current_user,
      ] || nil,
      db_dumps__to_be_applied.compact.nne && [
        :psql_db_batch__cli_or_apply_dumps,
        psql_db,
        db_dumps__to_be_applied,
        psql_dump_apply_options,
      ],
    ].compact

    batch_generators.map {|batch_generator|
      batch__from_batch_generator batch_generator
    }.flatten 1

  end


end # of RubyRooomyUnderDeprecationModule


=begin 
  The purpose of this module is to offer functions
  that were removed from other modules, and certainly
  should not be under usage anomore.
=end
module RubyRooomyDeprecatedModule


=begin
  Generates a #psql_db_batch__, ie, a #batch__
  definition tied to a #psql_db__ definition,
  which can be used to generate commands to
  drop and recreate a database, apply some
  dumps and reassign the ownership of that
  database to the user of a second #psql_db__
  definition given, the reassignee_psql_db.

  You may want to give "ON_ERROR_STOP=off"
  if there are ignorable errors on the dump
  files.

  You can give the results to #exec__batch

  Examples:

  # just recreate database:
  script__from psql_db_batch__database_reinstate("psql_db__sample_superuser_example")
  # PGPASSWORD="NSAowns" dropdb -h "localhost" -U "any_superuser" "any_db"   ;
  # PGPASSWORD="NSAowns" createdb -h "localhost" -U "any_superuser" "any_db"

  # just backup/dump database:
  script__from psql_db_batch__database_reinstate("psql_db__sample_superuser_example", nil, nil, nil,  ["/tmp/dump_before_drop"], "keep")
  # PGPASSWORD="NSAowns" pg_dump -h "localhost" -U "any_superuser" "any_db"    -f "/tmp/dump_before_drop"


  # just recreate database, but backup/dump it before:
  script__from psql_db_batch__database_reinstate("psql_db__sample_superuser_example", nil, nil, nil,  ["/tmp/dump_before_drop"])
  # PGPASSWORD="NSAowns" pg_dump -h "localhost" -U "any_superuser" "any_db"    -f "/tmp/dump_before_drop" ;
  # PGPASSWORD="NSAowns" dropdb -h "localhost" -U "any_superuser" "any_db"   ;
  # PGPASSWORD="NSAowns" createdb -h "localhost" -U "any_superuser" "any_db"



  # recreate database and reassign to the user in psql_db__sample_example:
  script__from psql_db_batch__database_reinstate("psql_db__sample_superuser_example", nil, "ON_ERROR_STOP=off", "psql_db__sample_example")
  # PGPASSWORD="NSAowns" dropdb -h "localhost" -U "any_superuser" "any_db"   ;
  # PGPASSWORD="NSAowns" createdb -h "localhost" -U "any_superuser" "any_db"   ;
  # PGPASSWORD="NSAowns" psql -h "localhost" -U "any_superuser" "any_db"  -c "REASSIGN OWNED BY "\"any_superuser\"" TO any_user"


  # recreate database and reassign to the user in psql_db__sample_example, after dump/backup of it:
  script__from psql_db_batch__database_reinstate("psql_db__sample_superuser_example", nil, "ON_ERROR_STOP=off", "psql_db__sample_example", ["/tmp/dump_before_drop"])
  # PGPASSWORD="NSAowns" pg_dump -h "localhost" -U "any_superuser" "any_db"   ON_ERROR_STOP=off -f "/tmp/dump_before_drop" ;
  # PGPASSWORD="NSAowns" dropdb -h "localhost" -U "any_superuser" "any_db"   ;
  # PGPASSWORD="NSAowns" createdb -h "localhost" -U "any_superuser" "any_db"   ;
  # PGPASSWORD="NSAowns" psql -h "localhost" -U "any_superuser" "any_db"  -c "REASSIGN OWNED BY "\"any_superuser\"" TO any_user"

  # the full example: recreate database, apply some dumps/migrations, reassign to the user in psql_db__sample_example, all after dump/backup of it
  script__from psql_db_batch__database_reinstate("psql_db__sample_superuser_example", [["package/migration_1.sql", "package/migration_2.sql"]], "ON_ERROR_STOP=off", "psql_db__sample_example", ["/tmp/dump_before_drop"])
  # PGPASSWORD="NSAowns" pg_dump -h "localhost" -U "any_superuser" "any_db"   ON_ERROR_STOP=off -f "/tmp/dump_before_drop" ;
  # PGPASSWORD="NSAowns" dropdb -h "localhost" -U "any_superuser" "any_db"   ;
  # PGPASSWORD="NSAowns" createdb -h "localhost" -U "any_superuser" "any_db"   ;
  # PGPASSWORD="NSAowns" psql -h "localhost" -U "any_superuser" "any_db"   ON_ERROR_STOP=off -f "package/migration_1.sql" ;
  # PGPASSWORD="NSAowns" psql -h "localhost" -U "any_superuser" "any_db"   ON_ERROR_STOP=off -f "package/migration_2.sql" ;
  # PGPASSWORD="NSAowns" psql -h "localhost" -U "any_superuser" "any_db"  -c "REASSIGN OWNED BY "\"any_superuser\"" TO any_user"

  # as often, values can be directly inlined:
  script__from psql_db_batch__database_reinstate(["my_db", "old_owner", "pw", "localhost"], nil, "ON_ERROR_STOP=off", [nil, "new_owner"])
  # PGPASSWORD="pw" dropdb -h "localhost" -U "old_owner" "my_db"   ;
  # PGPASSWORD="pw" createdb -h "localhost" -U "old_owner" "my_db"   ;
  # PGPASSWORD="pw" psql -h "localhost" -U "old_owner" "my_db"  -c "REASSIGN OWNED BY "\"old_owner\"" TO new_owner"

=end
  def psql_db_batch__database_reinstate(psql_db, db_dump_paths = nil, options= "", reassignee_psql_db = nil, bk_dump_to_paths = nil, no_reset = nil)

    psql_db_derivative = [
      bk_dump_to_paths,
      psql_db,
      db_dump_paths,
      options,
      reassignee_psql_db,
      no_reset.nne.negate_me,
    ]

    psql_db_derivative_batch__from psql_db_derivative

  end


end # of RubyRooomyDeprecatedModule


# Main module, basically a namespace
# for RubyRooomy. Consists basically
# of the inclusion of all available
# modules.
module RubyRooomyModule

  include RubyRooomyUnderDeprecationModule
  include RubyRooomyDeprecatedModule

  include RubyRooomyMetaModule
  include RubyRooomySQLModule
  include RubyRooomyPgGemModule
  include RubyRooomyFilesModule
  include RubyRooomyStringsModule
  include RubyRooomyJsonModule
  include RubyRooomyShortcutsModule
  include RubyRooomySubShellCommandsModule
  include RubyRooomyShellCommandsModule
  include RubyRooomyGemModule
  include RubyRooomyDefineContextsModule
  include RubyRooomyGitBaseModule
  include RubyRooomyArrayOfHashesModule

end # of RubyRooomyModule


# Main class, basically a namespace
# for RubyRooomy (not a module for
# making serialization easier if ever
# needed).
class RubyRooomy
  include RubyRooomyModule
end


(__FILE__ == $0) && RubyRooomy.new({:invoke => ARGV})


