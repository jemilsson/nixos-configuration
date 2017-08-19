from flask import Flask, request
application = Flask(__name__)

from pprint import pprint

@application.route("/", methods = ['POST', 'GET'])
def hello():
    pprint(request.headers)
    pprint(request.form)
    return "Hello Flask!"

if __name__ == "__main__":
    application.run()
