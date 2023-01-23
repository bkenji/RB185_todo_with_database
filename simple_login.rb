# Set of helper methods to facilitate database-based sign up and user authentication. To be required by the file containing database logic (e.g. databasepersistence.rb)


require "pg" # necessary?


# Methods to be used as `helpers` for the Sinatra app (i.e. they could be inside the `helpers block`)



def valid_login?(username, password)
  existing_username?(username) && 
  valid_password?(password)
end

def existing_username?(username)
  @storage.usernames.include?(username)
end

def valid_password?(password)
 !@storage.verify_password(password).empty?
end