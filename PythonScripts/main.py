from flask import Flask, render_template, request, redirect, jsonify
from SafetyModel import SafetyModel, FileLoader
import polyline

app = Flask(__name__)
loader = FileLoader()
model = SafetyModel(loader)


@app.route('/')
def main():
    return 'Health check'


@app.route('/riskScore', methods=['GET'])
def riskScore():
    lat = float(request.args.get('latitude'))
    lon = float(request.args.get('longitude'))
    hour = int(request.args.get('hour'))
    if hour < 0 or hour > 23 or type(hour) != int:
        return "Hour must be an int between 0 and 23", 400
    return jsonify({
        'score': model.get_risk_score_for_location(lat, lon, hour)
    })


@app.route('/pathRiskScore', methods=['POST'])
def pathRiskScore():
    data = request.get_json()
    if 'hour' not in data:
        return "ERROR: Must pass in hour", 400

    hour = int(data.get('hour'))
    if hour < 0 or hour > 23 or type(hour) != int:
        return "Hour must be an int between 0 and 23", 400

    poly_encoded_list = data.get('polyline')
    waypoints_list = [polyline.decode(poly_encoded) for poly_encoded in poly_encoded_list]
    risks = [model.get_path_risk_score(waypoints, hour) for waypoints in waypoints_list]
    return jsonify({
        'data': risks
    })


if __name__ == '__main__':
    app.debug = True
    app.run(host='0.0.0.0', port=8000)

