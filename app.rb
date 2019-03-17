require 'sinatra'
require 'slim'
require 'bcrypt'
require 'sqlite3'

enable :sessions

get('/') do 
    db = SQLite3::Database.new("db/blog.db")
    db.results_as_hash = true
    
    result = db.execute("SELECT * FROM Posts")
    slim(:index, locals:{posts: result, session: session})
    # locals är variabler som skickas in i slim-filen. Måste göras och är en symbol tack vare :{}
end

get('/Sign_In') do
    slim(:Sign_In)
end

post('/Sign_In') do
    db = SQLite3::Database.new("db/blog.db")
    db.results_as_hash = true
    
    finish = db.execute("SELECT id, password FROM Users WHERE username=?",  params["Username"])
    session["Username"] = params["Username"]
    
    if finish.length == 0 
        redirect('/Sign_In')
    end
    
    if BCrypt::Password.new(finish[0]["password"]) == params["Password"]
        session["user"] = finish[0]["id"]
        redirect('/')
    else
        redirect('/Sign_In')
    end
end

get('/Register') do
    slim(:Register)
end

post('/Register') do
    db = SQLite3::Database.new("db/blog.db")
    db.results_as_hash = true
    
    finish = db.execute("SELECT id FROM Users WHERE username=?",  [params["Username"]])
    
    if finish.length > 0
        redirect('/Register')
    end
    
    new_password = BCrypt::Password.create(params["Password"])
    
    db.execute("INSERT INTO Users (username, password, picture) VALUES (?, ?, 'v1.jpg')", [params["Username"], new_password])
    
    new_user_id = db.execute("SELECT id FROM Users WHERE username=?", [params["Username"]])
    
    session["user"] = new_user_id[0]["id"]
    redirect('/')
end

get('/Profile/:id') do
    db = SQLite3::Database.new("db/blog.db")
    db.results_as_hash = true
    id = params["id"]
    result = db.execute("SELECT * FROM Posts WHERE user_id=?",id)
    slim(:profile, locals:{posts: result, session: session}) 
end


get('/Profile/:id/alter') do
    slim(:profile_edit)
    
    
end

post('/logout') do
    session.destroy
    redirect('/')
end

post('/post') do
    text = params["content"]
    db = SQLite3::Database.new 'db/blog.db'
    username = db.execute("SELECT username FROM Users WHERE id=?", [session["user"]])
 

    new_file_name = SecureRandom.uuid
    temp_file = params["image"]["tempfile"]
    path = File.path(temp_file)

    new_file = FileUtils.copy(path, "./public/img/#{new_file_name}") 

    db.execute("INSERT INTO Posts (content, user_id, author, pic) VALUES(?,?,?,?)",[params['content'],session['user'],username,new_file_name])


    redirect('/')
end

post('/delete') do
    db = SQLite3::Database.new('db/blog.db')
    db.results_as_hash = true

    p db.execute("SELECT * FROM Posts WHERE id = ?", params["post_id"])
    p params["post_id"]
    db.execute("DELETE FROM Posts WHERE id = ?", params["post_id"])

    redirect('/')
end 

post('alter/:id') do
    db = SQLite3::Database.new('db/blog.db')
    db.results_as_hash = true

    
    new_file_name = SecureRandom.uuid
    temp_file = params["image"]["tempfile"]
    path = File.path(temp_file)

    new_file = FileUtils.copy(path, "./public/img/#{new_file_name}") 

    db.execute("REPLACE INTO Posts (content, user_id, author, pic, id) VALUES(?,?,?,?)",[
        
        params['content'],
        session['user'],
        username,new_file_name,
        
    ])


end


# configure do
#     set :error_messages, {
#         login_failed "Login failed!!"
#         ...  etc
#     }
#     settings.error[:Login_failed]
# end