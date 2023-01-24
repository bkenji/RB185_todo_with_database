# Set of helper methods to facilitate database-based sign up and user authentication. To be required by the file containing database logic (e.g. databasepersistence.rb)


def valid_login?(username, password)
  existing_username?(username) && 
  valid_password?(username, password)
end

def existing_username?(username)
  @storage.usernames.include?(username)
end

def valid_password?(user, password)
  hashed_pw = @storage.hashed_pw(user)
 BCrypt::Password.new(hashed_pw) == password
end

def valid_username?(username)
  !existing_username?(username) &&
  username =~ /^[A-Za-z0-9_]+$/
end

