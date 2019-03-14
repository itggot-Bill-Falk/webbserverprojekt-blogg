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
    if params["pic"].length == 0
        pic = nil
    else
        pic = params["pic"]
    end

    db.execute("INSERT INTO Posts (content, user_id, author, pic) VALUES(?,?,?,?)",[params['content'],session['user'],username,pic])
    redirect('/')
end


# configure do
#     set :error_messages, {
#         login_failed "Login failed!!"
#         ...  etc
#     }
#     settings.error[:Login_failed]
# end