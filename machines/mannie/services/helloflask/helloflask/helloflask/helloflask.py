from flask import Flask
application = Flask(__name__)

@app.route("/")
def hello():
    return "Hello Flask!"

if __name__ == "__main__":
    application.run()
