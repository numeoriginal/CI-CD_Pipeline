import requests
from flask import Flask, jsonify, request
import json

app = Flask(__name__)

films = []  
response = requests.get('https://www.swapi.tech/api/films')
data = json.loads(response.content)
for item in data['result']:
    uid = item["uid"]
    title = item['properties']['title']
    description = item['description']
    release_date = item['properties']['release_date']
    director = item['properties']['director']
    parsed_data = {
            'uid': uid,
            'title': title,
            'description': description,
            'release_date': release_date,
            'director': director
        }
    films.append(parsed_data)

@app.route('/')
def hello():
    return jsonify("Welcome to home page")

@app.route('/liveness')
def get_data():
    url = 'https://www.swapi.tech/api/films'
    response = requests.get(url)
    data = response.json()
    return jsonify(data)

@app.route('/films', methods=['GET'])
def films_route():
    return jsonify(films)

@app.route('/films/<film_uid>', methods=['GET'])
def get_film(film_uid):
    for film in films:
        if film['uid'] == film_uid:
            return jsonify(film)
    return jsonify({'message': 'Film not found'}), 404

@app.route('/films/<film_uid>', methods=['DELETE'])
def delete_film(film_uid):
    for film in films:
        if film['uid'] == film_uid:
            films.remove(film)
            return jsonify({'message': 'The film was successfully deleted'})
    return jsonify({'message': 'Film not found'}), 404

@app.route('/films', methods=['POST'])
def films_add():
    data = request.get_json()
    uid = data.get('uid', '')
    title = data.get('title', '')
    description = data.get('description', '')
    release_date = data.get('release_date', '')
    director = data.get('director', '')
    for film in films:
        if film['uid'] == uid:
            if 'title' in data:
                film['title'] = data['title']
            if 'description' in data:
                film['description'] = data['description']
            if 'release_date' in data:
                film['release_date'] = data['release_date']
            if 'director' in data:
                film['director'] = data['director']
            return jsonify({'message': 'The film already exists and has been updated'})
    new_film = {
        'uid': uid,
        'title': title,
        'description': description,
        'release_date': release_date,
        'director': director
    }
    films.append(new_film)
    return jsonify({'message': 'Film successfully added'}), 201

@app.route('/films/<film_uid>', methods=['PUT'])
def update_film(film_uid):
    data = request.get_json()
    title = data.get('title', '')
    description = data.get('description', '')
    release_date = data.get('release_date', '')
    director = data.get('director', '')
    
    if not all([title, description, release_date, director]):
        return jsonify({'error': 'All fields are required for update'}), 400
    
    for film in films:
        if film['uid'] == film_uid:
            film['title'] = title
            film['description'] = description
            film['release_date'] = release_date
            film['director'] = director
            return jsonify({'message': 'The film has been successfully updated'})
    return jsonify({'message': 'Film not found'}), 404

@app.route('/films/<film_uid>', methods=['PATCH'])
def update_film2(film_uid):
    data = request.get_json()
    for film in films:
        if film['uid'] == film_uid:
            if 'title' in data:
                film['title'] = data['title']
            if 'description' in data:
                film['description'] = data['description']
            if 'release_date' in data:
                film['release_date'] = data['release_date']
            if 'director' in data:
                film['director'] = data['director']
            return jsonify({'message': 'The film has been successfully updated'})
    return jsonify({'message': 'Film not found'}), 404

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=80)