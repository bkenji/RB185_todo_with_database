class SessionPersistence
  def initialize(session)
    @session = session
    @session[:lists] ||= []
  end

  def find_list(id)
    @session[:lists].find { |list| list[:id] == id}
  end

  def all_lists
    @session[:lists]
  end

  def create_list(name)
   id = next_list_id(all_lists)
   all_lists << { name: name, todos: [], id: id }
  end 

  def delete_list(id)
    all_lists.reject! {|list| list[:id].to_s == id}
  end

  def update_list_name(id, new_name)
    list = find_list(id)
    list[:name] = new_name
  end

  def create_new_todo(todos, todo_name)
    id = next_todo_id(todos)
    todos << { id: id, name: todo_name, completed: false }
  end

  def delete_todo(todos, todo_id)
       todos.reject! {|todo| todo[:id] == todo_id}
  end

  def update_todo_status(todo, new_status)
    todo[:completed] = new_status
  end

  def complete_all_todos(todos)
    todos.each { |todo| todo[:completed] = true }
  end

  def error=(error_msg)
    @session[:error] = error_msg
  end

  def success=(success_msg)
    @session[:success] = success_msg
  end 

  def clear_session
    @session.clear
  end

  private

  def next_list_id(all_lists)
    all_lists.map { |list| list[:id]}.max.to_i + 1
  end

  def next_todo_id(list)
    list.map { |todo| todo[:id] }.max.to_i + 1 
  end 
end