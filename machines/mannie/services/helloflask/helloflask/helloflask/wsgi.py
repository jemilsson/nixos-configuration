from flask import Flask, request
application = Flask(__name__)

@application.route("/", methods = ['POST', 'GET'])
def hello():
    print(request.headers)
    print(request.form)
    return "Hello Flask!"

if __name__ == "__main__":
    application.run()
