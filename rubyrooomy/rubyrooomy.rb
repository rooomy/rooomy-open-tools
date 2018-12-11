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


end


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


 # TODO: these 4 lines below must be manually removed. I was forced to leave
 them otherwise the merge tool will get confused and won't merge this branch.
 examples:
   pg_gem_batch__from psql_db__sample_example,  (db_query_select__from ["table"])
   pg_gem_batch__from psql_db__sample_example,  db_queries__drop_owned_current_user
   results__select_key_output exec__pg_gem_batch__from psql_db__sample_example,  [db_query_transform__count(db_query__show_tables), db_query__show_tables]
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


end


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


end


=begin 
  The purpose of this module is to offer functions that can
  execute git related commands and batches in the command line
  shell where ruby is running, like forking a branch
=end
module RubyRooomyGitShellCommandsModule


end # of RubyRooomyGitShellCommandsModule


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
    psql_db = array__from(psql_db)
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


end


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

  This function sets the big enough value, Float::INFINITY
  by default.
=end
    def log_size_limit set_to=nil
      set_to && (@log_size_limit = set_to)
      @log_size_limit ||= Float::INFINITY
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
    gem_is_current_file = __FILE__ # this enables the possibility of building
    #  a gem for the calling file itself, but be aware that lib/gem_file.rb
    # is supposed to be overriden later.
    gem_bin_generate = "bin/#{gem_name}" # generate a bin file
    gem_bin_contents =<<-ENDHEREDOC
#!/usr/bin/env ruby
require '#{gem_name}'
#{gem_validate_class}.new({:invoke => ARGV})
    ENDHEREDOC
    gem_bin_executables ||= [ gem_bin_generate && "#{gem_name}" ]
    gem_dependencies = [
      ["rubyment", "~> 0.7.25694800"],
      ["git", "~> 1.4"],
      ["pg",  "~> 1.1"],
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

   ]
  end


end


# Main module, basically a namespace
# for RubyRooomy. Consists basically
# of the inclusion of all available
# modules.
module RubyRooomyModule

  include RubyRooomyMetaModule
  include RubyRooomySQLModule
  include RubyRooomyPgGemModule
  include RubyRooomyFilesModule
  include RubyRooomyStringsModule
  include RubyRooomyJsonModule
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


