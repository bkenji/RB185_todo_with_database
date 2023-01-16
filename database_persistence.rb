require "pg"

class DatabasePersistence
  def initialize
    @db = PG.connect(dbname: 'todos')
  end

  def query(statement, *params)
    puts "#{statement} #{params}"
    @db.exec_params(statement, params)
  end

  def find_list(id)
    sql = "SELECT * FROM lists WHERE id = $1;"
    result = query(sql, id)

    tuple = result.first
    {id:tuple["id"], name: tuple["name"], todos:[]}
  end

  def all_lists
    sql = "SELECT * FROM lists;"
    result = query(sql)
    result.map do |tuple|
     {id:tuple["id"], name: tuple["name"] , todos: []}
    end
  end

  def create_list(name)
    sql = "INSERT INTO lists(name)
           VALUES($1);"
    result = query(sql, name)
  end 

  def delete_list(id)
    sql = "DELETE FROM lists WHERE id = $1;"
    result = query(sql,id)
  end

  def update_list_name(id, new_name)
    sql = "UPDATE lists SET name = $1 WHERE id = $2"
    result = query(sql, new_name, id)
  end

  def create_new_todo(todos, todo_name)
    # id = next_todo_id(todos)
    # todos << { id: id, name: todo_name, completed: false }
  end

  def delete_todo(todos, todo_id)
      #  todos.reject! {|todo| todo[:id] == todo_id}
  end

  def update_todo_status(todo, new_status)
    # todo[:completed] = new_status
  end

  def complete_all_todos(todos)
    # todos.each { |todo| todo[:completed] = true }
  end

  def error=(error_msg)
    # @session[:error] = error_msg
  end

  def success=(success_msg)
    # @session[:success] = success_msg
  end 

  def clear_session
    # @session.clear
  end
end