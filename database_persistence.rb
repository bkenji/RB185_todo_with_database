require "pg"

class DatabasePersistence
  def initialize(logger)
    @db = if Sinatra::Base.production?
      PG.connect(ENV['DATABASE_URL'])
    else
      PG.connect(dbname: "todos")
    end
    @logger = logger
  end

  def query(statement, *params)
    @logger.info "#{statement} #{params}"
    @db.exec_params(statement, params)
  end

  def find_list(id)
    sql = "SELECT * FROM lists WHERE id = $1;"
 
    result = query(sql, id)

    tuple = result.first
    return nil if tuple.nil?
    { id:tuple["id"], 
      name: tuple["name"],
      todos: todos_list(id) 
    }
  end

  def all_lists

    # Original query (n + 1):
    # sql = "SELECT * FROM lists;"    
    
    # Alternative optimization w/ subqueries:
    # sql = "SELECT lists.*,    
    #        count(todos.id) todos_count_completed, 
    #        count (
    #          (SELECT todos.id WHERE completed = 'false')
    #              ) todos_count_not_completed
    # FROM lists
    # LEFT JOIN todos ON lists.id = list_id
    # GROUP BY lists.id;"

    # Optimized query using JOIN clauses and NULLIF function:
    sql =  "SELECT lists.*, 
             count(todos.id) todos_count, 
             count(NULLIF(todos.completed, true)) todos_remaining
           FROM lists
           LEFT JOIN todos ON lists.id = list_id
           GROUP BY lists.id
           ORDER BY lists.id;"
    result = query(sql)

    result.map do |tuple|
      { id:tuple["id"],
        name: tuple["name"] , 
        todos_count: tuple["todos_count"],
        todos_remaining: tuple["todos_remaining"]
      }
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

  def todos_list(list_id)
    sql = "SELECT * FROM todos WHERE list_id = $1 ORDER BY id"
    result = query(sql, list_id)
    result.map do |todo_tuple|
      {id:todo_tuple["id"], name: todo_tuple["name"], completed: todo_tuple["completed"] == "t"}
    end
  end

  def create_new_todo(list_id, todo_name)
    sql = "INSERT INTO todos(name, list_id)
           VALUES ($1, $2)"
    result = query(sql, todo_name, list_id.to_s)
  end

  def delete_todo(list_id, todo_id)
    sql = "DELETE FROM todos 
           WHERE id = $1 AND list_id = $2"
    result = query(sql, todo_id, list_id)
  end

  def update_todo_status(todo_id, new_status)
    sql = "UPDATE todos
           SET completed = $2
           WHERE id = $1"

    result = query(sql, todo_id, new_status)
  end

  def complete_all_todos(list_id)
    sql = "UPDATE todos 
          SET completed = 'true'
          WHERE list_id = $1"

    result = query(sql, list_id)
  end

  def clear_lists
    sql = "DELETE FROM lists"

    result = query(sql)
  end
end