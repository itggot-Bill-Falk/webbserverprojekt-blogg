require 'sinatra'
require 'slim'
require 'bcrypt'
require 'sqlite3'

enable :sessions

get('/') do 
    db = SQLite3::Database.new("db/blog.db")
    db.results_as_hash = true
    
    result = db.execute("SELECT * FROM Posts")
    slim(:index, locals:{posts: result})
    # locals är variabler som skickas in i slim-filen. Måste göras och är en symbol tack vare :{}
end

get('/Sign_In') do
    slim(:Sign_In)
end

post('/Sign_In') do
    db = SQLite3::Database.new("db/blog.db")
    db.results_as_hash = true

    finish = db.execute("SELECT id, password FROM Users WHERE username=?",  params["Username"])

    if BCrypt::Password.new(finish[0]["password"]) == params["Password"]
        session["user"] = params["Username"]
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

    finish = db.execute("SELECT username FROM Users WHERE username=?",  [params["Username"]])

    if finish.length != 0 
        redirect('/Register')
    end

    new_password = BCrypt::Password.create(params["Password"])

    db.execute("INSERT INTO Users (username, password, picture) VALUES (?, ?, 'v1.jpeg')", [params["Username"], new_password])

    session["user"] = params["Username"]
    redirect('/')
end