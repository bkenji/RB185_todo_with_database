require 'sinatra'
require 'sinatra/content_for'
require 'tilt/erubis'
require_relative 'database_persistence'
require_relative 'simple_login'

configure do
  enable :sessions
  # set :session_secret, 'ffb0ae7a3db963272cc584ec05b3afee945aca81f98972151b162c4cccea32e9'
  set :erb, :escape_html => true
end

configure(:development) do
  require 'sinatra/reloader'
  also_reload "database_persistence.rb"
  also_reload "simple_login.rb"
end

helpers do

  def logged_in?
    session[:username]
  end

  def authorized_user?(user, list)
    @storage.verify_user(user, list)
  end

  def valid_username?(username)
    !existing_username?(username) &&
    username =~ /^[A-Za-z0-9_]+$/
  end

  def list_completed?(list)
    if list[:todos].nil?
      (todos_count(list).positive? &&
       remaining_todos_count(list).zero?)
    else
      (list[:todos].size.positive? &&
       list[:todos].all? {|todo| todo[:completed]})
    end
  end

  def todo_class(todo)
    'complete' if todo[:completed]
  end

  def todos_count(list)
    list[:todos_count].to_i
  end

  def remaining_todos_count(list)
    list[:todos_remaining].to_i
  end

  def sort_todos(todos)
    complete_todos, incomplete_todos = todos.partition { |todo| todo[:completed] }

    incomplete_todos.each { |todo| yield todo, todos.index(todo) }
    complete_todos.each { |todo| yield todo, todos.index(todo) }
  end

  # def sort_lists(lists) # original solution
  #   lists.sort_by! { |list| list_completed?(list) ? 1 : 0 }
  # end

  def sort_lists(lists)
    complete_lists, incomplete_lists = lists.partition { |list| list_completed?(list) }

    incomplete_lists.each { |list| yield list, lists.index(list) }
    complete_lists.each { |list| yield list, lists.index(list) }
  end
end

before do
  @storage = DatabasePersistence.new(logger)
  @user = session[:username]
  @lists = @storage.all_lists(@user)

  # @list_id = params[:list_id].to_i
end

# Root
get '/' do
  if logged_in?
   redirect '/lists'
  else
    redirect '/login'
  end
end

get '/login' do
  erb :login, layout: :layout
end

get '/signup' do
  erb :signup, layout: :layout
end

post '/signup' do
  if valid_username?(params[:username])# &&
   # valid_password?(params[:password]) 
    @storage.add_new_user(params[:username], params[:password])
    session[:username] = params[:username] 
    redirect '/'
  else
    session[:error] = "Invalid username or password."
    redirect '/signup'
  end
end

post '/login' do
  username = params[:username]
  password = params[:password]

  if valid_login?(username, password)
    session[:username] = username 
    redirect '/lists'
  else
    session[:error] = "Login invalid."
    redirect '/'
  end
end

get '/signout' do
  session[:username] = nil
  redirect '/'
end

# View list of lists
get '/lists' do
  redirect '/' unless logged_in?
  @todos = @lists
  erb :lists, layout: :layout
end

# Alternative route format
get '/lists/' do
  redirect '/lists'
end

# Render new list form
get '/lists/new' do
  erb :new_list, layout: :layout
end

# Return error message if list name is invalid, else returns nil.
def list_name_error
  if !(1..100).cover? @list_name.size
    'Name must be between 1 and 100 characters.'
  elsif @lists.any? { |list| list[:name] == @list_name }
    'Name already exists.'
  end
end

# Create a new list
post '/lists' do
  @list_name = params[:list_name].strip

  if list_name_error
    session[:error] = list_name_error
    erb :new_list, layout: :layout
  else
    @storage.create_list(@list_name, session[:username])
    session[:success] = 'List created successfully.'
    redirect '/lists'
  end
end

def valid_id?
  params[:list_id].to_i.to_s == params[:list_id]
end

def load_list(id)
  list = @storage.find_list(id)
  return list if list

  session[:error] = "The specified list was not found."
  redirect "/lists"
end


# Retrieve individual lists
get '/lists/:list_id' do
  redirect '/' unless logged_in? && authorized_user?(@user, params[:list_id])
  @list_id = params[:list_id].to_i
  @list = load_list(@list_id)
  @todos = @list[:todos]

  erb :list, layout: :layout
end

# Edit an existing todo list
get '/lists/:list_id/edit' do
  redirect '/' unless logged_in? && authorized_user?(@user, params[:list_id])
  @list_id = params[:list_id].to_i
  @list = load_list(@list_id)
  erb :edit_list, layout: :layout
end

# Update existing todo list
post '/lists/:list_id' do
  @list_name = params[:new_list_name].strip
  @list_id = params[:list_id].to_i
  @list = load_list(@list_id)

  if list_name_error
    session[:error] = list_name_error
    erb :edit_list, layout: :layout
  else
    @storage.update_list_name(@list_id, @list_name) 
    session[:success] = 'List name has been updated.'
    redirect "/lists/#{@list_id}"
  end
end

not_found do
  redirect '/lists'
end

# Delete a todo list
post '/lists/:list_id/delete' do
  @list_id = params[:list_id]
  session[:success] = "List has been deleted."
  @storage.delete_list(@list_id)
  if env["HTTP_X_REQUESTED_WITH"] == "XMLHttpRequest"
    "/lists"
  else
    redirect '/lists'
  end
end

# Error handling for todo editing
def todo_name_error
  return if (1..100).cover? @todo_name.size

  'Name must be between 1 and 100 characters.'
end

# Add new todo to list
post '/lists/:list_id/todos' do
  @list_id = params[:list_id].to_i
  @todo_name = params[:todo].strip
  @list = load_list(@list_id)
  @todos = @list[:todos]

  if todo_name_error
    session[:error] = todo_name_error
    erb :list, layout: :layout
  else
    @storage.create_new_todo(@list_id, @todo_name) 
    session[:success] = 'Todo item was successfully added.'
    redirect "/lists/#{@list_id}"
  end
end

# Delete todo item from individual list
post '/lists/:list_id/todos/:todo_id/delete' do
  @list_id = params[:list_id]
  @list = load_list(@list_id)

  @todos = @list[:todos]
  @todo_id = params[:todo_id]
  @storage.delete_todo(@list_id, @todo_id)

  if env["HTTP_X_REQUESTED_WITH"] == "XMLHttpRequest"
   status 204
  else
   session[:success] = "Todo item was successfully deleted."
   redirect "/lists/#{@list_id}" 
  end
end

def completed?
  !@todo[:completed] ? 'completed' : 'not yet completed'
end

# Update status of a todo
post '/lists/:list_id/todos/:todo_id' do
  @list_id = params[:list_id].to_i
  @list = load_list(@list_id)
  @todos = @list[:todos]
  @todo_id = params[:todo_id]
  @todo = @todos.find {|todo| todo[:id] == @todo_id}
  
  is_completed = params[:completed] == "t" 

  @storage.update_todo_status(@todo_id, is_completed)
  
  session[:success] = "\"#{@todo[:name]}\" has been marked as #{completed?}."
  redirect "lists/#{@list_id}"
end

# Check all todos as complete for a list
post '/lists/:list_id/todo_all' do
  @list_id = params[:list_id]
  @list = load_list(@list_id)
  @todos = @list[:todos]

  @storage.complete_all_todos(@list_id)
  session[:success] = 'All todos have been updated.'

  redirect "lists/#{@list_id}"
end

get '/clear' do
  redirect '/' unless logged_in?

  @storage.clear_lists(@user)
  if env["HTTP_X_REQUESTED_WITH"] == "XMLHttpRequest"
    session[:success] = "All lists deleted."
    "/lists"
  else
    redirect '/lists'
  end
  
end
